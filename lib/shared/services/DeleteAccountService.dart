import 'dart:convert';
import '../../shared/services/api_service.dart';

class DeleteAccountService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final String url = '${ApiService.baseUrl}/delete-account/';
      final response = await _apiService.authenticatedPost(url,{});

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to delete account: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }
}