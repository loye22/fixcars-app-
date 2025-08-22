import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class SupplierProfileSummaryService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchSupplierProfile() async {
    try {
      final String url = '${ApiService.baseUrl}/supplierProfileSummary/';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load supplier profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching supplier profile: $e');
    }
  }
}