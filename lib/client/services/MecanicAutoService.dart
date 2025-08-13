import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';
import 'AddressService.dart';

enum AutoService {
  mecanic_auto,
  autocolant_folie_auto,
  detailing_auto_profesionist,
  itp,
  tapiterie_auto,
  vulcanizare_auto_mobila,
  tractari_auto,
  tuning_auto,
}

class MecanicAutoService {
  final ApiService _apiService = ApiService();
  final AddressService _addressService = AddressService();

  Future<List<Map<String, dynamic>>> fetchMecanicAutos({
    required AutoService category,
    String? carBrand,
    List<String>? tags,
    double? lat,
    double? lng,
  }) async {
    try {
      // Use provided lat/lng if available, otherwise get current coordinates
      final coords = (lat != null && lng != null)
          ? {'latitude': lat, 'longitude': lng}
          : await _addressService.getCurrentCoordinates();
      final double finalLat = coords['latitude']!;
      final double finalLng = coords['longitude']!;

      // Build query parameters
      final Map<String, String> queryParams = {
        'category': category.toString().split('.').last,
        'lat': finalLat.toString(),
        'lng': finalLng.toString(),
      };

      // Add optional parameters if provided
      if (carBrand != null && carBrand.isNotEmpty) {
        queryParams['car_brand'] = carBrand;
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      // Construct URL with query parameters
      final String url = Uri.parse('${ApiService.baseUrl}/services/')
          .replace(queryParameters: queryParams)
          .toString();

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if the response has the expected structure
        if (responseData.containsKey('data') && responseData['data'] is List) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        } else {
          throw Exception('Unexpected response format: missing data array');
        }
      } else {
        throw Exception('Failed to load mechanic auto services: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching mechanic auto services: $e');
      throw Exception('Error fetching mechanic auto services: $e');
    }
  }
}