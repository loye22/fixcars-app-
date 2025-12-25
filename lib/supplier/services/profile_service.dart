import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';


class ProfileService {
  final ApiService _apiService = ApiService();

  /// Retrieves the user profile data from the backend.
  /// Uses authenticatedGet to handle JWT tokens and auto-refresh.
  Future<Map<String, dynamic>> getProfileData() async {
    try {
      final response = await _apiService.authenticatedGet('${ApiService.baseUrl}/user/profile/');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'User profile retrieved successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve profile',
          'errors': data['errors']
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while fetching profile data',
        'error': e.toString(),
      };
    }
  }

  /// Updates the user profile data.
  /// Uses authenticatedPut to handle JWT tokens and auto-refresh.
  Future<Map<String, dynamic>> updateProfileData({
    required String fullName,
    required String profilePhoto,
    required String phone,
    required String businessAddress,
    required String bio,
    required List<String> coverPhotos,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "full_name": fullName,
        "profile_photo": profilePhoto,
        "phone": phone,
        "business_address": businessAddress,
        "bio": bio,
        "cover_photos": coverPhotos,
      };

      final response = await _apiService.authenticatedPut(
        '${ApiService.baseUrl}/user/profile/update/',
        body,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      print("===================================================");
      print(data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
          'errors': data['errors']
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while updating profile data',
        'error': e.toString(),
      };
    }
  }
}