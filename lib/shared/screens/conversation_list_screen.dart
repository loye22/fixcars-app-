import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../services/firebase_chat_service.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final FirebaseChatService _chatService = FirebaseChatService();
  late Future<void> _initFuture;

  // FixCar Premium Dark Theme Constants
  final Color _bgColor = const Color(0xFF1E1E1E);
  final Color _surfaceColor = const Color(0xFF2C2C2C);
  final Color _accentColor = const Color(0xFFC8CADE);
  final Color _pureWhite = const Color(0xFFFFFFFF);
  final Color _neonGreen = const Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _initFuture = _chatService.initializeFirebase(); //
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return '${dateTime.day} ${['IAN', 'FEB', 'MAR', 'APR', 'MAI', 'IUN', 'IUL', 'AUG', 'SEPT', 'OCT', 'NOV', 'DEC'][dateTime.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "MESAJE",
          style: TextStyle(
            color: _pureWhite,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 4.0,
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, initSnap) {
          if (initSnap.connectionState == ConnectionState.waiting) {
            return Center(child: LoadingAnimationWidget.beat(color: _pureWhite, size: 20));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _chatService.getConversations(), //
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: LoadingAnimationWidget.beat(color: _pureWhite, size: 20));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text('NICI O CONVERSAȚIE',
                      style: TextStyle(color: _pureWhite.withOpacity(0.3), letterSpacing: 2.0, fontSize: 12)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final lastMessage = (data['last_message'] as Map<String, dynamic>?) ?? {};
                  final participants = List<String>.from(data['participants'] ?? []);
                  final otherUuid = participants.firstWhere((p) => p != _chatService.userUuid, orElse: () => '');
                  final updatedAt = data['updated_at'] as Timestamp?;

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: ApiService().getUserInfo(otherUuid), //
                    builder: (context, userSnap) {
                      final userData = userSnap.data ?? {};
                      final displayName = userData['display_name'] ?? lastMessage['sender_name'] as String? ?? 'Chat';
                      final avatarUrl = userData['profile_photo_url'] as String? ?? '';

                      return FutureBuilder<int>(
                        future: _chatService.getUnreadMessagesCount(doc.id), //
                        builder: (context, unreadSnap) {
                          final unread = unreadSnap.data ?? 0;
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ChatScreen(otherUserUuid: otherUuid), //
                              ));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              color: Colors.transparent, // Minimalist: No card background
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                    backgroundColor: _surfaceColor,
                                    child: avatarUrl.isEmpty ? _initialsFor(displayName) : null,
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              displayName.toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: _pureWhite,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            Text(
                                              _formatTimestamp(updatedAt).toUpperCase(),
                                              style: TextStyle(fontSize: 10, color: _pureWhite.withOpacity(0.4)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _lastMessagePreview(lastMessage),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: unread > 0 ? _pureWhite : _pureWhite.withOpacity(0.5),
                                                  fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w300,
                                                ),
                                              ),
                                            ),
                                            if (unread > 0)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(color: _neonGreen, shape: BoxShape.circle),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

  Widget _initialsFor(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return Icon(Icons.person, color: _pureWhite, size: 20);
    final parts = n.split(' ');
    String text = parts.length == 1 ? parts.first[0] : (parts[0][0] + parts[1][0]);
    return Text(text.toUpperCase(), style: TextStyle(color: _pureWhite, fontWeight: FontWeight.bold, fontSize: 14));
  }

  String _lastMessagePreview(Map<String, dynamic> lastMessage) {
    final type = (lastMessage['type'] as String?) ?? 'text';
    switch (type) {
      case 'image': return 'FOTO';
      case 'voice': return 'AUDIO';
      case 'file': return 'DOC';
      default: return (lastMessage['content'] as String?) ?? '';
    }
  }
}
// import 'package:fixcars/shared/services/api_service.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
//
// import '../services/firebase_chat_service.dart';
// import 'chat_screen.dart';
//
// class ConversationListScreen extends StatefulWidget {
//   const ConversationListScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ConversationListScreen> createState() => _ConversationListScreenState();
// }
//
// class _ConversationListScreenState extends State<ConversationListScreen> {
//   final FirebaseChatService _chatService = FirebaseChatService();
//   late Future<void> _initFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _initFuture = _chatService.initializeFirebase();
//   }
//
//   String _formatTimestamp(Timestamp? timestamp) {
//     if (timestamp == null) return '';
//     final dateTime = timestamp.toDate();
//     final now = DateTime.now();
//     if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
//       return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
//     } else if (dateTime.day == now.day - 1 && dateTime.month == now.month && dateTime.year == now.year) {
//       return 'Ieri';
//     }
//     return '${dateTime.day} ${
//         //['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
//         ['Ian.', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun', 'Iul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec']
//         [dateTime.month - 1]}';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//       //  actions: [Icon(Icons.abc , color: Colors.white,)],
//       //   leading: IconButton(
//       //     icon: Icon(CupertinoIcons.back), // Use the specific Cupertino icon
//       //     onPressed: () {
//       //       // This is the function that makes it go back to the previous screen
//       //       Navigator.of(context).pop();
//       //     },
//       //   ),
//         automaticallyImplyLeading: false,
//         backgroundColor: Colors.white,
//         title: Text("Mesaje"),
//       ),
//       backgroundColor: Colors.white,
//       body: FutureBuilder<void>(
//         future: _initFuture,
//         builder: (context, initSnap) {
//           if (initSnap.connectionState == ConnectionState.waiting) {
//             return  Center(child : LoadingAnimationWidget.threeArchedCircle(color: Colors.white, size: 24)
//             );
//           }
//           if (initSnap.hasError) {
//             return Center(child: Text('Failed to load chats', style: TextStyle(color: Colors.red)));
//           }
//
//           return StreamBuilder<QuerySnapshot>(
//             stream: _chatService.getConversations(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return  Center(child:LoadingAnimationWidget.threeArchedCircle(color: Colors.white, size: 24),
//                     );
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
//               }
//               final docs = snapshot.data?.docs ?? [];
//               if (docs.isEmpty) {
//                 return const Center(child: Text('No conversations yet', style: TextStyle(fontStyle: FontStyle.italic)));
//               }
//
//               return Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: ListView.separated(
//                   padding: const EdgeInsets.all(8.0),
//                   itemCount: docs.length,
//                   separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Colors.grey),
//                   itemBuilder: (context, index) {
//                     final doc = docs[index];
//                     final data = doc.data() as Map<String, dynamic>? ?? {};
//                     final lastMessage = (data['last_message'] as Map<String, dynamic>?) ?? {};
//                     final participants = List<String>.from(data['participants'] ?? []);
//                     final otherUuid = participants.firstWhere(
//                           (p) => p != _chatService.userUuid,
//                       orElse: () => '',
//                     );
//                     final updatedAt = data['updated_at'] as Timestamp?;
//
//                     // return FutureBuilder<int>(
//                     //   future: _chatService.getUnreadMessagesCount(doc.id),
//                     //   builder: (context, unreadSnap) {
//                     //     final unread = unreadSnap.data ?? 0;
//                     //     return ListTile(
//                     //       contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
//                     //       leading: CircleAvatar(
//                     //         radius: 24,
//                     //         backgroundColor: Colors.grey[200],
//                     //         child: _initialsFor(lastMessage['sender_name'] as String?),
//                     //       ),
//                     //       title: Row(
//                     //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     //         children: [
//                     //           Text(
//                     //             lastMessage['sender_name'] as String? ?? 'Chat',
//                     //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     //           ),
//                     //           Text(
//                     //             _formatTimestamp(updatedAt),
//                     //             style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     //           ),
//                     //         ],
//                     //       ),
//                     //       subtitle: Text(
//                     //         _lastMessagePreview(lastMessage),
//                     //         maxLines: 1,
//                     //         overflow: TextOverflow.ellipsis,
//                     //         style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                     //       ),
//                     //       trailing: unread > 0
//                     //           ? Container(
//                     //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     //         decoration: BoxDecoration(
//                     //           color: Colors.blue[700],
//                     //           borderRadius: BorderRadius.circular(12),
//                     //         ),
//                     //         child: Text(
//                     //           '$unread',
//                     //           style: TextStyle(
//                     //             color: Colors.white,
//                     //             fontWeight: FontWeight.bold,
//                     //             fontSize: 12,
//                     //           ),
//                     //         ),
//                     //       )
//                     //           : const SizedBox.shrink(),
//                     //       onTap: () {
//                     //         Navigator.of(context).push(
//                     //           MaterialPageRoute(
//                     //             builder: (_) => ChatScreen(otherUserUuid: otherUuid.isEmpty ? '' : otherUuid),
//                     //           ),
//                     //         );
//                     //       },
//                     //     );
//                     //   },
//                     // );
//
//                     return FutureBuilder<Map<String, dynamic>?>(
//                       future: ApiService().getUserInfo(otherUuid),
//                       builder: (context, userSnap) {
//                         final userData = userSnap.data ?? {};
//                         final displayName = userData['display_name'] ?? lastMessage['sender_name'] as String? ?? 'Chat';
//                         final avatarUrl = userData['profile_photo_url'] as String? ?? '';
//
//                         return FutureBuilder<int>(
//                           future: _chatService.getUnreadMessagesCount(doc.id),
//                           builder: (context, unreadSnap) {
//                             final unread = unreadSnap.data ?? 0;
//                             return ListTile(
//                               contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
//                               leading: CircleAvatar(
//                                 radius: 24,
//                                 backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
//                                 backgroundColor: avatarUrl.isEmpty ? Colors.grey[200] : null,
//                                 child: avatarUrl.isEmpty ? _initialsFor(displayName) : null,
//                               ),
//                               title: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     displayName,
//                                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                                   ),
//                                   Text(
//                                     _formatTimestamp(updatedAt),
//                                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                                   ),
//                                 ],
//                               ),
//                               subtitle: Text(
//                                 _lastMessagePreview(lastMessage),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                               ),
//                               trailing: unread > 0
//                                   ? Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue[700],
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   '$unread',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               )
//                                   : const SizedBox.shrink(),
//                               onTap: () {
//                                 Navigator.of(context).push(
//                                   MaterialPageRoute(
//                                     builder: (_) => ChatScreen(otherUserUuid: otherUuid.isEmpty ? '' : otherUuid),
//                                   ),
//                                 );
//                               },
//                             );
//                           },
//                         );
//                       },
//                     );
//
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _initialsFor(String? name) {
//     final n = (name ?? '').trim();
//     if (n.isEmpty) return Text('?', style: TextStyle(color: Colors.grey[600]));
//     final parts = n.split(' ');
//     if (parts.length == 1) return Text(parts.first[0].toUpperCase(), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
//     return Text(
//       (parts[0][0] + parts[1][0]).toUpperCase(),
//       style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//     );
//   }
//
//   String _lastMessagePreview(Map<String, dynamic> lastMessage) {
//     final type = (lastMessage['type'] as String?) ?? 'text';
//     switch (type) {
//       case 'image':
//         return '📷 ${lastMessage['content'] ?? 'Photo'}';
//       case 'voice':
//         return '🎤 Voice message';
//       case 'file':
//         return '📎 ${lastMessage['content'] ?? 'File'}';
//       default:
//         return (lastMessage['content'] as String?) ?? '';
//     }
//   }
// }
