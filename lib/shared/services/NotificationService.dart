import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<bool> hasUnreadNotifications() async {
    try {
      final String url = '${ApiService.baseUrl}/notifications/has-unread';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['has_unread_notifications'] ?? false;
      } else {
        throw Exception('Failed to check unread notifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking unread notifications: $e');
    }
  }
}