import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/AddressService.dart';
import '../services/MecanicAutoService.dart';
import '../widgets/BrandListWidget.dart';
import '../widgets/BusinessCardWidget.dart';
import '../widgets/ServiceSelectionWidget.dart';

class TuningScreen extends StatefulWidget {
  @override
  _TuningScreenState createState() => _TuningScreenState();
}

class _TuningScreenState extends State<TuningScreen> {
  // --- PREMIUM DARK COLOR PALETTE ---
  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _darkCard = Color(0xFF141414);
  static const Color _accentSilver = Color(0xFFB0B0B0);
  static const Color _primaryText = Color(0xFFF0F0F0);
  static const Color _secondaryText = Color(0xFFAAAAAA);
  static const Color _navBarColor = Color(0xFF1A1A1A);

  String _address = "Se încarcă adresa...";
  List<Map<String, dynamic>> _mechanicServices = [];
  List<String> _selectedServices = [];
  Map<String, dynamic>? _selectedBrand;
  bool _isLoading = true;
  String? _error;

  // Location state
  double _currentLat = 45.6486;
  double _currentLng = 25.6061;
  bool _isLocationLoading = false;
  bool _isFetchingData = false;

  // Track previous values for logic
  double _previousLat = 45.6486;
  double _previousLng = 25.6061;
  String? _previousBrandName;
  List<String> _previousServices = [];

  final AddressService _addressService = AddressService();
  final MecanicAutoService _tuningService = MecanicAutoService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // --- LOGIC (REMAINED THE SAME) ---
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
    bool hasLocationChanged = _currentLat != _previousLat || _currentLng != _previousLng;
    bool hasBrandChanged = _selectedBrand?['brand_name'] != _previousBrandName;
    bool hasServicesChanged = !listEquals(_selectedServices, _previousServices);

    if (!hasLocationChanged && !hasBrandChanged && !hasServicesChanged && _mechanicServices.isNotEmpty) return;

    try {
      setState(() {
        _isFetchingData = true;
        _isLoading = true;
        _error = null;
      });

      List<Map<String, dynamic>> services = await _tuningService.fetchMecanicAutos(
        category: AutoService.tuning_auto,
        lat: _currentLat,
        lng: _currentLng,
        carBrand: _selectedBrand?['brand_name'],
        tags: _selectedServices.isNotEmpty ? _selectedServices : null,
      );

      setState(() {
        _mechanicServices = services;
        _isLoading = false;
        _isFetchingData = false;
        _previousLat = _currentLat;
        _previousLng = _currentLng;
        _previousBrandName = _selectedBrand?['brand_name'];
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

  void _onBrandSelected(Map<String, dynamic>? brand) {
    setState(() => _selectedBrand = brand);
    _fetchData();
  }

  void _onServicesSelected(List<String> selectedServices) {
    setState(() => _selectedServices = selectedServices);
    _fetchData();
  }

  void _onLocationChanged(double lat, double lng, String newAddress) {
    setState(() {
      _currentLat = lat;
      _currentLng = lng;
      _address = newAddress;
    });
    _fetchData();
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
          onPressed: () => Navigator.pop(context),
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
      body: _isLoading || _isLocationLoading
          ? Center(child: LoadingAnimationWidget.newtonCradle(color: _accentSilver, size: 60))
          : _error != null
          ? _buildErrorWidget()
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader("Brand Auto"),
          BrandSelectorWidget(
            key: const ValueKey('brand_selector'),
            onBrandSelected: _onBrandSelected,
          ),
          const SizedBox(height: 24),
          _buildHeader("Servicii Tuning"),
          ServiceSelectionWidget(
            AutoServicetype: 'tuning_auto',
            key: const ValueKey('service_selector'),
            onServicesSelected: _onServicesSelected,
            initialSelectedServices: _selectedServices,
          ),
          const SizedBox(height: 24),
          _buildHeader("Ateliere Tuning"),
          _buildMechanicList(),
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

  Widget _buildMechanicList() {
    if (_mechanicServices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.tune_outlined, color: _darkCard, size: 80),
            const SizedBox(height: 16),
            const Text("Niciun atelier de tuning găsit în zonă.", style: TextStyle(color: _secondaryText)),
          ],
        ),
      );
    }
    return Column(
      children: _mechanicServices.map((service) {
        final String plan = service['subscription_plan']?.toString().toLowerCase() ?? "";
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
            color: _darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: BusinessCardWidget(
            supplierID: service['supplier_id'] ?? "",
            businessName: service['supplier_name'] ?? 'Workshop Tuning',
            rating: (service['review_score'] as num?)?.toDouble() ?? 0.0,
            reviewCount: service['total_reviews'] ?? 0,
            distance: "${service['distance_km'] ?? 0.0} km",
            location: service['supplier_address'] ?? 'Unknown',
            isAvailable: service['is_open'] ?? false,
            profileUrl: service['supplier_photo'] ?? '',
            servicesUrl: service['photo_url'] ?? '',
            carBrandUrl: service['brand_photo'] ?? '',
            tier: currentTier,
          ),
        );
      }).toList(),
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

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPickerModal(
        currentLat: _currentLat,
        currentLng: _currentLng,
        onLocationSelected: _onLocationChanged,
      ),
    );
  }
}

// --- UPDATED LOCATION PICKER MODAL ---
class _LocationPickerModal extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final Function(double, double, String) onLocationSelected;

  const _LocationPickerModal({required this.currentLat, required this.currentLng, required this.onLocationSelected});

  @override
  State<_LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<_LocationPickerModal> {
  late LatLng _selectedPos;
  bool _isResolvingAddress = false;

  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _navBarColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _selectedPos = LatLng(widget.currentLat, widget.currentLng);
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
              options: MapOptions(
                initialCenter: _selectedPos,
                initialZoom: 14,
                onTap: (tapPosition, point) => setState(() => _selectedPos = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: [
                  Marker(
                      point: _selectedPos,
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    setState(() => _isResolvingAddress = true);
                    final addr = await AddressService().getAddressFromCoordinates(_selectedPos.latitude, _selectedPos.longitude);
                    widget.onLocationSelected(_selectedPos.latitude, _selectedPos.longitude, addr);
                    Navigator.pop(context);
                  },
                  child: _isResolvingAddress
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("CONFIRMĂ LOCAȚIA", style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}