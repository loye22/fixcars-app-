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
      // but no change here except formatting
      final coords = (lat != null && lng != null)
          ? {'latitude': lat, 'longitude': lng}
          : await _addressService.getCurrentCoordinates();
      final double finalLat = coords['latitude']!;
      final double finalLng = coords['longitude']!;

      // This is cleaner and works with modern Dart enums
      final Map<String, String> baseParams = {
        'category': category.name,
        'lat': finalLat.toString(),
        'lng': finalLng.toString(),
      };

      if (carBrand != null && carBrand.isNotEmpty) {
        baseParams['car_brand'] = carBrand;
      }

      // This allows us to later append multiple tags without them being merged into one key
      final uri = Uri.parse('${ApiService.baseUrl}/services/')
          .replace(queryParameters: baseParams);
      String query = uri.query;

      // Instead of joining with commas, this makes: &tags=foo&tags=bar
      if (tags != null && tags.isNotEmpty) {
        for (final tag in tags) {
          query += '&tags=${Uri.encodeQueryComponent(tag)}'; // ✅ Encode to handle spaces & special characters
        }
      }

      final finalUrl = '${uri.toString().split('?').first}?$query';



      // API request
      final http.Response response = await _apiService.authenticatedGet(finalUrl);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data') && responseData['data'] is List) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        } else {
          throw Exception('Unexpected response format: missing data array');
        }
      } else {
        throw Exception(
          'Failed to load mechanic auto services: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stack) {

      print('Error fetching mechanic auto services: $e\n$stack');
      throw Exception('Error fetching mechanic auto services: $e');
    }
  }
}