import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final String url = '${ApiService.baseUrl}/notifications/mark-read/';

      final Map<String, dynamic> body = {
        "notification_id": notificationId
      };

      final http.Response response = await _apiService.authenticatedPost(
        url,
        body,
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to mark notification as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }
}