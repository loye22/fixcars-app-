import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../shared/services/api_service.dart';


class SubmitReviewsService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> submitReview({
    required String supplierId,
    required int rating,
    required String comment,
  }) async {
    try {
      final url = '${ApiService.baseUrl}/reviews/$supplierId/create-update/';
      final body = {
        'rating': rating,
        'comment': comment,
      };

      final response = await _apiService.authenticatedPost(url, body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 404 || (data['error'] != null && data['error'].toString().toLowerCase().contains('supplier not found'))) {
        return {
          'success': false,
          'error': 'Supplier not found',
        };
      }

      return {
        'success': false,
        'error': '${data['error'] ?? data['message'] ?? 'Unknown server error'}. Response: ${response.body}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}