import 'dart:convert';
import 'package:http/http.dart' as http;

// Assuming ApiService is in this shared path, adjust if necessary
import '../../shared/services/api_service.dart';


enum ObligationType {
  ITP,
  RCA,
  CASCO,
  ROVINIETA,
  AUTO_TAX,
  OIL_CHANGE,
  AIR_FILTER,
  CABIN_FILTER,
  BRAKE_CHECK,
  COOLANT,
  BATTERY,
  TIRES,
  WIPERS,
  FIRE_EXTINGUISHER,
  FIRST_AID_KIT
}

enum ReminderType {
  LEGAL,
  MECHANICAL,
  SAFETY,
  FINANCIAL,
  SEASONAL,
  OTHER
}

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

        print("============================= decodedBody =======================");
        print(decodedBody);

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
  }) async
  {
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





  /// Handles the update of an existing car via a PUT request to the API.
  /// Endpoint: ${ApiService.baseUrl}/cars/<car_brand_id>/
  Future<Map<String, dynamic>> updateCar({
    required String carId, // The ID of the car to update
    required String brandId,
    required String model,
    required int year,
    required int currentKm,
    required String lastKmUpdatedAt,
    String? licensePlate,
    String? vin,
  }) async
  {
    try {
      // Use carId in the endpoint path as per API specification: PUT /api/cars/<car_id>/
      final String endpoint = '${ApiService.baseUrl}/cars/$carId/';

      // Build request body
      final Map<String, dynamic> body = {
        'brand_id': brandId,
        'model': model.trim(),
        'year': year,
        'current_km': currentKm,
        'last_km_updated_at': lastKmUpdatedAt,
      };

      // Only add optional fields if provided
      if (licensePlate != null) {
        body['license_plate'] = licensePlate.trim().toUpperCase();
      }

      if (vin != null) {
        body['vin'] = vin.trim().toUpperCase();
      }

      // Use authenticatedPut method
      final http.Response response = await _apiService.authenticatedPut(endpoint, body);

      // print("response+=========================================");
      // print(response.body);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Success case (usually 200 OK)
      if (response.statusCode == 200 && responseData['success'] == true) {
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



  /// Fetches the current car details and available brands for initialization.
  /// Endpoint: ${ApiService.baseUrl}/init-car-details-update/
  Future<Map<String, dynamic>> fetchCurrentCarDetails() async {
    try {
      final String url = '${ApiService.baseUrl}/init-car-details-update/';

      // Perform an authenticated GET request
      final http.Response response = await _apiService.authenticatedGet(url);

      // Decode the JSON response body
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Return the 'data' object which contains 'current_car' and 'available_brands'
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        // Handle error cases or unexpected status codes
        String errorMessage = responseData['error'] ??
            responseData['message'] ??
            'Eroare la încărcarea detaliilor (cod: ${response.statusCode})';

        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      // Catch any network, timeout, or decoding errors
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



  /// Adds a new obligation to the current car.
  /// POST /api/add-car-obligation/
  Future<Map<String, dynamic>> addCarObligation({
    required ObligationType obligationType,
    required ReminderType reminderType,
    required DateTime dueDate,
    String? documentUrl,
    String? note,
  }) async
  {
    try
    {
      final String url = '${ApiService.baseUrl}/add-car-obligation/';

      // Prepare the request body
      final Map<String, dynamic> body = {
        'obligation_type': obligationType.name, // Converts enum to String (e.g., "ITP")
        'reminder_type': reminderType.name,     // Converts enum to String (e.g., "LEGAL")
        'due_date': dueDate.toIso8601String().split('T')[0], // Formats as YYYY-MM-DD
        'doc_url': documentUrl,
        'note': note,
      };

      // Perform the authenticated POST request
      final http.Response response = await _apiService.authenticatedPost(
        url,
      body,
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 201 || responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Obligation added successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? responseData['errors']?.toString() ?? 'Error adding obligation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }


  /// Deletes a specific car obligation.
  /// DELETE /api/cars/<car_id>/obligations/<obligation_id>/
  Future<Map<String, dynamic>> deleteCarObligation({
    required String carId,
    required String obligationId,
  }) async {
    try {
      final String url = '${ApiService.baseUrl}/cars/$carId/obligations/$obligationId/';

      // Perform the authenticated DELETE request
      final http.Response response = await _apiService.authenticatedDelete(url);

      // Decode the response body
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Handle Success: { "success": true, "message": "Obligation deleted successfully." }
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'],
        };
      }

      // Handle Failure: { "success": false, "error": "Obligation not found for this car." }
      return {
        'success': false,
        'error': responseData['error'] ?? 'Eroare la ștergerea obligației.',
      };
    } catch (e) {
      // Handle connection or parsing errors
      String errorMsg = e.toString().contains('SocketException')
          ? 'Fără conexiune la internet.'
          : 'Eroare neașteptată: $e';

      return {
        'success': false,
        'error': errorMsg,
      };
    }
  }

  /// Updates an existing car obligation by ID.
  /// POST /api/updatecarobligationbyid
  Future<Map<String, dynamic>> updateCarObligation({
    required String obligationId,
    required ObligationType obligationType,
    required ReminderType reminderType,
    required DateTime dueDate,
    String? documentUrl,
    String? note,
  }) async {
    try {
      final String url = '${ApiService.baseUrl}/updatecarobligationbyid';

      // Prepare the request body according to API requirements
      final Map<String, dynamic> body = {
        'obligation_id': obligationId,
        'obligation_type': obligationType.name, // e.g., "RCA"
        'reminder_type': reminderType.name,     // e.g., "LEGAL"
        'due_date': dueDate.toIso8601String().split('T')[0], // YYYY-MM-DD
        'doc_url': documentUrl,
        'note': note,
      };

      // Perform the authenticated POST request
      final http.Response response = await _apiService.authenticatedPost(
        url,
        body,
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      // Handle Success Case
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      }

      // Handle Error Case from API
      return {
        'success': false,
        'error': responseData['error'] ?? 'Eroare la actualizarea obligației.',
      };
    } catch (e) {
      // Handle connection or parsing errors
      String errorMsg = e.toString().contains('SocketException')
          ? 'Fără conexiune la internet.'
          : 'Eroare neașteptată: $e';

      return {
        'success': false,
        'error': errorMsg,
      };
    }
  }


  /// Fetches suggested businesses (golden suggestions) for a specific obligation type.
  ///
  /// API Link: http://192.168.1.129:8000/api/suggest-businesses-for-obligation/?obligation_type=OIL_CHANGE
  Future<Map<String, dynamic>> fetchGoldenSuggestions(ObligationType obligationType) async {
    try {
      // Constructs the URL using the enum name (e.g., "OIL_CHANGE")
      final String url = '${ApiService.baseUrl}/suggest-businesses-for-obligation/?obligation_type=${obligationType.name}';

      // Performs the authenticated GET request
      final http.Response response = await _apiService.authenticatedGet(url);

      final Map<String, dynamic> responseData = json.decode(response.body);

      // Handle Success Case based on the provided JSON structure
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'], // List of businesses
          'count': responseData['count'], // The number of results found
          'obligation_type': responseData['obligation_type'], // The requested type (e.g., OIL_CHANGE)
          'service_category': responseData['service_category'], // The category (e.g., mecanic_auto)
        };
      }

      // Handle Error Case (e.g., Invalid obligation_type)
      return {
        'success': false,
        'error': responseData['error'] ?? 'Eroare la încărcarea sugestiilor.',
      };
    } catch (e) {
      // Standard error handling used in your CarService
      String errorMsg = e.toString().contains('SocketException')
          ? 'Fără conexiune la internet.'
          : 'Eroare neașteptată: $e';

      return {
        'success': false,
        'error': errorMsg,
      };
    }
  }

}