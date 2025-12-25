import 'dart:convert';
import 'package:fixcars/shared/services/api_service.dart';

class BusinessHourService {
  final ApiService _apiService = ApiService();
  static const String _endpoint = '/business-hours/';

  /// Fetches the current business hours from the API
  Future<Map<String, dynamic>?> getBusinessHours() async {
    try {
      final response = await _apiService.authenticatedGet(
        '${ApiService.baseUrl}$_endpoint',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception('Failed to fetch business hours: ${data['message']}');
        }
      } else {
        throw Exception('Failed to fetch business hours: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getBusinessHours: $e');
      return null;
    }
  }


  // Update this method in BusinessHourService.dart
  Future<bool> updateBusinessHours(Map<String, dynamic> updatedData) async {
    try {
      // documentation specifies /api/business-hours/update/ for PUT
      final response = await _apiService.authenticatedPut(
        '${ApiService.baseUrl}/business-hours/update/',
        updatedData,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error in updateBusinessHours: $e');
      return false;
    }
  }

  /// Updates the business hours (dummy implementation for now)
  // Future<bool> updateBusinessHours(Map<String, dynamic> updatedData) async {
  //   try {
  //     final response = await _apiService.authenticatedPost(
  //       '${ApiService.baseUrl}$_endpoint',
  //       updatedData,
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final Map<String, dynamic> data = jsonDecode(response.body);
  //       return data['success'] == true;
  //     } else {
  //       print('Failed to update business hours: ${response.statusCode}');
  //       return false;
  //     }
  //   } catch (e) {
  //     print('Error in updateBusinessHours: $e');
  //     return false;
  //   }
  // }
}
