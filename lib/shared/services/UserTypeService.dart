import 'dart:convert';

import 'api_service.dart';

class UserTypeService {
  final ApiService _apiService = ApiService();

  // Returns the full response from /api/isItsupplier/
  Future<Map<String, dynamic>> getUserType() async {
    try {
      final response = await _apiService.authenticatedGet(
        '${ApiService.baseUrl}/isItsupplier/',
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'is_supplier': false,
          'error': 'Failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'is_supplier': false,
        'error': e.toString()
      };
    }
  }
}