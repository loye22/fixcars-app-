import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class GetRequestsService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchRequests() async {
    try {
      final String url = '${ApiService.baseUrl}/requests/';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if the request was successful
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception('API returned unsuccessful response: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load requests: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching requests: $e');
    }
  }

  // Get only the requests data as a list
  Future<List<dynamic>> getRequestsList() async {
    final response = await fetchRequests();
    return response['data'] ?? [];
  }

  // Get only pending requests
  Future<List<dynamic>> getPendingRequests() async {
    final response = await fetchRequests();
    final allRequests = response['data'] ?? [];
    return allRequests.where((request) => request['status'] == 'pending').toList();
  }

  // Get only completed requests
  Future<List<dynamic>> getCompletedRequests() async {
    final response = await fetchRequests();
    final allRequests = response['data'] ?? [];
    return allRequests.where((request) => request['status'] == 'completed').toList();
  }

  // Get the total count of requests
  Future<int> getTotalCount() async {
    final response = await fetchRequests();
    return response['count'] ?? 0;
  }

  // Get the count of pending requests
  Future<int> getPendingCount() async {
    final pendingRequests = await getPendingRequests();
    return pendingRequests.length;
  }

  // Get the count of completed requests
  Future<int> getCompletedCount() async {
    final completedRequests = await getCompletedRequests();
    return completedRequests.length;
  }
}