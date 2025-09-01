import 'package:fixcars/shared/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PasswordResetService {

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/password-reset/request/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': result['success'] ?? false,
          'message': result['message'] ?? 'Eroare necunoscută',
        };
      } else {
        return {
          'success': false,
          'message': 'Eroare server: ${response.statusCode}',
        };
      }
    } catch (e) {
      throw Exception('Eroare de rețea: $e');
    }
  }
}