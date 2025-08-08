import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Django backend URL
  static const String _baseMediaUrl = 'http://10.0.2.2:8000'; // Django backend URL


  static String get baseUrl => _baseUrl;


  Future<bool> isTokenExpired() async {
    final token = await getJwtToken();
    if (token == null) return true;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final jsonMap = json.decode(decoded);

      final exp = jsonMap['exp'] as int?;
      if (exp == null) return true;

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expirationTime.isBefore(DateTime.now().add(const Duration(minutes: 1)));
    } catch (e) {
      return true;
    }
  }


  // Reusable method for authenticated GET requests
  Future<http.Response> authenticatedGet(String url) async {
    final token = await getJwtToken();
    if (token == null) throw Exception('No authentication token found. Please log in.');
    http.Response response = await _makeGetRequest(url, token);
    // Handle token expiration
    if (response.statusCode == 401) {
      String? newToken = await refreshToken();
      if (newToken != null) {
        // Retry the request with the new token
        response = await _makeGetRequest(url, newToken);
      } else {
        throw Exception('Token refresh failed. Please log in again.');
      }
    }

    return response;
  }

  // Helper method for GET request
  Future<http.Response> _makeGetRequest(String url, String token) async {
    return await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Reusable method for authenticated POST requests
  Future<http.Response> authenticatedPost(String url, Map<String, dynamic> body) async {
    final token = await getJwtToken();
    if (token == null) throw Exception('No authentication token found. Please log in.');

    http.Response response = await _makePostRequest(url, token, body);

    // Handle token expiration
    if (response.statusCode == 401) {
      String? newToken = await refreshToken();
      if (newToken != null) {
        // Retry the request with the new token
        response = await _makePostRequest(url, newToken, body);
      } else {
        throw Exception('Token refresh failed. Please log in again.');
      }
    }

    return response;
  }

  // Helper method for POST request
  Future<http.Response> _makePostRequest(String url, String token, Map<String, dynamic> body) async {
    return await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }



  // Add this new method to the ApiService class
  Future<http.Response> authenticatedMultipartPostWithToken(
      String url,
      Map<String, String> fields, {
        XFile? file,
      }) async
  {
    final token = await getJwtToken();
    if (token == null) throw Exception('No authentication token found. Please log in.');

    // Make the initial multipart request
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('img', file.path));
    }

    var streamedResponse = await request.send();
    http.Response response = await http.Response.fromStream(streamedResponse);

    // Handle token expiration
    if (response.statusCode == 401) {
      String? newToken = await refreshToken();
      if (newToken != null) {
        // Retry with the new token
        request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers['Authorization'] = 'Bearer $newToken';
        request.fields.addAll(fields);

        if (file != null) {
          request.files.add(await http.MultipartFile.fromPath('img', file.path));
        }

        streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        throw Exception('Token refresh failed. Please log in again.');
      }
    }

    return response;
  }

  // Client Signup API
  Future<Map<String, dynamic>> clientSignup({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String photoUrl,
  }) async
  {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/client-signup/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'photo_url': _baseMediaUrl + photoUrl,
        }),
      ).timeout(Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': '${data['error'] ?? data['message'] ?? 'Eroare necunoscută de la server'}.'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e is SocketException
            ? 'Fără conexiune la internet. Detalii: $e'
            : e is TimeoutException
            ? 'Cererea a expirat. Detalii: $e'
            : 'Eroare de rețea: $e'
      };
    }
  }

  // File Upload API
  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload-file/'));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', file.path.split('.').last),
        ),
      );
      final streamedResponse = await request.send().timeout(Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': '${data['error'] ?? data['message'] ?? 'Eroare necunoscută de la server'}. Răspuns server: ${response.body}'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e is SocketException
            ? 'Fără conexiune la internet. Detalii: $e'
            : e is TimeoutException
            ? 'Cererea a expirat. Detalii: $e'
            : 'Eroare de rețea: $e'
      };
    }
  }

  // OTP Validation API
  Future<Map<String, dynamic>> validateOtp(String userId, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/validate-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'otp': otp,
        }),
      ).timeout(Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': '${data['message'] ?? 'Eroare necunoscută de la server'}'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e is SocketException
            ? 'Fără conexiune la internet. Detalii: $e'
            : e is TimeoutException
            ? 'Cererea a expirat. Detalii: $e'
            : 'Eroare de rețea: $e'
      };
    }
  }

  // Resend OTP API
  Future<Map<String, dynamic>> resendOtp(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/resend-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
        }),
      ).timeout(Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': '${data['message'] ?? 'Eroare necunoscută de la server'}. Răspuns server: ${response.body}'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e is SocketException
            ? 'Fără conexiune la internet. Detalii: $e'
            : e is TimeoutException
            ? 'Cererea a expirat. Detalii: $e'
            : 'Eroare de rețea: $e'
      };
    }
  }

// // Add these methods to ApiService
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    return userData != null ? jsonDecode(userData) : null;
  }

  Future<void> storeUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> loginData) async {
    try {
      var response = await http.post(
        Uri.parse('$_baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        await storeTokens(
            responseData['access_token'],
            responseData['refresh_token']
        );
        await storeUserData(responseData['user']);
        return {
          'success': true,
          'user_type': responseData['user']['user_type'],
        };
      } else {
        var responseData = jsonDecode(response.body);
        return responseData;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error during login: $e',
      };
    }
  }

  Future<void> storeTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

// Add this method to check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') != null;
  }

// In ApiService class
  Future<bool> isTokenValid() async {
    final token = await getJwtToken();
    if (token == null) return false;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/validate-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  Future<String?> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) {
        print('No refresh token found');
        return null;
      }

      print('Attempting to refresh token with refresh token: $refreshToken');

      final response = await http.post(
        Uri.parse('$_baseUrl/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      ).timeout(const Duration(seconds: 5));

      print('Refresh token response status: ${response.statusCode}');
      print('Refresh token response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newAccessToken = responseData['access'];
        print('Successfully refreshed token: $newAccessToken');
        await storeJwtToken(newAccessToken);
        return newAccessToken;
      } else {
        print('Token refresh failed with status: ${response.statusCode}');
        await clearAllData(); // Clear invalid tokens
        return null;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      await clearAllData(); // Clear invalid tokens on error
      return null;
    }
  }

  // Store JWT token
  Future<void> storeJwtToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Get JWT token
  Future<String?> getJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Clear JWT token
  Future<void> clearJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
  }
}

