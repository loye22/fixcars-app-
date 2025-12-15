import 'dart:convert';
import 'package:http/http.dart' as http;

// Assuming ApiService is in this shared path, adjust if necessary
import '../../shared/services/api_service.dart';

class CarService {
  final ApiService _apiService = ApiService();

  /// Fetches a list of cars from the API endpoint /api/cars/
  ///
  /// The expected API response format is:
  /// { "success": true, "data": [ { ...car_data... }, { ...car_data... } ] }
  Future<List<Map<String, dynamic>>> fetchCars() async {
    try {
      // Construct the full API URL for cars
      // Note: The prompt specified the link as /api/cars/, which
      // typically means the full path is ${ApiService.baseUrl}/api/cars/
      // Adjusting to match the general structure if needed, but using '/cars'
      // based on the BrandService structure for consistency.
      final String url = '${ApiService.baseUrl}/cars';

      // Perform an authenticated GET request using the existing ApiService
      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        // Decode the JSON response body
        final Map<String, dynamic> decodedBody = json.decode(response.body);

        // Check if the body contains a 'data' key which is a list
        if (decodedBody.containsKey('data') && decodedBody['data'] is List) {
          final List<dynamic> data = decodedBody['data'];
          // Cast the list of dynamic maps to List<Map<String, dynamic>>
          return data.cast<Map<String, dynamic>>();
        } else {
          // Handle case where 'data' key is missing or not a list,
          // which is an unexpected but successful response structure.
          return [];
        }
      } else {
        // Throw an exception for non-200 status codes (e.g., 404, 500)
        throw Exception('Failed to load cars: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Catch any network or decoding errors
      throw Exception('Error fetching cars: $e');
    }
  }



  /// Handles the creation of a new car via a POST request to the API.
  /// Endpoint: ${ApiService.baseUrl}/cars/create/
  Future<Map<String, dynamic>> addCar({
    required String brandId,
    required String model,
    required int year,
    required int currentKm,
    required String lastKmUpdatedAt, // MUST be provided
    String? licensePlate,
    String? vin,
  }) async {
    try {
      final String endpoint = '${ApiService.baseUrl}/cars/create/';

      // Build request body
      final Map<String, dynamic> body = {
        'brand_id': brandId,
        'model': model.trim(),
        'year': year,
        'current_km': currentKm,
        'last_km_updated_at': lastKmUpdatedAt, // Required, passed exactly as given
      };

      // Only add license_plate if explicitly provided (even if empty)
      if (licensePlate != null) {
        body['license_plate'] = licensePlate.trim().toUpperCase();
      }

      // Only add vin if explicitly provided (even if empty)
      if (vin != null) {
        body['vin'] = vin.trim().toUpperCase();
      }

      final http.Response response = await _apiService.authenticatedPost(endpoint, body);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Success case (usually 201 Created or 200 OK)
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      }

      // Validation or field-specific errors from backend
      if (responseData.containsKey('errors') && responseData['errors'] is Map) {
        return {
          'success': false,
          'error': 'Unele câmpuri conțin erori.',
          'fieldErrors': Map<String, dynamic>.from(responseData['errors']),
        };
      }

      // Generic error message
      String errorMessage = responseData['error'] ??
          responseData['message'] ??
          'Eroare necunoscută de la server (cod: ${response.statusCode})';

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      String errorMsg;
      if (e.toString().contains('SocketException')) {
        errorMsg = 'Fără conexiune la internet.';
      } else if (e.toString().contains('Timeout')) {
        errorMsg = 'Cererea a expirat. Încearcă din nou.';
      } else {
        errorMsg = 'Eroare neașteptată: $e';
      }

      return {
        'success': false,
        'error': errorMsg,
      };
    }
  }





}