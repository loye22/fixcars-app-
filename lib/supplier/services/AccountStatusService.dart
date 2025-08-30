import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class AccountStatusService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchAccountStatus() async {
    try {
      final String url = '${ApiService.baseUrl}/account-status';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load account status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching account status: $e');
    }
  }

  // Optional: Helper method to extract just the account_status object
  Future<Map<String, dynamic>> getAccountStatusData() async {
    final Map<String, dynamic> response = await fetchAccountStatus();
    return response['account_status'] as Map<String, dynamic>;
  }

  // Optional: Helper method to check if account is active
  Future<bool> isAccountActive() async {
    final Map<String, dynamic> accountStatus = await getAccountStatusData();
    return accountStatus['is_active'] as bool;
  }

  // Optional: Helper method to check approval status
  Future<String> getApprovalStatus() async {
    final Map<String, dynamic> accountStatus = await getAccountStatusData();
    return accountStatus['approval_status'] as String;
  }
}