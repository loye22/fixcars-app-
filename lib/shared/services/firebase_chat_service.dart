// services/firebase_chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

// Message type enum
enum MessageType {
  text,
  image,
  voice,
  file;

  String get value => toString().split('.').last;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

// Message status enum
enum MessageStatus {
  sent,
  delivered,
  read;

  String get value => toString().split('.').last;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MessageStatus.sent,
    );
  }
}

class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  // Cache for user profile data
  String? _cachedUserName;
  String? _cachedUserPhotoUrl;
  String? _cachedUserUuid;

  String? get cachedUserUuid => _cachedUserUuid;


  // Initialize Firebase with Django authentication
  Future<void> initializeFirebase() async {
    try {
      // Get token from Django (includes user data)
      final tokenData = await _getFirebaseToken();
      final customToken = tokenData['token'];
      final userUuid = tokenData['user_uuid'];
      final displayName = tokenData['display_name'];
      final photoUrl = tokenData['profile_photo_url'];

      // Sign in to Firebase with custom token
      await _auth.signInWithCustomToken(customToken);

      // Cache user data directly from token response
      _cachedUserUuid = userUuid;
      _cachedUserName = displayName;
      _cachedUserPhotoUrl = photoUrl;

      print('Firebase initialized with user: $displayName ($userUuid)');
    } catch (e) {
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  // Get Firebase token from Django backend
  Future<Map<String, dynamic>> _getFirebaseToken() async {
    try {
      final response = await _apiService.authenticatedGet('${ApiService.baseUrl}/firebase-token/');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to get Firebase token: ${response.statusCode}');

        throw Exception('Failed to get Firebase token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting Firebase token: $e');
    }
  }

// Upload file to Django backend with dynamic extension detection
  Future<String> uploadFile({
    required File file,
    String? customFileName,
  }) async {
    try {
      // Define allowed MIME types and their corresponding extensions, matching backend
      const allowedTypes = {
        'image/jpeg': 'jpg',
        'image/jpg': 'jpg', // Included for backend compatibility
        'image/png': 'png',
        'image/gif': 'gif',
        'application/pdf': 'pdf',
        'text/plain': 'txt',
      };

      // Get file MIME type
      final mimeType = lookupMimeType(file.path);
      if (mimeType == null || !allowedTypes.containsKey(mimeType)) {
        throw Exception('File type not allowed. Allowed types: JPEG, PNG, GIF, PDF, TXT');
      }

      // Use the extension from allowedTypes
      final extension = allowedTypes[mimeType]!;

      // Create filename with timestamp and proper extension
      final fileName = customFileName ??
          'file_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/upload-file/'),
      );

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType), // Explicitly set MIME type
        ),
      );

      // Add authorization header
      final token = await _apiService.getJwtToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final fileUrl = responseData['file_url'];
        if (fileUrl == null) {
          throw Exception('No file URL returned from server');
        }
        return fileUrl;
      } else {
        throw Exception('Failed to upload file: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  // Get or create a conversation between current user and another user
  Future<String> getOrCreateConversation({
    required String otherUserUuid,
  }) async {
    if (_cachedUserUuid == null) {
      await initializeFirebase();
    }

    // Check if conversation already exists
    final conversationsQuery = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: _cachedUserUuid)
        .get();

    for (final doc in conversationsQuery.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUserUuid) && participants.contains(_cachedUserUuid)) {
        return doc.id; // Return existing conversation ID
      }
    }

    // Create new conversation
    return await createConversation(
      participants: [_cachedUserUuid!, otherUserUuid],
    );
  }

  // Create a new conversation
  Future<String> createConversation({
    required List<String> participants,
  }) async {
    final conversationRef = _firestore.collection('conversations').doc();

    final conversationData = {
      'participants': participants,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await conversationRef.set(conversationData);
    return conversationRef.id;
  }

  // Get all conversations for the current user
  Stream<QuerySnapshot> getConversations() {
    if (_cachedUserUuid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: _cachedUserUuid)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .handleError((error) {
      print('Error getting conversations: $error');
    });
  }

  // Get messages for a specific conversation
  Stream<QuerySnapshot> getMessages({
    required String conversationId,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .handleError((error) {
      print('Error getting messages: $error');
    });
  }



  // Send a text message
  Future<void> sendTextMessage({
    required String conversationId,
    required String content,
    required List<String> participants,
  }) async {
    return sendMessage(
      conversationId: conversationId,
      content: content,
      type: MessageType.text,
      participants: participants,
    );
  }



  // Send a voice message with file upload
  Future<void> sendVoiceMessage({
    required String conversationId,
    required File voiceFile,
    required String duration,
    required List<String> participants,
  }) async {
    // Upload the voice file (extension will be detected automatically)
    final voiceUrl = await uploadFile(file: voiceFile);

    return sendMessage(
      conversationId: conversationId,
      content: duration,
      type: MessageType.voice,
      mediaUrl: voiceUrl,
      participants: participants,
    );
  }

  // Send a file message with file upload
  Future<void> sendFileMessage({
    required String conversationId,
    required File file,
    String? fileName,
    required String description,
    required List<String> participants,
  }) async {
    // Upload the file with optional custom filename
    final fileUrl = await uploadFile(
      file: file,
      customFileName: fileName,
    );

    return sendMessage(
      conversationId: conversationId,
      content: description,
      type: MessageType.file,
      mediaUrl: fileUrl,
      participants: participants,
    );
  }

  // Update message status (sent → delivered → read)
  Future<void> updateMessageStatus({
    required String conversationId,
    required String messageId,
    required MessageStatus status,
  }) async {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'status': status.value});
  }

// Send an image message with file upload
  Future<void> sendImageMessage({
    required String conversationId,
    required File imageFile,
    required String caption,
    required List<String> participants,
    String? replyTo,
    String? replyToMessageId,
  }) async {
    try {
      // Upload the image file to Django backend
      final imageUrl = await uploadFile(file: imageFile);

      // Send the message with image URL and caption
      await sendMessage(
        conversationId: conversationId,
        content: caption,
        type: MessageType.image,
        mediaUrl: imageUrl,
        participants: participants,
        replyTo: replyTo,
        replyToMessageId: replyToMessageId,
      );
    } catch (e) {
      throw Exception('Error sending image message: $e');
    }
  }

  // Send a message (text, image, voice, or file)
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    required MessageType type,
    String? mediaUrl,
    String? replyTo,
    String? replyToMessageId,
    required List<String> participants,
  }) async {
    try {
      // Ensure Firebase is initialized
      if (_cachedUserUuid == null) {
        await initializeFirebase();
      }

      // Reference to new message document
      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      // Create read status tracking for all participants
      final readStatus = <String, bool>{};
      for (final participant in participants) {
        readStatus[participant] = participant == _cachedUserUuid; // Sender has read it
      }

      // Message data
      final messageData = {
        'sender_id': _cachedUserUuid,
        'sender_name': _cachedUserName,
        'sender_photo_url': _cachedUserPhotoUrl,
        'content': content,
        'type': type.value,
        'media_url': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': MessageStatus.sent.value,
        'read_by': readStatus,
        'reply_to': replyTo,
        'reply_to_message_id': replyToMessageId,
      };

      // Update conversation last message
      final conversationUpdate = {
        'last_message': messageData,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Batch write to update message and conversation
      final batch = _firestore.batch();
      batch.set(messageRef, messageData);
      // Add unread counters for recipients to avoid dynamic field index queries
      final Map<String, dynamic> updates = {
        ...conversationUpdate,
      };
      for (final participant in participants) {
        if (participant == _cachedUserUuid) continue;
        updates['unread_counts.$participant'] = FieldValue.increment(1);
      }
      batch.update(
        _firestore.collection('conversations').doc(conversationId),
        updates,
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Get unread message count for a conversation
  Future<int> getUnreadMessagesCount(String conversationId) async {
    try {
      if (_cachedUserUuid == null) return 0;
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      if (!doc.exists) return 0;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final unreadCounts = (data['unread_counts'] as Map<String, dynamic>?) ?? {};
      final count = unreadCounts[_cachedUserUuid];
      if (count is int) return count;
      if (count is num) return count.toInt();
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

// Update the markMessagesAsRead method:
  Future<void> markMessagesAsRead({
    required String conversationId,
  }) async {
    if (_cachedUserUuid == null) return;
    await _firestore.collection('conversations').doc(conversationId).update({
      'unread_counts.$_cachedUserUuid': 0,
      'last_read_at.$_cachedUserUuid': FieldValue.serverTimestamp(),
    });

    // Additionally mark all messages from the other user as read (status)
    try {
      final messages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('sender_id', isNotEqualTo: _cachedUserUuid)
          .get();

      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        final data = doc.data();
        if ((data['status'] as String?) != MessageStatus.read.value) {
          batch.update(doc.reference, {
            'status': MessageStatus.read.value,
          });
        }
      }
      await batch.commit();
    } catch (_) {
      // ignore; status updates are best-effort
    }
  }

// Add this helper method to check if a message is read by current user
  Future<bool> isMessageReadByUser(String conversationId, String messageId) async {
    if (_cachedUserUuid == null) return false;

    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final readBy = data['read_by'] as Map<String, dynamic>? ?? {};
      return readBy[_cachedUserUuid] == true;
    }

    return false;
  }

  // Get user UUID (for creating conversations)
  String? get userUuid => _cachedUserUuid;

  // Get user display name
  String? get userName => _cachedUserName;

  // Get user photo URL
  String? get userPhotoUrl => _cachedUserPhotoUrl;

  // Check if user is authenticated with Firebase
  bool isAuthenticated() {
    return _auth.currentUser != null && _cachedUserUuid != null;
  }

  // Sign out from Firebase
  Future<void> signOut() async {
    _cachedUserName = null;
    _cachedUserPhotoUrl = null;
    _cachedUserUuid = null;
    await _auth.signOut();
  }


  // Add to services/firebase_chat_service.dart
  Future<String> startNewConversation({
    required String otherUserUuid,
    required String otherUserName,
    required String? otherUserPhotoUrl,
  }) async {
    if (_cachedUserUuid == null) {
      await initializeFirebase();
    }

    // Get or create conversation
    final conversationId = await getOrCreateConversation(
      otherUserUuid: otherUserUuid,
    );

    return conversationId;
  }

}
