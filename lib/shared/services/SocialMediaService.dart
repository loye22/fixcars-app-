import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class SocialMediaService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchSocialMedia() async {
    try {
      final String url = '${ApiService.baseUrl}/user/social-media/';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'No profile found'};
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load social media: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error fetching social media: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSocialMedia(Map<String, dynamic> updates) async {
    try {
      final String url = '${ApiService.baseUrl}/user/social-media/';

      final http.Response response = await _apiService.authenticatedPost(url, updates);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? data['errors'] ?? 'Failed to update social media: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error updating social media: $e'};
    }
  }
}