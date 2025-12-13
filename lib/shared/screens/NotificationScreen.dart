import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../supplier/services/MarkNotificationAsReadService.dart';
import '../../client/services/ClientNotificationService.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ClientNotificationService _notificationService = ClientNotificationService();
  final NotificationService _notificationServiceread = NotificationService();
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  List<Map<String, dynamic>> _notificari = [];


  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    try {
      final notifications = await _notificationService.fetchNotifications();
      setState(() {
        _notificari = notifications;
      });
      return notifications;
    } catch (e) {
      // Handle error appropriately
      rethrow;
    }
  }

  // Function to show notification details
  void _arataDetaliiNotificare(int index) {
    _markNotificationAsRead(_notificari[index]["notification_id"]);

    // Mark as read when opened (you might want to call an API endpoint for this)
    if (!_notificari[index]['is_read']) {
      setState(() {
        _notificari[index]['is_read'] = true;
      });
      // Here you would typically call an API endpoint to mark as read
      // _markAsRead(_notificari[index]['notification_id']);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            _getTitleFromType(_notificari[index]['type']),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _notificari[index]['message'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Primit: ${_formatTime(_notificari[index]['created_at'])}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Închide'),
            ),
          ],
        );
      },
    );
  }

  String _getTitleFromType(String type) {
    switch (type) {
      case 'new_message':
        return 'Mesaj Nou';
      case 'supplier_approval':
        return 'Aprobare Furnizor';
      case 'request_update':
        return 'Actualizare Cerere';
      case 'general_notification':
        return 'Notificare';
      default:
        return 'Notificare';
    }
  }

  String _formatTime(String createdAt) {
    try {
      final DateTime dateTime = DateTime.parse(createdAt);
      final Duration difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'acum câteva secunde';
      } else if (difference.inMinutes < 60) {
        return 'acum ${difference.inMinutes} minute';
      } else if (difference.inHours < 24) {
        return 'acum ${difference.inHours} ore';
      } else {
        return 'acum ${difference.inDays} zile';
      }
    } catch (e) {
      return createdAt;
    }
  }

  // Helper method to get icon based on notification type
  Widget _obtineIconita(String tip, bool citit) {
    String assetPath;

    switch (tip) {
      case 'new_message':
        assetPath = 'assets/mes_no.png';
        break;
      case 'supplier_approval':
        assetPath = 'assets/approved.png';
        break;
      case 'request_update':
        assetPath = 'assets/update_no.png';
        break;
      case 'general_notification':
        assetPath = 'assets/general_no.png';
        break;
      default:
        assetPath = 'assets/general_no.png';
    }

    return Image.asset(
      assetPath,
      width: 40,
      height: 40,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),

      appBar: AppBar(
        backgroundColor: Color(0xFFF3F4F6),
        // leading: IconButton(
        //   icon: Icon(CupertinoIcons.back, color: Colors.black,), // Use the specific Cupertino icon
        //   onPressed: () {
        //     // This is the function that makes it go back to the previous screen
        //     Navigator.of(context).pop();
        //   },
        // ),

        title: const Text(

          'Notificări',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _notificationsFuture = _fetchNotifications();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return  Center(
              child: Padding(
                // Retain original padding, or slightly increase for better framing
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 💎 Elegant Icon Container
                    Container(
                      padding: const EdgeInsets.all(28), // Slightly increased padding
                      decoration: BoxDecoration(
                        color: Colors.white, // High-contrast base
                        // Use a dark, sophisticated border instead of a light fill
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        borderRadius: BorderRadius.circular(50.0), // Rounded rectangle/Squircle shape
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05), // Subtle, soft shadow
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_off_outlined, // A more context-appropriate icon
                        size: 68, // Slightly larger icon
                        color: Color(0xFF1B2A41), // Deep, sophisticated Navy Blue/Charcoal
                      ),
                    ),
                    const SizedBox(height: 32), // Increased spacing for breathability

                    // 📝 Main Title (Preserving original text and error focus)
                    const Text(
                      'Eroare la încărcarea notificărilor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22, // Slightly larger, more imposing
                        fontWeight: FontWeight.w700, // Bold and distinct
                        color: Color(0xFF1B2A41), // Matching dark color
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 💡 Subtitle/Detailed Error (Preserving original logic/variable)
                    Text(
                      // Logic preserved: using the dynamic snapshot.error
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600, // Elegant neutral color
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 40), // More vertical separation

                    // 🔄 Elegant Button (Preserving original size/logic)
                    SizedBox(
                      width: 180, // Slightly wider for elegance
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          // Using a subtle color for the button to avoid an emergency look
                          backgroundColor: const Color(0xFF4C5B7F), // Muted Blue-Gray/Slate
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Modern, slightly rounded
                          ),
                          elevation: 4, // Subtle lift
                        ),
                        // 🚨 Logic Preserved 🚨
                        onPressed: () {
                          setState(() {
                            _notificationsFuture = _fetchNotifications();
                          });
                        },
                        child: const Text(
                          'Încearcă din nou', // Preserved original text
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
            //   Center(
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       const Icon(Icons.error_outline, size: 74, color: Colors.red),
            //       const SizedBox(height: 16),
            //       const Text(
            //         'Eroare la încărcarea notificărilor',
            //         style: TextStyle(fontSize: 18),
            //       ),
            //       const SizedBox(height: 8),
            //       Text(
            //         snapshot.error.toString(),
            //         textAlign: TextAlign.center,
            //         style: const TextStyle(color: Colors.red),
            //       ),
            //       const SizedBox(height: 16),
            //       ElevatedButton(
            //         onPressed: () {
            //           setState(() {
            //             _notificationsFuture = _fetchNotifications();
            //           });
            //         },
            //         child: const Text('Încearcă din nou'),
            //       ),
            //     ],
            //   ),
            // );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nu aveți notificări',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: _notificari.length,
              itemBuilder: (context, index) {
                final notificare = _notificari[index];
                return GestureDetector(
                  onTap: () => _arataDetaliiNotificare(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Notification icon using custom assets
                          _obtineIconita(notificare['type'], notificare['is_read']),

                          const SizedBox(width: 16),

                          // Notification content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title with read indicator
                                Row(
                                  children: [
                                    Text(
                                      _getTitleFromType(notificare['type']),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: notificare['is_read']
                                            ? const Color(0xFF666666)
                                            : const Color(0xFF222222),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!notificare['is_read'])
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Content text
                                Text(
                                  notificare['message'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF666666),
                                    height: 1.4,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Time ago
                                Text(
                                  _formatTime(notificare['created_at']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF999999),
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
        },
      ),
    );
  }
  void _markNotificationAsRead(String notificationId) async {
    try {
      await _notificationServiceread.markNotificationAsRead(notificationId);
      print('Notification marked as read successfully');
      // Optionally update UI or show a success message
    } catch (e) {
      print('Error: $e');
      // Optionally show an error message to the user
    }
  }
}



