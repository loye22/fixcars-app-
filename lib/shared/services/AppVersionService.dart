import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';

class AppVersionService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> fetchAppVersions() async {
    try {
      final String url = '${ApiService.baseUrl}/app-versions';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load app versions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching app versions: $e');
    }
  }

  // Optional helper method to get the latest version
  Future<Map<String, dynamic>?> getLatestVersion() async {
    try {
      final versions = await fetchAppVersions();
      if (versions.isNotEmpty) {
        // Sort by created_at to get the latest version
        versions.sort((a, b) =>
            DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']))
        );
        return versions.first;
      }
      return null;
    } catch (e) {
      throw Exception('Error getting latest version: $e');
    }
  }

  // Optional helper method to check if update is required
  Future<bool> isUpdateRequired(String currentVersion) async {
    try {
      final latestVersion = await getLatestVersion();
      if (latestVersion != null) {
        // Compare versions and check force_update flag
        return _compareVersions(currentVersion, latestVersion['version']) < 0
            && latestVersion['force_update'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error checking update requirement: $e');
    }
  }

  // Helper method to compare version strings (e.g., "2.2.0" vs "1.0.0")
  int _compareVersions(String v1, String v2) {
    List<int> parts1 = v1.split('.').map(int.parse).toList();
    List<int> parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < parts1.length && i < parts2.length; i++) {
      if (parts1[i] != parts2[i]) {
        return parts1[i].compareTo(parts2[i]);
      }
    }
    return parts1.length.compareTo(parts2.length);
  }
}