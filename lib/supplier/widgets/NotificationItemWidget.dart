import 'package:flutter/material.dart';

class NotificationItemWidget extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  State<NotificationItemWidget> createState() => _NotificationItemWidgetState();
}

class _NotificationItemWidgetState extends State<NotificationItemWidget> {
  // Internal icon handling method
  Widget _getIcon(String type, bool isRead) {
    String assetPath;

    switch (type) {
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

  // Internal title handling method
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

  // Internal time formatting method
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

  // Show elegant popup dialog with notification details
  void _showNotificationDetails(BuildContext context) {
    final String type = widget.notification['type'] ?? 'general_notification';
    final String message = widget.notification['message'] ?? '';
    final String createdAt = widget.notification['created_at'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    _getIcon(type, true),
                    const SizedBox(width: 16),
                    Text(
                      _getTitleFromType(type),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Message content
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF444444),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Timestamp
                Text(
                  _formatTime(createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 24),

                // Close button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Închide',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract values from the notification map with null safety
    final String type = widget.notification['type'] ?? 'general_notification';
    final String message = widget.notification['message'] ?? '';
    final  bool isRead = widget.notification['is_read'] ?? false;
    final String createdAt = widget.notification['created_at'] ?? '';

    return GestureDetector(
      onTap: () {

        setState(() {
          widget.notification['is_read'] = true; // Update the notification map
        });

        // First call the onTap callback if provided
        widget.onTap?.call();

        // Then show the popup automatically
        _showNotificationDetails(context);
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Container(
          // margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
                _getIcon(type, isRead),

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
                            _getTitleFromType(type),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isRead
                                  ? const Color(0xFF666666)
                                  : const Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isRead)
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
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Time ago
                      Text(
                        _formatTime(createdAt),
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
      ),
    );
  }
}