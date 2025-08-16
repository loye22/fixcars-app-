import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class SupplierProfileService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchSupplierProfile({required String userId}) async {
    try {
      final String url = '${ApiService.baseUrl}/supplierProfile/$userId/';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
          };
        } else {
          throw Exception('Failed to load supplier profile: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load supplier profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching supplier profile: $e',
      };
    }
  }
}