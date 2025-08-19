//DetailingScreen

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/services/api_service.dart';
import '../services/AddressService.dart';
import '../services/MecanicAutoService.dart';
import '../widgets/BrandListWidget.dart';
import '../widgets/BusinessCardWidget.dart';
import '../widgets/ServiceSelectionWidget.dart';

class DetailingScreen extends StatefulWidget {
  @override
  _DetailingScreenState createState() => _DetailingScreenState();
}

class _DetailingScreenState extends State<DetailingScreen> {
  String _address = "Se încarcă adresa...";
  List<Map<String, dynamic>> _mechanicServices = [];
  List<String> _selectedServices = [];
  bool _isLoading = true;
  String? _error;

  // Location state
  double _currentLat = 45.6486; // Default to Romania center
  double _currentLng = 25.6061;
  bool _isLocationLoading = false;
  bool _isFetchingData = false; // Prevent multiple simultaneous API calls

  // Track previous values to detect changes
  double _previousLat = 45.6486;
  double _previousLng = 25.6061;
  String? _previousBrandName;
  List<String> _previousServices = [];

  final AddressService _addressService = AddressService();
  final MecanicAutoService _DetailingService = MecanicAutoService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLocationLoading = true;
      });

      // Get current location
      final coords = await _addressService.getCurrentCoordinates();
      final address = await _addressService.getCurrentAddress();

      setState(() {
        _currentLat = coords['latitude']!;
        _currentLng = coords['longitude']!;
        _address = address;
        _isLocationLoading = false;
      });

      // Fetch initial data
      await _fetchData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLocationLoading = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    // Prevent multiple simultaneous API calls
    if (_isFetchingData) {
      print('Skipping API call - already fetching data');
      return;
    }

    // Check if any filter has changed
    bool hasLocationChanged = _currentLat != _previousLat || _currentLng != _previousLng;
    bool hasServicesChanged = !listEquals(_selectedServices, _previousServices);
    // print('Change detection:');
    // print('- Location changed: $hasLocationChanged (current: $_currentLat,$_currentLng, previous: $_previousLat,$_previousLng)');
    // print('- Brand changed: $hasBrandChanged (current: ${_selectedBrand?['brand_name']}, previous: $_previousBrandName)');
    // print('- Services changed: $hasServicesChanged (current: $_selectedServices, previous: $_previousServices)');

    // Only fetch if something changed or this is the initial load
    if (!hasLocationChanged  && !hasServicesChanged && _mechanicServices.isNotEmpty) {
      print('No changes detected, skipping API call');
      return;
    }

    //print('Fetching data with filters: brand=${_selectedBrand?['brand_name']}, services=$_selectedServices, lat=$_currentLat, lng=$_currentLng');

    try {
      setState(() {
        _isFetchingData = true;
        _isLoading = true;
        _error = null;
      });

      // Fetch mechanic services with current filters
      List<Map<String, dynamic>> services = await _DetailingService.fetchMecanicAutos(
        category: AutoService.detailing_auto_profesionist,
        lat: _currentLat,
        lng: _currentLng,
        tags: _selectedServices.isNotEmpty ? _selectedServices : null,
      );

      // print('API returned ${services.length} services');

      setState(() {
        _mechanicServices = services;
        _isLoading = false;
        _isFetchingData = false;

        // Update previous values after successful fetch
        _previousLat = _currentLat;
        _previousLng = _currentLng;
        _previousServices = List.from(_selectedServices);
        //
        // print('Updated previous values:');
        // print('- Previous brand: $_previousBrandName');
        // print('- Previous services: $_previousServices');
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isFetchingData = false;
      });
    }
  }


  void _onServicesSelected(List<String> selectedServices) {
    // print('MecanicScreen: Services selected: $selectedServices');
    // print('MecanicScreen: Previous services: $_selectedServices');
    setState(() {
      _selectedServices = selectedServices;
    });
    // print('MecanicScreen: After setState - selected services: $_selectedServices');

    _fetchData(); // Trigger API call with new service filters
  }

  void _onLocationChanged(double lat, double lng, String newAddress) {
    setState(() {
      _currentLat = lat;
      _currentLng = lng;
      _address = newAddress;
    });
    _fetchData(); // Trigger API call with new location
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerWidget(
        currentLat: _currentLat,
        currentLng: _currentLng,
        onLocationSelected: _onLocationChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showLocationPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/location.png', width: 30),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  _address,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            ],
          ),
        ),
        backgroundColor: Color(0xFF4B5563),
        automaticallyImplyLeading: false, // default is true
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _isLocationLoading || _isLoading
            ? Center(
          child: LoadingAnimationWidget.threeArchedCircle(
            color: Color(0xFF4B5563),
            size: 50,
          ),
        )
            : _error != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchData,
                child: Text('Încearcă din nou'),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceSelectionWidget(
                key: ValueKey('service_selector'),
                onServicesSelected: _onServicesSelected,
                initialSelectedServices: _selectedServices,
                AutoServicetype: 'detailing_auto_profesionist',

              ),
              SizedBox(height: 16),
              MechanicServicesList(
                key: ValueKey('mechanic_services_${_mechanicServices.length}'),
                services: _mechanicServices,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Location Picker Widget
class LocationPickerWidget extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final Function(double lat, double lng, String address) onLocationSelected;

  const LocationPickerWidget({
    Key? key,
    required this.currentLat,
    required this.currentLng,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _LocationPickerWidgetState createState() => _LocationPickerWidgetState();
}
class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  bool _isLoading = false;
  String _selectedAddress = "";

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = LatLng(widget.currentLat, widget.currentLng);
    _getAddressFromLocation();
  }

  Future<void> _getAddressFromLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final addressService = AddressService();
      final address = await addressService.getAddressFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      setState(() {
        _selectedAddress = address;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _selectedAddress = "Adresa nu a putut fi găsită";
        _isLoading = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _getAddressFromLocation();
  }

  void _confirmLocation() {
    widget.onLocationSelected(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
      _selectedAddress,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF4B5563)),
                SizedBox(width: 8),
                Text(
                  'Selectează locația',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Anulează'),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 13,
                onTap: _onMapTap,
                maxZoom: 18,
                minZoom: 5,
                // Restrict to Romania bounds
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                    LatLng(43.5, 20.0), // Southwest Romania
                    LatLng(48.5, 30.0), // Northeast Romania
                  ),
                ),
              ),
              children: [
                ApiService.lightTileLayer,
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: Color(0xFF4B5563),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Selected location info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Locația selectată:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                _isLoading
                    ? Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Se încarcă adresa...'),
                  ],
                )
                    : Text(
                  _selectedAddress,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4B5563),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Confirmă locația',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




/// Displays results fetched from the API.
/// Separated into its own widget to avoid rebuilding the upper section
/// and to keep the top content visible while this part is loading.
class MechanicServicesList extends StatelessWidget {
  final List<Map<String, dynamic>> services;

  const MechanicServicesList({
    Key? key,
    required this.services,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/noresults.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 16),
            Text(
              'Nu s-au găsit rezultate, te rugăm să ajustezi filtrul.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: services.map((service) {
        return BusinessCardWidget(
          businessName: service['supplier_name'] ?? 'Unknown',
          rating: (service['review_score'] as num?)?.toDouble() ?? 0.0,
          reviewCount: service['total_reviews'] ?? 0,
          distance: "${service['distance_km'] ?? 0.0} km",
          location: service['supplier_address'] ?? 'Unknown',
          isAvailable: service['is_open'] ?? false,
          profileUrl: service['supplier_photo'] ?? '',
          servicesUrl: service['photo_url'] ?? '',
          carBrandUrl: service['brand_photo'] ?? '',
          supplierID: service['supplier_id'] ?? '',
        );
      }).toList(),
    );
  }
}




