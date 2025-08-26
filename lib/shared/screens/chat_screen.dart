import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
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
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
              (_otherUserPhotoUrl != null && _otherUserPhotoUrl!.isNotEmpty)
                  ? NetworkImage(_otherUserPhotoUrl!)
                  : null,
              child:
              (_otherUserPhotoUrl == null || _otherUserPhotoUrl!.isEmpty)
                  ? Text(
                _initialsFor(_otherUserName ?? widget.otherUserUuid),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _otherUserName ?? widget.otherUserUuid,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _conversationId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
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
                  final data = doc.data() as Map<String, dynamic>? ?? {};
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
                      _highlightedMessageId = _pendingScrollToMessageId;
                      _pendingScrollToMessageId = null;
                    });
                    Future.delayed(const Duration(milliseconds: 900), () {
                      if (!mounted) return;
                      setState(() {
                        _highlightedMessageId = null;
                      });
                    });
                  });
                }

                return ListView.builder(
                  key: _conversationId == null
                      ? null
                      : PageStorageKey<String>('chat_' + _conversationId!),
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final isMe = data['sender_id'] == _chatService.userUuid;
                    final type = data['type'] as String? ?? 'text';
                    final status = data['status'] as String? ?? 'sent';
                    final mediaUrl = data['media_url'] as String?;
                    final replyTo = data['reply_to'] as String?;
                    final replyToMessageId =
                    data['reply_to_message_id'] as String?;
                    final timestamp = data['timestamp'];
                    final sentAt = _formatTime(timestamp);

                    // WhatsApp-like date header label
                    final String currentLabel = _formatDateLabel(timestamp);
                    String? previousLabel;
                    if (index + 1 < items.length) {
                      final prevData = items[index + 1].data() as Map<String, dynamic>? ?? {};
                      previousLabel = _formatDateLabel(prevData['timestamp']);
                    }

                    final msgKey = _messageKeys.putIfAbsent(
                      doc.id,
                          () => GlobalKey(),
                    );

                    final bubble = Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: _SwipeReplyWrapper(
                        onTrigger: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _replyToMessageText = data['content'] as String?;
                            _replyToMessageId = doc.id;
                          });
                        },
                        child: GestureDetector(
                          onLongPress: () {
                            setState(() {
                              _replyToMessageText = data['content'] as String?;
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
                              MediaQuery.of(context).size.width * 0.78,
                            ),
                            decoration: BoxDecoration(
                              color: _highlightedMessageId == doc.id
                                  ? Colors.yellow.withOpacity(0.35)
                                  : isMe
                                  ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  : Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (replyTo != null)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(
                                      bottom: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                      Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _scrollToMessage(replyToMessageId),
                                      child: Text(
                                        'Reply: $replyTo',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (type == 'image' && mediaUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 6,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(mediaUrl),
                                    ),
                                  ),
                                Text(
                                  (data['content'] as String?) ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      sentAt,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ),
                                    if (isMe) const SizedBox(width: 6),
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
                        if (index == 0 || currentLabel != previousLabel)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                currentLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7),
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
              onCancel: () => setState(() {
                _replyToMessageText = null;
                _replyToMessageId = null;
              }),
            ),
          _Composer(onSend: _sendText, onPickImage: _sendImage),
        ],
      ),
    );
  }

  Icon _statusIcon(String status) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all, size: 18, color: Colors.green);
      default:
      // 'sent' mapped to double-check gray per requirement
        return const Icon(Icons.done_all, size: 18, color: Colors.grey);
    }
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
      final messageIndex = _currentMessages.indexWhere((doc) => doc.id == messageId);
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
            data['photo_url'] as String? ?? data['profile_photo_url'] as String?;
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
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class _Composer extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  final Future<void> Function() onPickImage;

  const _Composer({required this.onSend, required this.onPickImage});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: () async {
                await widget.onPickImage();
              },
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () async {
                final text = _controller.text;
                _controller.clear();
                await widget.onSend(text);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  final String text;
  final VoidCallback onCancel;

  const _ReplyBanner({required this.text, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          const Icon(Icons.reply, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
        ],
      ),
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

class _SwipeReplyWrapperState extends State<_SwipeReplyWrapper> with SingleTickerProviderStateMixin {
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
                  Text('Swipe left to reply', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          Transform.translate(
            offset: Offset(_dragDx, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

