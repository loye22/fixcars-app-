import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_chat_service.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final FirebaseChatService _chatService = FirebaseChatService();
  late Future<void> _initFuture;
  @override
  void initState() {
    super.initState();
    // Ensure Firebase is ready
    _initFuture = _chatService.initializeFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () async {
              // Fallback: prompt for UUID to start a new conversation
              final otherUuid = await _promptForUuid(context);
              if (otherUuid == null || otherUuid.trim().isEmpty) return;
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserUuid: otherUuid.trim(),
                  ),
                ),
              );
            },
            tooltip: 'New chat',
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, initSnap) {
          if (initSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (initSnap.hasError) {
            return Center(child: Text('Failed to load chats'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _chatService.getConversations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No conversations yet'));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final lastMessage = (data['last_message'] as Map<String, dynamic>?) ?? {};
                  final participants = List<String>.from(data['participants'] ?? const []);
                  final otherUuid = participants.firstWhere(
                        (p) => p != _chatService.userUuid,
                    orElse: () => '',
                  );

                  return FutureBuilder<int>(
                    future: _chatService.getUnreadMessagesCount(doc.id),
                    builder: (context, unreadSnap) {
                      final unread = unreadSnap.data ?? 0;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(_initialsFor(lastMessage['sender_name'] as String?)),
                        ),
                        title: Text(lastMessage['sender_name'] as String? ?? 'Chat'),
                        subtitle: Text(
                          _lastMessagePreview(lastMessage),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: unread > 0
                            ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unread',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                            : const SizedBox.shrink(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUserUuid: otherUuid.isEmpty ? '' : otherUuid,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _initialsFor(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _lastMessagePreview(Map<String, dynamic> lastMessage) {
    final type = (lastMessage['type'] as String?) ?? 'text';
    switch (type) {
      case 'image':
        return '📷 ${lastMessage['content'] ?? 'Photo'}';
      case 'voice':
        return '🎤 Voice message';
      case 'file':
        return '📎 ${lastMessage['content'] ?? 'File'}';
      default:
        return (lastMessage['content'] as String?) ?? '';
    }
  }

  Future<String?> _promptForUuid(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start new chat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Other user UUID',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }
}


