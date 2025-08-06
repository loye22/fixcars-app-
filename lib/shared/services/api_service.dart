import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Django backend URL
  static const String _baseMediaUrl = 'http://10.0.2.2:8000'; // Django backend URL

  // Client Signup API
  Future<Map<String, dynamic>> clientSignup({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/client-signup/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'photo_url': _baseMediaUrl+photoUrl,
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

  // Login API
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
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
}
// import 'dart:async';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:http_parser/http_parser.dart';
//
// class ApiService {
//   static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Replace with your Django backend URL
//
//   // Client Signup API
//   Future<Map<String, dynamic>> clientSignup({
//     required String fullName,
//     required String email,
//     required String password,
//     required String phone,
//     required String photoUrl,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/client-signup/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'full_name': fullName,
//           'email': email,
//           'password': password,
//           'phone': phone,
//           'photo_url': photoUrl,
//         }),
//       ).timeout(Duration(seconds: 10));
//
//       final data = jsonDecode(response.body);
//       if (response.statusCode == 201) {
//         return {'success': true, 'data': data};
//       }
//       return {'success': false, 'error': response.body?? data['message'] ?? 'Eroare necunoscută de la server'};
//     } catch (e) {
//       return {
//         'success': false,
//         'error': e is SocketException
//             ? 'Fără conexiune la internet'
//             : e is TimeoutException
//             ? 'Cererea a expirat'
//             : 'Eroare de rețea: $e'
//       };
//     }
//   }
//
//   // File Upload API
//   Future<Map<String, dynamic>> uploadFile(File file) async {
//     try {
//       var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload-file/'));
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'file',
//           file.path,
//           contentType: MediaType('image', file.path.split('.').last),
//         ),
//       );
//       final streamedResponse = await request.send().timeout(Duration(seconds: 10));
//       final response = await http.Response.fromStream(streamedResponse);
//       final data = jsonDecode(response.body);
//
//       if (response.statusCode == 201) {
//         return {'success': true, 'data': data};
//       }
//       return {'success': false, 'error': response.body ?? data['message'] ?? 'Eroare necunoscută de la server'};
//     } catch (e) {
//       return {
//         'success': false,
//         'error': e is SocketException
//             ? 'Fără conexiune la internet'
//             : e is TimeoutException
//             ? 'Cererea a expirat'
//             : 'Eroare de rețea: $e'
//       };
//     }
//   }
//
//   // OTP Validation API
//   Future<Map<String, dynamic>> validateOtp(String userId, String otp) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/validate-otp/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'user_id': userId,
//           'otp': otp,
//         }),
//       ).timeout(Duration(seconds: 10));
//
//       final data = jsonDecode(response.body);
//       if (response.statusCode == 200 && data['status'] == 'success') {
//         return {'success': true, 'data': data};
//       }
//       return {'success': false, 'error': data['message'] ?? 'Eroare necunoscută de la server'};
//     } catch (e) {
//       return {
//         'success': false,
//         'error': e is SocketException
//             ? 'Fără conexiune la internet'
//             : e is TimeoutException
//             ? 'Cererea a expirat'
//             : 'Eroare de rețea: $e'
//       };
//     }
//   }
//
//   // Resend OTP API
//   Future<Map<String, dynamic>> resendOtp(String userId) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/resend-otp/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'user_id': userId,
//         }),
//       ).timeout(Duration(seconds: 10));
//
//       final data = jsonDecode(response.body);
//       if (response.statusCode == 200 && data['status'] == 'success') {
//         return {'success': true, 'data': data};
//       }
//       return {'success': false, 'error': data['message'] ?? 'Eroare necunoscută de la server'};
//     } catch (e) {
//       return {
//         'success': false,
//         'error': e is SocketException
//             ? 'Fără conexiune la internet'
//             : e is TimeoutException
//             ? 'Cererea a expirat'
//             : 'Eroare de rețea: $e'
//       };
//     }
//   }
//
//   // Login API
//   Future<Map<String, dynamic>> login(String email, String password) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/login/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'email': email,
//           'password': password,
//         }),
//       ).timeout(Duration(seconds: 10));
//
//       final data = jsonDecode(response.body);
//       if (response.statusCode == 200 && data['success']) {
//         return {'success': true, 'data': data};
//       }
//       return {'success': false, 'error': data['message'] ?? 'Eroare necunoscută de la server'};
//     } catch (e) {
//       return {
//         'success': false,
//         'error': e is SocketException
//             ? 'Fără conexiune la internet'
//             : e is TimeoutException
//             ? 'Cererea a expirat'
//             : 'Eroare de rețea: $e'
//       };
//     }
//   }
// }