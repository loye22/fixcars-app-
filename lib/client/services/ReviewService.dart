import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class ReviewService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> fetchReviews(String supplierId) async {
    try {
      final String url = '${ApiService.baseUrl}/reviews/$supplierId';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // Extract the 'reviews' key, assuming it contains a list
        final List<dynamic> reviews = data['data'] ?? [];
        return reviews.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching reviews: $e');
    }
  }
}