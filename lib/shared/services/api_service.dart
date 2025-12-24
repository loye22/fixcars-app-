
import 'dart:async';
import 'dart:io';
import 'package:fixcars/shared/services/OneSignalService.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  // static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Django backend URL
  // static const String _baseMediaUrl = 'http://10.0.2.2:8000/media/'; // Django backend URL
  //
  static const String _baseUrl = 'http://192.168.1.129:8000/api'; // Django backend URL
  static const String _baseMediaUrl = 'http://192.168.1.129:8000/media/'; // Django backend URL

  //  static const String _baseUrl = 'https://www.app.fixcars.ro/api'; // Django backend URL
  //  static const String _baseMediaUrl = 'https://www.app.fixcars.ro/media/'; // Django backend URL
  //


  static final TileLayer _lightTileLayer = TileLayer(
    urlTemplate: "https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
    subdomains: const ['a', 'b', 'c', 'd'],
    userAgentPackageName: 'com.example.app',
  );

  // Public getter to access the private TileLayer
  static TileLayer get lightTileLayer => _lightTileLayer;
  static String get baseUrl => _baseUrl;
  static String get baseMediaUrl => _baseMediaUrl;


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
          'photo_url': photoUrl,
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


  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      // Validate file existence
      if (!file.existsSync()) {
        return {
          'success': false,
          'error': 'Fișierul nu există: ${file.path}',
        };
      }

      // Prepare the multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload-file/'));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', file.path.split('.').last.toLowerCase()),
        ),
      );

      // Add headers if needed (e.g., authentication)
      request.headers['Accept'] = 'application/json';

      // Send request with timeout
      final streamedResponse = await request.send().timeout(Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      // Log response for debugging
      print("===========================================================");
      print("uploadFile Response");
      print("Status: ${response.statusCode}");
      print("Headers: ${response.headers}");
      print("Body: ${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}");
      print("===========================================================");
      print(MediaType('image', file.path.split('.').last.toLowerCase()));

      print("===========================================================");
      print("===========================================================");

      // Check HTTP status code
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Verify content type
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          return {
            'success': false,
            'error': 'Răspunsul serverului nu este JSON. Content-Type: $contentType',
            'responseBody': response.body,
          };
        }

        try {
          final data = jsonDecode(response.body);
          return {'success': true, 'data': data};
        } catch (e) {
          return {
            'success': false,
            'error': 'Eroare la parsarea JSON: $e',
            'responseBody': response.body,
          };
        }
      } else {
        // Handle non-201 status codes
        String errorMessage = 'Eroare server: ${response.statusCode} ${response.reasonPhrase}';
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['error'] ?? data['message'] ?? errorMessage;
        } catch (_) {
          // Non-JSON response
          errorMessage = 'Răspuns invalid de la server (nu este JSON): ${response.body}';
        }
        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
          'responseBody': response.body,
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'error': 'Fără conexiune la internet. Detalii: $e',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'error': 'Cererea a expirat. Detalii: $e',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Eroare neașteptată: $e',
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

        // Initialize OneSignal after successful login
        await OneSignalService.initializeOneSignal();

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

  // Add this method to your ApiService class for supplier signup
  Future<Map<String, dynamic>> supplierSignup({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String photoUrl,
    required List<String> coverPhotosUrls,
    required double latitude,
    required double longitude,
    required String bio,
    required String address

  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/supplier-signup/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'photo_url': photoUrl,
          'cover_photos_urls': coverPhotosUrls,
          'latitude': latitude,
          'longitude': longitude,
          'bio': bio,
          'business_address' : address
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

  /// refactor this asn place it in the firebase servisesce
  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    try {
      final response = await authenticatedGet('$_baseUrl/user/$userId/');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get user info: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching user info: $e');
    }
  }



  // Future<bool> isServerReachable() async {
  //   try {
  //     print("this is isServerReachable()  start}" );
  //
  //     // Use a simple endpoint that should always be available
  //     final response = await http.get(
  //       Uri.parse('$_baseUrl/health/'), // You'll need to create this endpoint
  //       headers: {'Content-Type': 'application/json'},
  //     ).timeout(const Duration(seconds: 5));
  //
  //     print("this is isServerReachable() funtion  ${response.body}" );
  //     // Consider server reachable if we get any 2xx or 3xx response
  //     return response.statusCode >= 200 && response.statusCode < 400;
  //   } on SocketException {
  //     // No internet connection
  //     return false;
  //   } on TimeoutException {
  //     // Server didn't respond in time
  //     return false;
  //   } on HttpException {
  //     // HTTP error
  //     return false;
  //   } catch (e) {
  //     print('Server health check error: $e');
  //     return false;
  //   }
  // }

  Future<bool> isServerReachable() async {
    try {
      print("Checking server reachability...");
      print("Base URL: $_baseUrl");

      // Create a custom client with better timeout handling
      final client = http.Client();

      // Use a simple endpoint that should always be available
      final response = await client.get(
        Uri.parse('$_baseUrl/health/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        print("Server request timed out - server is likely down");
        return http.Response('Timeout', 408); // Return a custom response
      });

      print("Server response status: ${response.statusCode}");

      // Consider server reachable if we get any 2xx or 3xx response
      final isReachable = response.statusCode >= 200 && response.statusCode < 400;
      print("Server reachable: $isReachable");

      client.close(); // Always close the client
      return isReachable;

    } on SocketException catch (e) {
      print("SocketException - No connection to server: $e");
      return false;
    } on TimeoutException catch (e) {
      print("TimeoutException - Server didn't respond in time: $e");
      return false;
    } on HttpException catch (e) {
      print("HttpException - HTTP error: $e");
      return false;
    } catch (e) {
      print('Unexpected error in server health check: $e');
      return false;
    }
  }


  // Reusable method for authenticated PUT requests
  Future<http.Response> authenticatedPut(String url, Map<String, dynamic> body) async {
    final token = await getJwtToken();
    if (token == null) throw Exception('No authentication token found. Please log in.');

    http.Response response = await _makePutRequest(url, token, body);

    // Handle token expiration
    if (response.statusCode == 401) {
      String? newToken = await refreshToken();
      if (newToken != null) {
        // Retry the request with the new token
        response = await _makePutRequest(url, newToken, body);
      } else {
        throw Exception('Token refresh failed. Please log in again.');
      }
    }

    return response;
  }

// Helper method for PUT request
  Future<http.Response> _makePutRequest(String url, String token, Map<String, dynamic> body) async {
    return await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }


  Future<Map<String, dynamic>> uploadFile2(File file) async {
    if (!file.existsSync()) {
      return {'success': false, 'error': 'Fișierul nu există'};
    }

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final splitMime = mimeType.split('/');

    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload-file/'));
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType(splitMime[0], splitMime[1]),
    ));
    request.headers['Accept'] = 'application/json';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final data = jsonDecode(response.body);
      return {'success': false, 'error': data['error'] ?? 'Eroare la upload'};
    }
  }


  // Reusable method for authenticated DELETE requests
  Future<http.Response> authenticatedDelete(String url) async {
    final token = await getJwtToken();
    if (token == null) throw Exception('No authentication token found. Please log in.');

    http.Response response = await _makeDeleteRequest(url, token);

    // Handle token expiration
    if (response.statusCode == 401) {
      String? newToken = await refreshToken();
      if (newToken != null) {
        // Retry the request with the new token
        response = await _makeDeleteRequest(url, newToken);
      } else {
        throw Exception('Token refresh failed. Please log in again.');
      }
    }

    return response;
  }

  // Helper method for DELETE request
  Future<http.Response> _makeDeleteRequest(String url, String token) async {
    return await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }


}
