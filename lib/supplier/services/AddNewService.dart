import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fixcars/shared/services/api_service.dart';

class AddNewService {
  final ApiService _apiService = ApiService();

  // New method for bulk creation with the updated payload format
  // Future<Map<String, dynamic>> addSupplierBrandServiceBulk({
  //   required String city,
  //   required String sector,
  //   required double latitude,
  //   required double longitude,
  //   required List<Map<String, dynamic>> payloads,
  // }) async
  //
  // {
  //   try {
  //     final Map<String, dynamic> requestBody = {
  //       "total_payloads": payloads.length,
  //       "shared_location": {
  //         "city": city,
  //         "sector": sector,
  //         "latitude": latitude,
  //         "longitude": longitude,
  //         "is_real_location": true,
  //       },
  //       "payloads": payloads,
  //       "metadata": {
  //         "price": 0.0,
  //         "created_at": DateTime.now().toIso8601String(),
  //       },
  //     };
  //
  //     // Use the authenticatedPost method from ApiService
  //     final response = await _apiService.authenticatedPost(
  //       '${ApiService.baseUrl}/supplier-brand-services/bulk/',
  //       // Note: added /bulk/
  //       requestBody,
  //     );
  //
  //     final responseData = jsonDecode(response.body);
  //
  //     if (response.statusCode == 201) {
  //       return {
  //         'success': true,
  //         'message': responseData['message'] ?? 'Servicii adăugate cu succes!',
  //         'created_count': responseData['created_count'] ?? 0,
  //         'data': responseData['data'] ?? [],
  //       };
  //     } else {
  //       return {
  //         'success': false,
  //         'error': responseData['error'] ?? 'Eroare necunoscută',
  //         'duplicate_errors': responseData['duplicate_errors'] ?? [],
  //       };
  //     }
  //   } catch (e) {
  //     return {'success': false, 'error': 'Eroare de rețea: $e'};
  //   }
  // }


  Future<Map<String, dynamic>> addSupplierBrandService({
    required String city,
    required String sector,
    required double latitude,
    required double longitude,
    required List<Map<String, dynamic>> payloads,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "total_payloads": payloads.length,
        "shared_location": {
          "city": city,
          "sector": sector,
          "latitude": latitude,
          "longitude": longitude,
          "is_real_location": true,
        },
        "payloads": payloads,
        "metadata": {
          "price": 0.0,
          "created_at": DateTime.now().toIso8601String(),
        }
      };

      final response = await _apiService.authenticatedPost(
        '${ApiService.baseUrl}/supplier-brand-services/', // Note the /bulk/ endpoint
        requestBody,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Servicii adăugate cu succes!',
          'created_count': responseData['created_count'] ?? 0,
          'data': responseData['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Eroare necunoscută',
          'duplicate_errors': responseData['duplicate_errors'] ?? [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Eroare de rețea: $e',
      };
    }
  }

}
