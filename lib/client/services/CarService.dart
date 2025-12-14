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
}