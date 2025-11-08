import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';
class SupplierOptionsService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchSupplierOptions() async {
    try {
      final String url = '${ApiService.baseUrl}/supplier-brand-service-options/';
      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        if (decodedJson['success'] != true) {
          throw Exception('API returned success: false');
        }
        return decodedJson['data'] as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to load options: ${response.statusCode} – ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching options: $e');
    }
  }
}