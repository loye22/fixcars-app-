// referral_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class ReferralService {
  final ApiService _apiService = ApiService();

  /// Calls POST /referedBy/ with {"email": email}
  Future<Map<String, dynamic>> referByEmail(String email) async {
    try {
      final String url = '${ApiService.baseUrl}/referedBy/';

      final Map<String, dynamic> body = {
        "email": email,
      };

      final http.Response response = await _apiService.authenticatedPost(
        url,
         body,

      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to refer by email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error referring by email: $e');
    }
  }
}