import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/services/api_service.dart';

class ServicesService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchServices({String category = 'mecanic_auto'}) async {
    try {
      final String url = '${ApiService.baseUrl}/services-by-category/?category=$category';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load services: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching services: $e');
    }
  }
}