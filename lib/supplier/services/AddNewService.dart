import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fixcars/shared/services/api_service.dart';

class AddNewService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> addSupplierBrandService({
    required String brandId,
    required List<String> serviceIds,
    required String city,
    required String sector,
    required double latitude,
    required double longitude,
    required double price,
  }) async {
    try {


      final Map<String, dynamic> requestBody = {
        'brand_id': brandId,
        'service_ids': serviceIds,
        'city': city,
        'sector': sector,
        'latitude': latitude,
        'longitude': longitude,
        'price': price, // Send as number, not string
      };

      // Remove price if it's 0 (optional field)
      if (price == 0.0) {
        requestBody.remove('price');
      }

      // Use the authenticatedPost method from ApiService
      final response = await _apiService.authenticatedPost(
        '${ApiService.baseUrl}/supplier-brand-services/',
        requestBody,
      );



      final responseData = jsonDecode(response.body);



      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Serviciu adăugat cu succes!',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Eroare necunoscută',
          'details': responseData['details'],
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