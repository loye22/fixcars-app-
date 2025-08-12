import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class BrandService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> fetchBrands() async {
    try {
      final String url = '${ApiService.baseUrl}/brands';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load brands: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching brands: $e');
    }
  }
}