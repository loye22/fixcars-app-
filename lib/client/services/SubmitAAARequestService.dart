
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../shared/services/api_service.dart';

class SubmitAAARequestService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> submitRequest({
    required String supplierId,
    required String reason,
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'error': 'Location services are disabled. Please enable them.',
        };
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'success': false,
            'error': 'Location permissions are denied.',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'success': false,
          'error': 'Location permissions are permanently denied.',
        };
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url = '${ApiService.baseUrl}/requests/create/';
      final body = {
        'supplier': supplierId,
        'longitude': position.longitude,
        'latitude': position.latitude,
        'reason': reason,
      };

      final response = await _apiService.authenticatedPost(url, body);

      final data = jsonDecode(response.body);



      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Request created successfully.',
        };
      } else if (response.statusCode == 400 && data['code'] == 'duplicate_request') {
        return {
          'success': false,
          'error': data['error'] ?? 'You have already made a request to this supplier.',
          'code': 'duplicate_request',
        };
      }

      return {
        'success': false,
        'error': '${data['error'] ?? data['message'] ?? 'Unknown server error'}. Response: ',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching location or network error: $e',
      };
    }
  }
}