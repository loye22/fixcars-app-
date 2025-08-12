import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';
import 'AddressService.dart';


class MecanicAutoService {
  final ApiService _apiService = ApiService();
  final AddressService _addressService = AddressService();

  Future<List<Map<String, dynamic>>> fetchMecanicAutos() async {
    try {
      final coords = await _addressService.getCurrentCoordinates();
      final double lat = coords['latitude']!;
      final double lng = coords['longitude']!;

      final String url = '${ApiService.baseUrl}/mecanic-auto-services/?lat=$lat&lng=$lng';

      final http.Response response = await _apiService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load mechanic auto services: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching mechanic auto services: $e');
    }
  }
}