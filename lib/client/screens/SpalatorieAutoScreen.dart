import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/services/api_service.dart';
import '../services/AddressService.dart';
import '../services/MecanicAutoService.dart';
import '../widgets/BusinessCardWidget.dart';
import '../widgets/ServiceSelectionWidget.dart';



class SpalatorieAutoScreen extends StatefulWidget {
  @override
  _SpalatorieAutoScreenState createState() => _SpalatorieAutoScreenState();
}

class _SpalatorieAutoScreenState extends State<SpalatorieAutoScreen> {
  String _address = "Se încarcă adresa...";
  List<Map<String, dynamic>> _services = [];
  List<String> _selectedServices = [];
  bool _isLoading = true;
  String? _error;

  // Location
  double _currentLat = 45.6486; // Romania center
  double _currentLng = 25.6061;
  bool _isLocationLoading = false;
  bool _isFetchingData = false;

  // Change detection
  double _previousLat = 45.6486;
  double _previousLng = 25.6061;
  List<String> _previousServices = [];

  final AddressService _addressService = AddressService();
  final MecanicAutoService _service = MecanicAutoService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() => _isLocationLoading = true);

      final coords = await _addressService.getCurrentCoordinates();
      final address = await _addressService.getCurrentAddress();

      setState(() {
        _currentLat = coords['latitude']!;
        _currentLng = coords['longitude']!;
        _address = address;
        _isLocationLoading = false;
      });

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
    if (_isFetchingData) return;

    final locationChanged =
        _currentLat != _previousLat || _currentLng != _previousLng;
    final servicesChanged =
    !listEquals(_selectedServices, _previousServices);

    if (!locationChanged && !servicesChanged && _services.isNotEmpty) return;

    try {
      setState(() {
        _isFetchingData = true;
        _isLoading = true;
        _error = null;
      });

      final List<Map<String, dynamic>> data =
      await _service.fetchMecanicAutos(
        category: AutoService.spalatorie_auto,
        lat: _currentLat,
        lng: _currentLng,
        tags: _selectedServices.isNotEmpty ? _selectedServices : null,
      );

      setState(() {
        _services = data;
        _isLoading = false;
        _isFetchingData = false;

        _previousLat = _currentLat;
        _previousLng = _currentLng;
        _previousServices = List.from(_selectedServices);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isFetchingData = false;
      });
    }
  }

  void _onServicesSelected(List<String> selected) {
    setState(() => _selectedServices = selected);
    _fetchData();
  }

  void _onLocationChanged(double lat, double lng, String address) {
    setState(() {
      _currentLat = lat;
      _currentLng = lng;
      _address = address;
    });
    _fetchData();
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerWidget(
        currentLat: _currentLat,
        currentLng: _currentLng,
        onLocationSelected: _onLocationChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back , color: Colors.white,), // Use the specific Cupertino icon
          onPressed: () {
            // This is the function that makes it go back to the previous screen
            Navigator.of(context).pop();
          },
        ),
        title: GestureDetector(
          onTap: _showLocationPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/location.png', width: 30),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _address,
                  style: const TextStyle(
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
        backgroundColor: const Color(0xFF4B5563),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLocationLoading || _isLoading
            ? Center(
          child: LoadingAnimationWidget.threeArchedCircle(
            color: const Color(0xFF4B5563),
            size: 50,
          ),
        )
            : _error != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _fetchData,
                  child: const Text('Încearcă din nou')),
            ],
          ),
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceSelectionWidget(
                key: const ValueKey('service_selector_spalatorie'),
                onServicesSelected: _onServicesSelected,
                initialSelectedServices: _selectedServices,
                AutoServicetype: 'spalatorie_auto',
              ),
              const SizedBox(height: 16),
              MechanicServicesList(
                key: ValueKey('spalatorie_services_${_services.length}'),
                services: _services,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Reusable Location Picker
// ──────────────────────────────────────────────────────────────
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
      setState(() => _isLoading = true);
      final address = await AddressService()
          .getAddressFromCoordinates(_selectedLocation.latitude,
          _selectedLocation.longitude);
      setState(() {
        _selectedAddress = address;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _selectedAddress = "Adresa nu a putut fi găsită";
        _isLoading = false;
      });
    }
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() => _selectedLocation = point);
    _getAddressFromLocation();
  }

  void _confirmLocation() {
    widget.onLocationSelected(
        _selectedLocation.latitude, _selectedLocation.longitude,
        _selectedAddress);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF4B5563)),
                const SizedBox(width: 8),
                const Text('Selectează locația',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Anulează')),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 13,
                onTap: _onMapTap,
                maxZoom: 18,
                minZoom: 5,
                cameraConstraint: CameraConstraint.contain(
                  bounds:  LatLngBounds(
                    LatLng(43.5, 20.0),
                    LatLng(48.5, 30.0),
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
                      child: const Icon(Icons.location_on,
                          color: Color(0xFF4B5563), size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Locația selectată:',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _isLoading
                    ? const Row(
                  children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Se încarcă adresa...'),
                  ],
                )
                    : Text(_selectedAddress, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B5563),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Confirmă locația',
                        style: TextStyle(color: Colors.white)),
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

// ──────────────────────────────────────────────────────────────
// Results List
// ──────────────────────────────────────────────────────────────
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
            Image.asset('assets/noresults.png', width: 150, height: 150),
            const SizedBox(height: 16),
            const Text(
              'Nu s-au găsit rezultate, te rugăm să ajustezi filtrul.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: services.map((s) {
        return BusinessCardWidget(
          businessName: s['supplier_name'] ?? 'Necunoscut',
          rating: (s['review_score'] as num?)?.toDouble() ?? 0.0,
          reviewCount: s['total_reviews'] ?? 0,
          distance: "${s['distance_km'] ?? 999.0} km",
          location: s['supplier_address'] ?? 'Necunoscut',
          isAvailable: s['is_open'] ?? false,
          profileUrl: s['supplier_photo'] ?? '',
          servicesUrl: s['photo_url'] ?? '',
          carBrandUrl: s['brand_photo'] ?? '',
          supplierID: s['supplier_id'] ?? '',
        );
      }).toList(),
    );
  }
}