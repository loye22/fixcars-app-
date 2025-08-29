import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class PendingCountService {
  final ApiService _apiService = ApiService();

  Future<int> fetchPendingCount() async {
    try {
      final String url = '${ApiService.baseUrl}/requests/pending-count/';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if the request was successful and extract the pending_count
        if (data['success'] == true) {
          return data['pending_count'] ?? 0;
        } else {
          throw Exception('API returned unsuccessful response: $data');
        }
      } else {
        throw Exception('Failed to load pending count: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching pending count: $e');
    }
  }
}