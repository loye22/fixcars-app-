import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

enum RequestStatus {
  accepted,
  completed,
  expired,
  pending,
  rejected;

  String get value {
    switch (this) {
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.completed:
        return 'completed';
      case RequestStatus.expired:
        return 'expired';
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.rejected:
        return 'rejected';
    }
  }
}

class RequestService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> updateRequestStatus({
    required String requestId,
    required RequestStatus status,
  }) async {
    try {
      final String url = '${ApiService.baseUrl}/requests/update-status/';

      final Map<String, dynamic> requestBody = {
        'request_id': requestId,
        'status': status.value,
      };

      final http.Response response = await _apiService.authenticatedPost(
        url,
        requestBody, // Pass the map directly, no need for json.encode
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to update request status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating request status: $e');
    }
  }
}