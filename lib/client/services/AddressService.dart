import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddressService {
  // Singleton pattern (optional)
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  // Get city and neighborhood as a string
  Future<String> getCurrentAddress() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return "Location services are disabled.";
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return "Location permissions are denied.";
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return "Location permissions are permanently denied.";
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("position $position") ;

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );


      // Extract city and neighborhood from the first placemark
      Placemark placemark = placemarks[0];
      String city = placemark.locality ?? "Unknown City";
      String neighborhood = placemark.subLocality ?? "Unknown Neighborhood";
      return "$neighborhood, $city";
    } catch (e) {
      return "Error fetching address: $e";
    }
  }

  // Get latitude and longitude
  Future<Map<String, double>> getCurrentCoordinates() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Return latitude and longitude as a map
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      throw Exception("Error fetching coordinates: $e");
    }
  }


  // Get address from coordinates using geocoding package
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // Convert coordinates to address using geocoding package
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String city = placemark.locality ?? "Unknown City";
        String neighborhood = placemark.subLocality ?? "Unknown Neighborhood";
        return "$neighborhood, $city";
      } else {
        return "Adresa nu a putut fi găsită";
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return "Adresa nu a putut fi găsită";
    }
  }
}
