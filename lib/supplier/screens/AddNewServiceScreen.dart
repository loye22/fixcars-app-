import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../../shared/screens/BusinessLocationPermissionGate.dart';
import '../../shared/services/api_service.dart';
import '../services/AddNewService.dart';
import '../services/GetServiceOptions.dart';

class AddNewServiceScreen extends StatefulWidget {
  const AddNewServiceScreen({super.key});

  @override
  State<AddNewServiceScreen> createState() => _AddNewServiceScreenState();
}

class _AddNewServiceScreenState extends State<AddNewServiceScreen> {
  final GetServiceOptions _service = GetServiceOptions();

  // UI state
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  // New Configuration State
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final Set<String> _selectedBrandIds = {};
  bool _selectAllBrands = false;
  final Map<String, Set<String>> _servicesByBrand = {}; // brand_id -> Set<service_id>


  final AddNewService _addService = AddNewService();

  // NEW: Scroll controller and error tracking
  final ScrollController _scrollController = ScrollController();
  String? _brandWithNoServices; // Track which brand has no services

  // Original Location State (kept for backward compatibility)
  Position? _currentPosition;
  String? _locationError;
  bool _isGettingLocation = false;

  // Original Step 2 State
  String? _selectedCityValue;
  String _selectedSectorValue = '';
  final TextEditingController _priceCtrl = TextEditingController();

  bool _isSubmitting = false;

  // UI Constants
  static const _gridColumns = 3;
  static const _brandLogoSize = 60.0;
  static const _cardBorderRadius = 16.0;
  static const _animationDuration = Duration(milliseconds: 300);


  @override
  void initState() {
    super.initState();
    _loadOptions();
    //_getCurrentLocation();
    _checkAndGetLocation();
  }


  Future<void> _checkAndGetLocation() async {
    // First check if we have permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // If no permission, show the permission gate
      _navigateToPermissionGate();
      return;
    }

    // If we have permission, get location
    await _getCurrentLocation();
  }

  void _navigateToPermissionGate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BusinessLocationPermissionGate(
            child: AddNewServiceScreen(), // This screen will restart
          ),
        ),
      );
    });
  }

  Future<void> _loadOptions() async {
    try {
      final data = await _service.fetchSupplierOptions();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Original location functions remain the same
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permisiunea locației a fost refuzată';
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permisiunile de locație sunt refuzate permanent';
          _isGettingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _currentPosition = position;
        _isGettingLocation = false;
      });

    } catch (e) {
      setState(() {
        _locationError = 'Eroare la obținerea locației: $e';
        _isGettingLocation = false;
      });
    }
  }

  // NEW: Updated _nextStep function with service validation
  void _nextStep() {
    if (_currentStep == 0) {
      // Validate brand selection
      if (_selectedBrandIds.isEmpty && !_selectAllBrands) {
        _showSnackBar('Vă rugăm să selectați cel puțin o marcă auto');
        return;
      }
    } else if (_currentStep == 1) {
      // Validate service selection for each brand
      if (_selectAllBrands) {
        // For "all brands", we still need to check if any services are selected
        bool hasServices = false;
        for (final brandId in _selectedBrandIds) {
          final services = _servicesByBrand[brandId];
          if (services != null && services.isNotEmpty) {
            hasServices = true;
            break;
          }
        }

        if (!hasServices) {
          _showSnackBar('Vă rugăm să selectați cel puțin un serviciu pentru toate mărcile');
          return;
        }
      } else {
        // Check each selected brand for services
        for (final brandId in _selectedBrandIds) {
          final services = _servicesByBrand[brandId];
          if (services == null || services.isEmpty) {
            // Highlight this brand
            setState(() {
              _brandWithNoServices = brandId;
            });

            // Scroll to the problematic brand
            _scrollToBrandWithNoServices();

            // Show error message with brand name
            final brand = _data!['brands'].firstWhere(
                  (b) => b['brand_id'] == brandId,
              orElse: () => {'brand_name': 'Această marcă'},
            );
            final brandName = brand['brand_name'] as String;

            _showSnackBar('Vă rugăm să selectați cel puțin un serviciu pentru $brandName',
                backgroundColor: Colors.red);
            return;
          }
        }
      }
      // Clear the error if validation passes
      setState(() {
        _brandWithNoServices = null;
      });
    } else if (_currentStep == 2) {
      // Location validation (price field removed)
      if (_selectedCityValue == null) {
        _showSnackBar('Vă rugăm să selectați un oraș');
        return;
      }
      if (_selectedSectorValue.isEmpty) {
        _showSnackBar('Vă rugăm să selectați un sector');
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  // NEW: Scroll to brand with no services
  void _scrollToBrandWithNoServices() {
    if (_brandWithNoServices == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find the index of the brand with no services
      final brands = _data!['brands'] as List;
      final index = brands.indexWhere((b) => b['brand_id'] == _brandWithNoServices);

      if (index != -1 && _scrollController.hasClients) {
        // Calculate scroll position based on brand position
        final itemHeight = 180.0; // Approximate height of each brand card
        final scrollPosition = (index ~/ _gridColumns) * itemHeight;

        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _submit() async {
    // 1. Check if we have location - if not, show error immediately
    if (_currentPosition == null) {
      _showSnackBar(
        'Locația nu este disponibilă. Vă rugăm să acordați permisiunea de localizare.',
        backgroundColor: Colors.red,
      );

      // Optional: Trigger location request
      await _getCurrentLocation();
      return;
    }

    // 2. Basic validation
    if (_selectedSectorValue.isEmpty) {
      _showSnackBar('Vă rugăm să selectați un sector', backgroundColor: Colors.red);
      return;
    }

    // 3. Prepare location data
    final double latitude = double.parse(_currentPosition!.latitude.toStringAsFixed(6));
    final double longitude = double.parse(_currentPosition!.longitude.toStringAsFixed(6));

    // 4. Create payloads
    final List<Map<String, dynamic>> payloads = [];

    for (final brandId in _selectedBrandIds) {
      final services = _servicesByBrand[brandId] ?? {};

      // Only add if there are services for this brand
      if (services.isNotEmpty) {
        payloads.add({
          "brand_id": brandId,
          "service_ids": services.toList(),
        });
      }
    }

    // Check if we have any payloads
    if (payloads.isEmpty) {
      _showSnackBar('Niciun serviciu selectat pentru a fi adăugat', backgroundColor: Colors.red);
      return;
    }

    // 5. Call API
    setState(() => _isSubmitting = true);

    final result = await _addService.addSupplierBrandService(

      city: _selectedCityValue!,
      sector: _selectedSectorValue,
      latitude: latitude,
      longitude: longitude,
      payloads: payloads,
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      final createdCount = result['created_count'] ?? 0;

      _showSnackBar(
        '${result['message']} ($createdCount servicii adăugate)',
        backgroundColor: Colors.green,
      );

      // Optionally navigate back or reset form
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });

    } else {
      // Handle errors, including duplicate errors
      final errorMessage = result['error'] ?? 'Eroare necunoscută';
      final duplicateErrors = result['duplicate_errors'] as List?;

      if (duplicateErrors != null && duplicateErrors.isNotEmpty) {
        // Handle duplicate errors with more detail
        final duplicateCount = duplicateErrors.length;
        _showSnackBar(
          '$errorMessage ($duplicateCount combinații existente)',
          backgroundColor: Colors.orange,
        );
      } else {
        _showSnackBar(errorMessage, backgroundColor: Colors.red);
      }
    }
  }

  // void _submit() async {
  //   // 1. Check if we have location - if not, show error immediately
  //   if (_currentPosition == null) {
  //     _showSnackBar(
  //       'Locația nu este disponibilă. Vă rugăm să acordați permisiunea de localizare.',
  //       backgroundColor: Colors.red,
  //     );
  //
  //     // Optional: Trigger location request
  //     await _getCurrentLocation();
  //     return;
  //   }
  //
  //   // 2. Basic validation
  //   if (_selectedSectorValue.isEmpty) {
  //     _showSnackBar('Vă rugăm să selectați un sector', backgroundColor: Colors.red);
  //     return;
  //   }
  //
  //   // 3. Prepare location data
  //   final double latitude = double.parse(_currentPosition!.latitude.toStringAsFixed(6));
  //   final double longitude = double.parse(_currentPosition!.longitude.toStringAsFixed(6));
  //
  //   // 4. Create payloads
  //   final List<Map<String, dynamic>> allPayloads = [];
  //   for (final brandId in _selectedBrandIds) {
  //     final services = _servicesByBrand[brandId] ?? {};
  //
  //     for (final serviceId in services) {
  //       allPayloads.add({
  //         "brand_id": brandId,
  //         "service_ids": [serviceId],
  //         "city": _selectedCityValue,
  //         "sector": _selectedSectorValue,
  //         "latitude": latitude,
  //         "longitude": longitude,
  //         "price": 0.0,
  //       });
  //     }
  //   }
  //
  //
  //  // print(allPayloads);
  //
  //   // // 5. Print JSON
  //   //  _printFinalJson(allPayloads, latitude, longitude);
  //
  //   // 6. Show success
  //   // _showSnackBar(
  //   //   '${allPayloads.length} combinații create cu succes.',
  //   //   backgroundColor: Colors.green,
  //   // );
  //
  //
  // }

  void _printFinalJson(List<Map<String, dynamic>> payloads, double latitude, double longitude) {
    // Remove duplicate location data from each payload
    final List<Map<String, dynamic>> normalizedPayloads = [];

    for (final payload in payloads) {
      normalizedPayloads.add({
        "brand_id": payload["brand_id"],
        "service_ids": payload["service_ids"],
      });
    }

    final Map<String, dynamic> output = {
      "total_payloads": payloads.length,
      "shared_location": {
        "city": _selectedCityValue,
        "sector": _selectedSectorValue,
        "latitude": latitude,
        "longitude": longitude,
        "is_real_location": true,
      },
      "payloads": normalizedPayloads,
      "metadata": {
        "price": 0.0, // Same for all payloads
        "created_at": DateTime.now().toIso8601String(),
      }
    };

    final jsonEncoder = JsonEncoder.withIndent('  ');
    final prettyJson = jsonEncoder.convert(output);

    debugPrint('🎯 FINAL PAYLOADS (NORMALIZED):');
    debugPrint(prettyJson);
  }
  // Brand selection functions
  void _toggleBrandSelection(String brandId) {
    setState(() {
      if (_selectedBrandIds.contains(brandId)) {
        _selectedBrandIds.remove(brandId);
        _servicesByBrand.remove(brandId);
      } else {
        _selectedBrandIds.add(brandId);
        _servicesByBrand[brandId] = {};
      }
    });
  }

  void _toggleAllBrands() {
    setState(() {
      _selectAllBrands = !_selectAllBrands;
      if (_selectAllBrands) {
        // Select all brands
        final brands = _data?['brands'] as List? ?? [];
        _selectedBrandIds.clear();
        _servicesByBrand.clear();

        for (final brand in brands) {
          final brandId = brand['brand_id'] as String;
          _selectedBrandIds.add(brandId);
          _servicesByBrand[brandId] = {};
        }
      } else {
        // Keep current selections but clear the flag
        _selectedBrandIds.clear();
        _servicesByBrand.clear();
      }
    });
  }

  // UPDATED: _toggleServiceForBrand with error clearing
  void _toggleServiceForBrand(String brandId, String serviceId) {
    setState(() {
      final services = _servicesByBrand[brandId] ?? {};
      if (services.contains(serviceId)) {
        services.remove(serviceId);
      } else {
        services.add(serviceId);
      }
      _servicesByBrand[brandId] = services;

      // Clear the error if this was the problematic brand
      if (_brandWithNoServices == brandId && services.isNotEmpty) {
        _brandWithNoServices = null;
      }
    });
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor ?? Colors.black87,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
        ),
      )
          : _error != null
          ? _buildErrorView()
          : _buildMainContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.redAccent.withOpacity(0.8)),
          const SizedBox(height: 20),
          Text(
            'Eroare la încărcare',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadOptions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Încearcă din nou', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [

        SizedBox(height: 50,) ,
        // Step Indicator
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              _buildStepIndicator(0, 'Mărci'),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              _buildStepIndicator(1, 'Servicii'),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              _buildStepIndicator(2, 'Locație'),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              _buildStepIndicator(3, 'Confirmare'),
            ],
          ),
        ),

        // Content Area
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1Brands(),
              _buildStep2Services(),
              _buildStep3Location(),
              _buildStep4Summary(),
            ],
          ),
        ),

        // Navigation Buttons
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: _previousStep,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Înapoi',
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                )
              else
                const SizedBox(width: 120),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  _currentStep == 3 ? 'Confirmă și Adaugă' : 'Următorul',
                  style: const TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return SingleChildScrollView(
      child: Column(
        children: [
          // SizedBox(height: 50,) ,
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive || isCompleted ? Colors.black : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text(
                (stepIndex + 1).toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive || isCompleted ? Colors.black : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Brands() {
    final List<dynamic> brands = _data!['brands'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Selectare Marcă Auto'),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Alegeți mărcile auto pentru care oferiți servicii',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),

          // "Select All" Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_cardBorderRadius),
                side: BorderSide(
                  color: _selectAllBrands ? Colors.black : Colors.grey.shade300,
                  width: _selectAllBrands ? 2 : 1,
                ),
              ),
              child: CheckboxListTile(
                title: const Text(
                  'Ofer servicii pentru toate mărcile auto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Selectați această opțiune dacă serviți toate mărcile disponibile',
                  style: TextStyle(fontSize: 14),
                ),
                value: _selectAllBrands,
                activeColor: Colors.black,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                onChanged: (value) => _toggleAllBrands(),
                tileColor: _selectAllBrands ? Colors.black.withOpacity(0.05) : null,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Brands Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                final brandId = brand['brand_id'] as String;
                final brandName = brand['brand_name'] as String;
                final brandPhoto = brand['brand_photo'] as String?;
                final isSelected = _selectedBrandIds.contains(brandId) || _selectAllBrands;

                return GestureDetector(
                  onTap: _selectAllBrands ? null : () => _toggleBrandSelection(brandId),
                  child: AnimatedContainer(
                    duration: _animationDuration,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_cardBorderRadius),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Brand Logo with centered container
                              Container(
                                width: _brandLogoSize,
                                height: _brandLogoSize,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: brandPhoto != null && brandPhoto.isNotEmpty
                                      ? DecorationImage(
                                    image: NetworkImage(brandPhoto),
                                    fit: BoxFit.cover,
                                  )
                                      : null,
                                  color: Colors.grey.shade100,
                                ),
                                alignment: Alignment.center,
                                child: brandPhoto == null || brandPhoto.isEmpty
                                    ? const Icon(
                                  Icons.directions_car,
                                  size: 32,
                                  color: Colors.grey,
                                )
                                    : null,
                              ),

                              // Brand Name with proper constraints
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 100, // Prevent text from being too wide
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    brandName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? Colors.black : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Selection Checkmark (kept in top right)
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // Disabled Overlay
                        if (_selectAllBrands)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(_cardBorderRadius),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Services() {
    if (_selectAllBrands) {
      return _buildAllBrandsServices();
    }

    final brands = _data!['brands'] as List;
    final selectedBrands = brands.where((b) => _selectedBrandIds.contains(b['brand_id'])).toList();

    return ListView.builder(
      controller: _scrollController, // Add scroll controller
      itemCount: selectedBrands.length,
      itemBuilder: (context, index) {
        final brand = selectedBrands[index];
        final brandId = brand['brand_id'] as String;
        final brandName = brand['brand_name'] as String;
        final brandPhoto = brand['brand_photo'] as String?;
        final selectedServices = _servicesByBrand[brandId] ?? {};
        final hasNoServices = selectedServices.isEmpty;
        final isProblemBrand = _brandWithNoServices == brandId;

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardBorderRadius),
            border: Border.all(
              color: isProblemBrand ? Colors.red : Colors.transparent,
              width: isProblemBrand ? 2 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: isProblemBrand
                    ? Colors.red.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isProblemBrand ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cardBorderRadius),
            ),
            color: isProblemBrand ? Colors.red.shade50 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Header with logo
                  Row(
                    children: [
                      // Brand Logo
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: brandPhoto != null && brandPhoto.isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(brandPhoto),
                            fit: BoxFit.cover,
                          )
                              : null,
                          color: Colors.grey.shade100,
                        ),
                        child: brandPhoto == null || brandPhoto.isEmpty
                            ? Icon(
                          Icons.directions_car,
                          size: 24,
                          color: isProblemBrand ? Colors.red : Colors.grey,
                        )
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          brandName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isProblemBrand ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${selectedServices.length} servicii',
                          style: TextStyle(
                            color: isProblemBrand ? Colors.red : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: isProblemBrand
                            ? Colors.red.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                        side: BorderSide(
                          color: isProblemBrand ? Colors.red : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ],
                  ),

                  // Error message if no services
                  if (isProblemBrand)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 52),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            'Selectați cel puțin un serviciu',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Service Categories
                  ..._buildServiceCategoriesForBrand(brandId, isProblemBrand),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildServiceCategoriesForBrand(String brandId, bool isProblemBrand) {
    final List<dynamic> rawCategories = _data!['services_by_category'];
    final selectedServices = _servicesByBrand[brandId] ?? {};

    return rawCategories.map((category) {
      final String catName = category['category_name'] as String;
      final List<dynamic> services = category['services'];

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isProblemBrand ? Colors.red : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isProblemBrand ? Colors.red.shade300 : Colors.grey.shade200,
          ),
        ),
        child: ExpansionTile(
          backgroundColor: isProblemBrand ? Colors.red : Colors.grey[50],
          collapsedBackgroundColor: isProblemBrand ? Colors.red : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            catName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isProblemBrand ? Colors.red.shade800 : Colors.black87,
            ),
          ),
          iconColor: isProblemBrand ? Colors.red : Colors.black54,
          collapsedIconColor: isProblemBrand ? Colors.red : Colors.black54,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: services.map<Widget>((service) {
            final String id = service['service_id'] as String;
            final String name = service['service_name'] as String;
            final bool selected = selectedServices.contains(id);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? (isProblemBrand ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.06))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? (isProblemBrand ? Colors.red.shade800 : Colors.black87)
                        : (isProblemBrand ? Colors.red.shade700 : Colors.black54),
                    fontSize: 15,
                  ),
                ),
                value: selected,
                activeColor: isProblemBrand ? Colors.red : Colors.black,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onChanged: (val) {
                  _toggleServiceForBrand(brandId, id);
                  // Clear error if services are now selected
                  if (val == true && _brandWithNoServices == brandId) {
                    setState(() {
                      _brandWithNoServices = null;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildAllBrandsServices() {
    final List<dynamic> rawCategories = _data!['services_by_category'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Card(
            color: Colors.white,
            margin: EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.black),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Serviciile selectate aici se vor aplica pentru TOATE mărcile auto.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Service Categories
          ...rawCategories.map((category) {
            final String catName = category['category_name'] as String;
            final List<dynamic> services = category['services'];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ExpansionTile(
                  backgroundColor: Colors.grey[50],
                  collapsedBackgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(catName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  iconColor: Colors.black54,
                  collapsedIconColor: Colors.black54,
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: services.map<Widget>((service) {
                    final String id = service['service_id'] as String;
                    final String name = service['service_name'] as String;
                    final isSelected = _servicesByBrand.values.any((set) => set.contains(id));

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black.withOpacity(0.06) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.black87 : Colors.black54,
                            fontSize: 15.5,
                          ),
                        ),
                        value: isSelected,
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onChanged: (val) {
                          // Apply to all brands
                          for (final brandId in _selectedBrandIds) {
                            _toggleServiceForBrand(brandId, id);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStep3Location() {
    final List<dynamic> cities = _data!['cities'];
    final List<dynamic> sectors = _data!['sectors'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Locație'),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Stabiliți zona în care oferiți serviciile',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Oraș'),
          const SizedBox(height: 12),
          _buildLuxuryDropdown(
            value: _selectedCityValue,
            hint: 'Selectați orașul',
            items: cities
                .map((c) => DropdownMenuItem<String>(
              value: c['value'] as String,
              child: Text(c['label'] as String),
            ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCityValue = v),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Sector'),
          const SizedBox(height: 12),
          _buildLuxuryDropdown(
            value: _selectedSectorValue.isEmpty ? null : _selectedSectorValue,
            hint: 'Selectați sectorul',
            items: sectors
                .map((s) => DropdownMenuItem<String>(
              value: s['value'] as String,
              child: Text(s['label'] as String),
            ))
                .toList(),
            onChanged: (v) => setState(() => _selectedSectorValue = v ?? ''),
          ),

          // Price field REMOVED
        ],
      ),
    );
  }

  Widget _buildStep4Summary() {
    final brands = _data!['brands'] as List;
    final cityLabel = _data!['cities'].firstWhere(
          (c) => c['value'] == _selectedCityValue,
      orElse: () => {'label': _selectedCityValue},
    )['label'] ?? _selectedCityValue;

    final sectorLabel = _selectedSectorValue.isNotEmpty
        ? _data!['sectors'].firstWhere(
          (s) => s['value'] == _selectedSectorValue,
      orElse: () => {'label': _selectedSectorValue},
    )['label']
        : null;

    // Calculate totals
    int totalServices = 0;
    for (final services in _servicesByBrand.values) {
      totalServices += services.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Rezumat Configurație'),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Verificați detaliile înainte de confirmare',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),

          // Summary Cards
          _buildSummaryCard(
            title: 'Mărci Selectate',
            content: _selectAllBrands
                ? 'Toate mărcile (${_selectedBrandIds.length})'
                : '${_selectedBrandIds.length} marcă(i) selectate',
            icon: Icons.directions_car,
            color: Colors.blue,
          ),

          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Servicii Configurate',
            content: 'Total: $totalServices servicii',
            icon: Icons.build,
            color: Colors.green,
            isMultiline: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildServiceSummaryList(),
            ),
          ),

          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Locație',
            content: '$cityLabel${sectorLabel != null ? ' ($sectorLabel)' : ''}',
            icon: Icons.location_on,
            color: Colors.orange,
          ),

          // Price card REMOVED
        ],
      ),
    );
  }

  List<Widget> _buildServiceSummaryList() {
    final List<Widget> widgets = [];

    if (_selectAllBrands) {
      widgets.add(const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('Servicii aplicate pentru toate mărcile'),
      ));
    } else {
      for (final brandId in _selectedBrandIds) {
        final brand = _data!['brands'].firstWhere(
              (b) => b['brand_id'] == brandId,
          orElse: () => {'brand_name': 'Necunoscut'},
        );
        final brandName = brand['brand_name'] as String;
        final services = _servicesByBrand[brandId] ?? {};

        if (services.isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$brandName: ${services.length} servicii',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ));
        }
      }
    }

    return widgets;
  }

  Widget _buildSummaryCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    bool isMultiline = false,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                if (child != null) child else Text(
                  content,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _buildLuxuryDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54, size: 26),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(18),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose(); // Add this line
    _priceCtrl.dispose();
    super.dispose();
  }
}