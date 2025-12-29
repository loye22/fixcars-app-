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
  // --- PREMIUM DARK COLOR PALETTE ---
  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _darkCard = Color(0xFF141414);
  static const Color _accentSilver = Color(0xFFB0B0B0);
  static const Color _primaryText = Color(0xFFF0F0F0);
  static const Color _secondaryText = Color(0xFFAAAAAA);
  static const Color _navBarColor = Color(0xFF1A1A1A);

  String _address = "Se încarcă adresa...";
  List<Map<String, dynamic>> _services = [];
  List<String> _selectedServices = [];
  bool _isLoading = true;
  String? _error;

  // Location
  double _currentLat = 45.6486;
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

  // --- LOGIC (UNTOUCHED) ---
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
    final locationChanged = _currentLat != _previousLat || _currentLng != _previousLng;
    final servicesChanged = !listEquals(_selectedServices, _previousServices);
    if (!locationChanged && !servicesChanged && _services.isNotEmpty) return;

    try {
      setState(() {
        _isFetchingData = true;
        _isLoading = true;
        _error = null;
      });

      final List<Map<String, dynamic>> data = await _service.fetchMecanicAutos(
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

  // --- UPDATED UI DESIGN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _navBarColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _primaryText, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: _showLocationPicker,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("LOCAȚIE CURENTĂ", style: TextStyle(fontSize: 10, color: _accentSilver, letterSpacing: 1.2)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _address,
                      style: const TextStyle(fontSize: 14, color: _primaryText, fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: _accentSilver, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLocationLoading || _isLoading
          ? Center(child: LoadingAnimationWidget.newtonCradle(color: _accentSilver, size: 60))
          : _error != null
          ? _buildErrorWidget()
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader("Servicii Spălătorie"),
          ServiceSelectionWidget(
            key: const ValueKey('service_selector_spalatorie'),
            onServicesSelected: _onServicesSelected,
            initialSelectedServices: _selectedServices,
            AutoServicetype: 'spalatorie_auto',
          ),
          const SizedBox(height: 24),
          _buildHeader("Spălătorii Auto"),
          MechanicServicesList(
            key: ValueKey('spalatorie_services_${_services.length}'),
            services: _services,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: _accentSilver, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkCard),
            onPressed: _fetchData,
            child: const Text('Încearcă din nou', style: TextStyle(color: _primaryText)),
          ),
        ],
      ),
    );
  }
}

// --- UPDATED LOCATION PICKER MODAL ---
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

  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _navBarColor = Color(0xFF1A1A1A);

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
      final address = await AddressService().getAddressFromCoordinates(
          _selectedLocation.latitude, _selectedLocation.longitude);
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
    widget.onLocationSelected(_selectedLocation.latitude, _selectedLocation.longitude, _selectedAddress);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("Selectează locația pe hartă", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                cameraConstraint: CameraConstraint.unconstrained(),
                initialCenter: _selectedLocation,
                initialZoom: 14,
                onTap: _onMapTap,
                // cameraConstraint: CameraConstraint.contain(
                //   bounds: LatLngBounds(LatLng(43.5, 20.0), LatLng(48.5, 30.0)),
                // ),
              ),
              children: [
                ApiService.lightTileLayer,
                MarkerLayer(markers: [
                  Marker(
                      point: _selectedLocation,
                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40)
                  ),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: _navBarColor,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_selectedAddress, style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _confirmLocation,
                      child: const Text("CONFIRMĂ LOCAȚIA", style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// --- UPDATED RESULTS LIST ---
class MechanicServicesList extends StatelessWidget {
  final List<Map<String, dynamic>> services;

  const MechanicServicesList({Key? key, required this.services}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: const Column(
          children: [
            Icon(Icons.local_car_wash_outlined, color: Color(0xFF141414), size: 80),
            SizedBox(height: 16),
            Text("Nicio spălătorie găsită în zonă.", style: TextStyle(color: Color(0xFFAAAAAA))),
          ],
        ),
      );
    }

    return Column(
      children: services.map((s) {
        final String plan = s['subscription_plan']?.toString().toLowerCase() ?? "";
        SupplierTier currentTier;
        if (plan == 'gold') {
          currentTier = SupplierTier.gold;
        } else if (plan == 'silver') {
          currentTier = SupplierTier.silver;
        } else {
          currentTier = SupplierTier.bronze; // Default for "bronze" or unknown
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: BusinessCardWidget(
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
            tier: currentTier,
          ),
        );
      }).toList(),
    );
  }
}