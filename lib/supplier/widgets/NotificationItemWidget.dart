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

  // Internal icon data based on type
  IconData _getIconData(String type) {
    switch (type) {
      case 'new_message':
        return Icons.message_outlined;
      case 'supplier_approval':
        return Icons.check_circle_outline;
      case 'request_update':
        return Icons.update_outlined;
      case 'general_notification':
        return Icons.notifications_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  // Internal color based on type
  Color _getColorForType(String type) {
    switch (type) {
      case 'new_message':
        return Colors.blue.shade300;
      case 'supplier_approval':
        return Colors.green.shade300;
      case 'request_update':
        return Colors.orange.shade300;
      case 'general_notification':
        return Colors.cyan.shade300;
      default:
        return Colors.grey.shade300;
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

  // Show elegant bottom sheet with notification details
  void _showNotificationDetails(BuildContext context) {
    final String type = widget.notification['type'] ?? 'general_notification';
    final String message = widget.notification['message'] ?? '';
    final String createdAt = widget.notification['created_at'] ?? '';
    final Color typeColor = _getColorForType(type);
    final IconData typeIcon = _getIconData(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: Colors.grey.shade800, width: 0.5),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),

                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: typeColor, width: 1.5),
                        ),
                        child: Icon(
                          typeIcon,
                          color: typeColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _getTitleFromType(type),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade700, thickness: 1),
                  const SizedBox(height: 24),

                  // Message content
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade300,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade700, thickness: 1),
                  const SizedBox(height: 16),

                  // Timestamp
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade700, width: 0.5),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Închide',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract values from the notification map with null safety
    final String type = widget.notification['type'] ?? 'general_notification';
    final String message = widget.notification['message'] ?? '';
    final bool isRead = widget.notification['is_read'] ?? false;
    final String createdAt = widget.notification['created_at'] ?? '';
    final Color typeColor = _getColorForType(type);
    final IconData typeIcon = _getIconData(type);

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.notification['is_read'] = true; // Update the notification map
        });

        // First call the onTap callback if provided
        widget.onTap?.call();

        // Then show the bottom sheet automatically
        _showNotificationDetails(context);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: isRead ? Colors.grey.shade800 : typeColor.withOpacity(0.5),
              width: isRead ? 0.5 : 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with icon and read indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: typeColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        typeIcon,
                        color: typeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getTitleFromType(type),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isRead ? Colors.grey.shade400 : Colors.white,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: typeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: typeColor.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Content text
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade300,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Time ago
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
