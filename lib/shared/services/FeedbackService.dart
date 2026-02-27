import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../shared/services/api_service.dart';

class FeedbackService {
  final ApiService _apiService = ApiService();
  Future<Map<String, dynamic>> submitFeedback({
    required String text,
    String? voiceUrl,
    String? imageUrl1,
    String? imageUrl2,
    String? imageUrl3,
  }) async

  {
    try {
      final String url = '${ApiService.baseUrl}/feedback/';

      // Build the request body with required text field
      final Map<String, dynamic> body = {
        'text': text,
      };

      // Add optional fields only if they are not null and not empty
      if (voiceUrl != null && voiceUrl.isNotEmpty) {
        body['voice_url'] = voiceUrl;
      }
      if (imageUrl1 != null && imageUrl1.isNotEmpty) {
        body['image_url_1'] = imageUrl1;
      }
      if (imageUrl2 != null && imageUrl2.isNotEmpty) {
        body['image_url_2'] = imageUrl2;
      }
      if (imageUrl3 != null && imageUrl3.isNotEmpty) {
        body['image_url_3'] = imageUrl3;
      }

      // Make the authenticated POST request
      final http.Response response = await _apiService.authenticatedPost(url, body);

      // Parse the response
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Feedback submitted successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? responseData['message'] ?? 'Failed to submit feedback',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error submitting feedback: $e',
      };
    }
  }


}