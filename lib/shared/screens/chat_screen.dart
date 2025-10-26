import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../client/screens/SupplierProfileScreen.dart';
import '../services/api_service.dart';
import '../services/firebase_chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserUuid;

  const ChatScreen({Key? key, required this.otherUserUuid}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseChatService _chatService = FirebaseChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyToMessageText;
  String? _replyToMessageId;
  String? _conversationId;

  // Using a reversed list view, so newest messages are at the bottom visually
  bool _shouldAutoScrollOnNextUpdate = false;
  bool _isMarkingRead = false;
  Stream<QuerySnapshot>? _messagesStream;
  String? _highlightedMessageId;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _otherUserName;
  String? _otherUserPhotoUrl;
  String? _pendingScrollToMessageId;
  List<QueryDocumentSnapshot> _currentMessages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureConversation();
      if (_conversationId != null) {
        await _chatService.markMessagesAsRead(conversationId: _conversationId!);
        setState(() {
          _messagesStream = _chatService.getMessages(
            conversationId: _conversationId!,
          );
        });
      }
    });
    _loadOtherUserProfile();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF6FF),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/chatwall.jpg'),
            // Your image path
            fit: BoxFit.cover, // Cover the entire screen
          ),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            SupplierProfileScreen(userId: widget.otherUserUuid),
                  ),
                );
              },
              child: Card(
                color: Colors.white,
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 40, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with back button and user info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Back button
                          IconButton(
                            icon: Icon(Icons.arrow_back, size: 30),
                            onPressed: () {
                              // Add your back navigation logic here
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          // User avatar
                          CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                (_otherUserPhotoUrl != null &&
                                        _otherUserPhotoUrl!.isNotEmpty)
                                    ? NetworkImage(_otherUserPhotoUrl!)
                                    : null,
                            child:
                                (_otherUserPhotoUrl == null ||
                                        _otherUserPhotoUrl!.isEmpty)
                                    ? Text(
                                      _initialsFor(
                                        _otherUserName ?? widget.otherUserUuid,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          // User name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _otherUserName ?? widget.otherUserUuid,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                Text(
                                  "De obicei, îți răspunde în mai puțin de 10 minute",
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Subtitle with response time
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child:
                  _conversationId == null
                      ? Center(
                        child: LoadingAnimationWidget.threeArchedCircle(
                          color: Colors.black,
                          size: 24,
                        ),
                      )
                      : StreamBuilder<QuerySnapshot>(
                        stream: _messagesStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: LoadingAnimationWidget.threeArchedCircle(
                                color: Colors.black,
                                size: 24,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          // Store current messages for reference
                          _currentMessages = docs;

                          // Mark incoming messages as read when the chat is open
                          bool hasUnreadIncoming = false;
                          for (final doc in docs) {
                            final data =
                                doc.data() as Map<String, dynamic>? ?? {};
                            final isIncoming =
                                data['sender_id'] != _chatService.userUuid;
                            if (isIncoming && data['status'] != 'read') {
                              hasUnreadIncoming = true;
                              _chatService.updateMessageStatus(
                                conversationId: _conversationId!,
                                messageId: doc.id,
                                status: MessageStatus.read,
                              );
                            }
                          }
                          // Keep unread counters reset while viewing the chat
                          if (hasUnreadIncoming && !_isMarkingRead) {
                            _isMarkingRead = true;
                            _chatService
                                .markMessagesAsRead(
                                  conversationId: _conversationId!,
                                )
                                .whenComplete(() {
                                  _isMarkingRead = false;
                                });
                          }

                          final items = docs.reversed.toList(growable: false);

                          // If we have a pending scroll target, try to bring it into view after build
                          if (_pendingScrollToMessageId != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToMessageImpl(_pendingScrollToMessageId!);
                              setState(() {
                                _highlightedMessageId =
                                    _pendingScrollToMessageId;
                                _pendingScrollToMessageId = null;
                              });
                              Future.delayed(
                                const Duration(milliseconds: 900),
                                () {
                                  if (!mounted) return;
                                  setState(() {
                                    _highlightedMessageId = null;
                                  });
                                },
                              );
                            });
                          }

                          return ListView.builder(
                            key:
                                _conversationId == null
                                    ? null
                                    : PageStorageKey<String>(
                                      'chat_' + _conversationId!,
                                    ),
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final doc = items[index];
                              final data =
                                  doc.data() as Map<String, dynamic>? ?? {};
                              final isMe =
                                  data['sender_id'] == _chatService.userUuid;
                              final type = data['type'] as String? ?? 'text';
                              final status =
                                  data['status'] as String? ?? 'sent';
                              final mediaUrl = data['media_url'] as String?;
                              final replyTo = data['reply_to'] as String?;
                              final replyToMessageId =
                                  data['reply_to_message_id'] as String?;
                              final timestamp = data['timestamp'];
                              final sentAt = _formatTime(timestamp);

                              // WhatsApp-like date header label
                              final String currentLabel = _formatDateLabel(
                                timestamp,
                              );
                              String? previousLabel;
                              if (index + 1 < items.length) {
                                final prevData =
                                    items[index + 1].data()
                                        as Map<String, dynamic>? ??
                                    {};
                                previousLabel = _formatDateLabel(
                                  prevData['timestamp'],
                                );
                              }

                              final msgKey = _messageKeys.putIfAbsent(
                                doc.id,
                                () => GlobalKey(),
                              );

                              final bubble = Align(
                                alignment:
                                    isMe
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                child: _SwipeReplyWrapper(
                                  onTrigger: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _replyToMessageText =
                                          data['content'] as String?;
                                      _replyToMessageId = doc.id;
                                    });
                                  },
                                  child: GestureDetector(
                                    onLongPress: () {
                                      setState(() {
                                        _replyToMessageText =
                                            data['content'] as String?;
                                        _replyToMessageId = doc.id;
                                      });
                                    },
                                    child: Container(
                                      key: msgKey,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.78,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _highlightedMessageId == doc.id
                                                ? Colors.yellow.withOpacity(
                                                  0.35,
                                                )
                                                : isMe
                                                ? Color(0xFF14B8A6)
                                                : Color(0xFFDBEAFE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (replyTo != null)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              margin: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isMe
                                                        ? Color(0xFF54DBCC)
                                                        : Color(0xFFC2DCFF),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: GestureDetector(
                                                onTap:
                                                    () => _scrollToMessage(
                                                      replyToMessageId,
                                                    ),
                                                child: Text(
                                                  'Reply: $replyTo',
                                                  style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color:
                                                        isMe
                                                            ? Color(0xFFFFFFFF)
                                                            : Color(0xFF1E40AF),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (type == 'image' &&
                                              mediaUrl != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => ExtendedImageSlidePage(
                                                            child: ExtendedImage.network(
                                                              mediaUrl,
                                                              mode:
                                                                  ExtendedImageMode
                                                                      .gesture,
                                                              initEditorConfigHandler: (
                                                                state,
                                                              ) {
                                                                return EditorConfig(
                                                                  maxScale: 5.0,
                                                                  hitTestSize:
                                                                      20.0,
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    mediaUrl,
                                                    width:
                                                        200, // Define a fixed width
                                                    height: 200,
                                                    loadingBuilder:
                                                        (_, _, _) => Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                58.0,
                                                              ),
                                                          child: Container(
                                                            child: LoadingAnimationWidget.threeArchedCircle(
                                                              color:
                                                                  isMe
                                                                      ? Color(
                                                                        0xFFFFFFFF,
                                                                      )
                                                                      : Color(
                                                                        0xFF1E40AF,
                                                                      ),
                                                              size: 24,
                                                            ),
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Text(
                                            (data['content'] as String?) ?? '',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color:
                                                  isMe
                                                      ? Color(0xFFFFFFFF)
                                                      : Color(0xFF1E40AF),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                sentAt,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      isMe
                                                          ? Color(0xFFFFFFFF)
                                                          : Color(0xFF1E40AF),
                                                ),
                                              ),
                                              if (isMe)
                                                const SizedBox(width: 6),
                                              if (isMe) _statusIcon(status),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              return Column(
                                children: [
                                  if (index == 0 ||
                                      currentLabel != previousLabel)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          currentLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  bubble,
                                ],
                              );
                            },
                          );
                        },
                      ),
            ),
            if (_replyToMessageText != null)
              _ReplyBanner(
                text: _replyToMessageText!,
                onCancel:
                    () => setState(() {
                      _replyToMessageText = null;
                      _replyToMessageId = null;
                    }),
              ),
            _Composer(
              onSend: _sendText,
              onPickImageFromGallery: _sendImageFromGallery,
              onTakePicture: _takePicture,
            ),
          ],
        ),
      ),
    );
  }

  Icon _statusIcon(String status) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all, size: 18, color: Colors.white);
      default:
        // 'sent' mapped to double-check gray per requirement
        return const Icon(Icons.done, size: 18, color: Colors.white);
    }
  }

  Future<void> _sendImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final file = File(picked.path);
    await _ensureConversation();
    if (_conversationId == null) return;
    final myUuid = _chatService.userUuid ?? '';
    await _chatService.sendImageMessage(
      conversationId: _conversationId!,
      imageFile: file,
      caption: '',
      participants: [myUuid, widget.otherUserUuid],
      replyTo: _replyToMessageText,
      replyToMessageId: _replyToMessageId,
    );
    setState(() {
      _textController.clear();
      _replyToMessageText = null;
      _replyToMessageId = null;
    });
    _shouldAutoScrollOnNextUpdate = true;
    _scrollToBottom();
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return;
    final file = File(picked.path);
    await _ensureConversation();
    if (_conversationId == null) return;
    final myUuid = _chatService.userUuid ?? '';
    await _chatService.sendImageMessage(
      conversationId: _conversationId!,
      imageFile: file,
      caption: '',
      participants: [myUuid, widget.otherUserUuid],
      replyTo: _replyToMessageText,
      replyToMessageId: _replyToMessageId,
    );
    setState(() {
      _textController.clear();
      _replyToMessageText = null;
      _replyToMessageId = null;
    });
    _shouldAutoScrollOnNextUpdate = true;
    _scrollToBottom();
  }

  Future<void> _sendText(String text) async {
    if (text.trim().isEmpty) return;
    final replySnapshot = _replyToMessageText;
    final replyIdSnapshot = _replyToMessageId;
    setState(() {
      _replyToMessageText = null;
      _replyToMessageId = null;
    });
    await _ensureConversation();
    if (_conversationId == null) return;
    final myUuid = _chatService.userUuid ?? '';
    await _chatService.sendMessage(
      conversationId: _conversationId!,
      content: text.trim(),
      type: MessageType.text,
      participants: [myUuid, widget.otherUserUuid],
      replyTo: replySnapshot,
      replyToMessageId: replyIdSnapshot,
    );
    _shouldAutoScrollOnNextUpdate = true;
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final file = File(picked.path);
    await _ensureConversation();
    if (_conversationId == null) return;
    final myUuid = _chatService.userUuid ?? '';
    await _chatService.sendImageMessage(
      conversationId: _conversationId!,
      imageFile: file,
      caption: '',
      participants: [myUuid, widget.otherUserUuid],
      replyTo: _replyToMessageText,
      replyToMessageId: _replyToMessageId,
    );
    setState(() {
      _textController.clear();
      _replyToMessageText = null;
      _replyToMessageId = null;
    });
    _shouldAutoScrollOnNextUpdate = true;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      // For reversed list, bottom is offset 0
      if (_shouldAutoScrollOnNextUpdate || _isNearBottom()) {
        _shouldAutoScrollOnNextUpdate = false;
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.offset <= 56;
  }

  void _scrollToMessage(String? messageId) {
    if (messageId == null) return;
    setState(() {
      _pendingScrollToMessageId = messageId;
    });
  }

  void _scrollToMessageImpl(String messageId) {
    final key = _messageKeys[messageId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3, // Scroll to 30% of the viewport
      );
    } else {
      // Fallback: if the key isn't available yet, scroll to the approximate position
      final messageIndex = _currentMessages.indexWhere(
        (doc) => doc.id == messageId,
      );
      if (messageIndex != -1) {
        // Calculate position based on reversed list
        final position = (_currentMessages.length - messageIndex - 1) * 100.0;
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _ensureConversation() async {
    if (_conversationId != null) return;
    // Initialize Firebase and resolve conversation
    await _chatService.initializeFirebase();
    final id = await _chatService.getOrCreateConversation(
      otherUserUuid: widget.otherUserUuid,
    );
    if (!mounted) return;
    setState(() {
      _conversationId = id;
      _messagesStream = _chatService.getMessages(conversationId: id);
    });
  }

  Future<void> _loadOtherUserProfile() async {
    try {
      final api = ApiService();
      final data = await api.getUserInfo(widget.otherUserUuid);
      if (!mounted) return;
      setState(() {
        _otherUserName =
            data['full_name'] as String? ?? data['display_name'] as String?;
        _otherUserPhotoUrl =
            data['photo_url'] as String? ??
            data['profile_photo_url'] as String?;
      });
    } catch (_) {
      // ignore failures gracefully
    }
  }

  String _initialsFor(String value) {
    final n = value.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatTime(dynamic timestamp) {
    try {
      DateTime dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dt = timestamp;
      } else {
        return '';
      }
      final now = DateTime.now();
      final isToday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (isToday) return time;
      return '${dt.month}/${dt.day} $time';
    } catch (_) {
      return '';
    }
  }

  String _formatDateLabel(dynamic timestamp) {
    try {
      DateTime dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dt = timestamp;
      } else {
        return '';
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thatDay = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(thatDay).inDays;
      if (diff == 0) return 'Azi';
      if (diff == 1) return 'Ieri';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class _Composer extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  final Future<void> Function() onPickImageFromGallery;
  final Future<void> Function() onTakePicture;

  const _Composer({
    required this.onSend,
    required this.onPickImageFromGallery,
    required this.onTakePicture,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gallery button (clipper)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Image.asset('assets/clipper.png', width: 24),
              onPressed: () async {
                await widget.onPickImageFromGallery();
              },
            ),
          ),
          const SizedBox(width: 12),

          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Scrieți mesajul aici...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Image.asset('assets/camera2.png', width: 24),
                    onPressed: () async {
                      // Handle emoji picker
                      await widget.onTakePicture();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Send button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Image.asset('assets/send.png', width: 24),
              onPressed: () async {
                if (_hasText) {
                  final text = _controller.text;
                  _controller.clear();
                  await widget.onSend(text);
                } else {
                  // Handle voice message
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// class _Composer extends StatefulWidget {
//   final Future<void> Function(String text) onSend;
//   final Future<void> Function() onPickImage;
//
//   const _Composer({required this.onSend, required this.onPickImage});
//
//   @override
//   State<_Composer> createState() => _ComposerState();
// }
//
// class _ComposerState extends State<_Composer> {
//   final TextEditingController _controller = TextEditingController();
//   bool _hasText = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller.addListener(() {
//       setState(() {
//         _hasText = _controller.text.isNotEmpty;
//       });
//     });
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Image attachment button
//           Container(
//             decoration: BoxDecoration(
//               color: Color(0xFF14B8A6),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: IconButton(
//               icon: Image.asset('assets/clipper.png', width: 24),
//               onPressed: () async {
//                 if (_hasText) {
//                   final text = _controller.text;
//                   _controller.clear();
//                   await widget.onSend(text);
//                 } else {
//                   // Handle voice message
//                 }
//               },
//             ),
//           ),
//           const SizedBox(width: 12),
//
//           // Text input field
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               child: Row(
//                 children: [
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: TextField(
//                       controller: _controller,
//                       decoration: const InputDecoration(
//                         hintText: 'Type your message...',
//                         border: InputBorder.none,
//                         isDense: true,
//                         contentPadding: EdgeInsets.symmetric(vertical: 14),
//                       ),
//                       maxLines: null,
//                       textCapitalization: TextCapitalization.sentences,
//                     ),
//                   ),
//                   IconButton(
//                     icon: Image.asset('assets/camera2.png', width: 24),
//                     onPressed: () {
//                       // Handle emoji picker
//                     },
//                   ),
//                   // IconButton(
//                   //   icon: Image.asset('assets/mic.png', width: 30),
//                   //   onPressed: () {
//                   //     // Handle emoji picker
//                   //   },
//                   // ),
//
//                   const SizedBox(width: 4),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//
//           // Send button
//           Container(
//             decoration: BoxDecoration(
//               color: Color(0xFF14B8A6),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: IconButton(
//               icon: Image.asset('assets/send.png', width: 24),
//               onPressed: () async {
//                 if (_hasText) {
//                   final text = _controller.text;
//                   _controller.clear();
//                   await widget.onSend(text);
//                 } else {
//                   // Handle voice message
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }

class _ReplyBanner extends StatefulWidget {
  final String text;
  final VoidCallback onCancel;

  const _ReplyBanner({required this.text, required this.onCancel});

  @override
  State<_ReplyBanner> createState() => _ReplyBannerState();
}

class _ReplyBannerState extends State<_ReplyBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF14B8A6).withOpacity(0.1),
                    const Color(0xFF14B8A6).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF14B8A6).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14B8A6).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Reply indicator line
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF14B8A6),
                          const Color(0xFF54DBCC),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Reply icon with background
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14B8A6).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.reply,
                            size: 20,
                            color: Color(0xFF14B8A6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Reply text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Răspundeți la',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF14B8A6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cancel button
                        GestureDetector(
                          onTap: () {
                            _animationController.reverse().then((_) {
                              widget.onCancel();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SwipeReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTrigger;

  const _SwipeReplyWrapper({required this.child, required this.onTrigger});

  @override
  State<_SwipeReplyWrapper> createState() => _SwipeReplyWrapperState();
}

class _SwipeReplyWrapperState extends State<_SwipeReplyWrapper>
    with SingleTickerProviderStateMixin {
  double _dragDx = 0;
  static const double _trigger = 56;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() {
          _dragDx = (d.delta.dx + _dragDx).clamp(0, 96);
        });
      },
      onHorizontalDragEnd: (_) {
        if (_dragDx >= _trigger) {
          widget.onTrigger();
        }
        setState(() {
          _dragDx = 0;
        });
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dragDx > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.reply, size: 18, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'Swipe left to reply',
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ],
              ),
            ),
          Transform.translate(offset: Offset(_dragDx, 0), child: widget.child),
        ],
      ),
    );
  }
}
