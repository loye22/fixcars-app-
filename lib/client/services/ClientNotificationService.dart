import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class ClientNotificationService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final String url = '${ApiService.baseUrl}/notifications';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Failed to load notifications: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }
}