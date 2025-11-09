import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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

  // Step 1
  String? _selectedBrandId;
  final Set<String> _selectedServiceIds = {};
  bool _isSubmitting = false;

  // Step 2
  String? _selectedCityValue;
  String _selectedSectorValue = ''; // Changed from nullable to required
  final TextEditingController _priceCtrl = TextEditingController();

  // Location
  Position? _currentPosition;
  String? _locationError;
  bool _isGettingLocation = false;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _getCurrentLocation();
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check permission
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

      // Get current position
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

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedBrandId == null) {
        _showSnackBar('Vă rugăm să selectați o marcă auto');
        return;
      }
      if (_selectedServiceIds.isEmpty) {
        _showSnackBar('Selectați cel puțin un serviciu');
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedCityValue == null) {
        _showSnackBar('Vă rugăm să selectați un oraș');
        return;
      }
      // Add sector validation (now required)
      if (_selectedSectorValue.isEmpty) {
        _showSnackBar('Vă rugăm să selectați un sector');
        return;
      }
    }
    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _submit() async {
    if (_isSubmitting) return;

    // Validate sector (now required)
    if (_selectedSectorValue.isEmpty) {
      _showSnackBar('Vă rugăm să selectați un sector', backgroundColor: Colors.red);
      return;
    }

    // Validate price (optional but should be number)
    final priceText = _priceCtrl.text.trim();
    double priceValue = 0.0;
    if (priceText.isNotEmpty) {
      final price = double.tryParse(priceText);
      if (price == null || price <= 0) {
        _showSnackBar('Introduceți un preț valid', backgroundColor: Colors.red);
        return;
      }
      priceValue = price;
    }

    // Use real coordinates - no validation for city matching
    if (_currentPosition == null) {
      _showSnackBar('Nu s-a putut obține locația. Încercați din nou.', backgroundColor: Colors.red);
      await _getCurrentLocation();
      if (_currentPosition == null) {
        return;
      }
    }

    // Round coordinates to 6 decimal places to match backend validation
    final double roundedLatitude = double.parse(_currentPosition!.latitude.toStringAsFixed(6));
    final double roundedLongitude = double.parse(_currentPosition!.longitude.toStringAsFixed(6));

    final Map<String, dynamic> payload = {
      "brand_id": _selectedBrandId,
      "service_ids": _selectedServiceIds.toList(),
      "city": _selectedCityValue,
      "sector": _selectedSectorValue,
      "latitude": roundedLatitude, // Use rounded latitude
      "longitude": roundedLongitude, // Use rounded longitude
      "price": priceValue,
    };

    // Remove null values
    payload.removeWhere((key, value) => value == null);

    final prettyJson = const JsonEncoder.withIndent('  ').convert(payload);
    debugPrint("Submitting payload:\n$prettyJson");

    setState(() => _isSubmitting = true);

    try {
      final result = await AddNewService().addSupplierBrandService(
        brandId: payload['brand_id'],
        serviceIds: payload['service_ids'],
        city: payload['city'],
        sector: payload['sector'],
        latitude: roundedLatitude, // Pass rounded coordinates
        longitude: roundedLongitude, // Pass rounded coordinates
        price: payload['price'] ?? 0.0,
      );

      if (result['success'] == true) {
        _showSnackBar(
          result['message'] ?? 'Serviciu adăugat cu succes!',
          backgroundColor: Colors.green,
        );
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } else {
        String errorMsg = result['error'] ?? 'Eroare necunoscută';
        final details = result['details'];
        if (details is Map) {
          // Handle different types of validation errors from backend
          if (details['non_field_errors'] != null) {
            errorMsg = details['non_field_errors'].join('\n');
          } else if (details['brand_id'] != null) {
            errorMsg = 'Eroare marcă: ${details['brand_id'].join('\n')}';
          } else if (details['service_ids'] != null) {
            errorMsg = 'Eroare servicii: ${details['service_ids'].join('\n')}';
          } else if (details['sector'] != null) {
            errorMsg = 'Eroare sector: ${details['sector'].join('\n')}';
          } else if (details['latitude'] != null || details['longitude'] != null) {
            errorMsg = 'Eroare coordonate: ${details['latitude'] ?? details['longitude']}';
          }
        }
        _showSnackBar(errorMsg, backgroundColor: Colors.red);
      }
    } catch (e) {
      _showSnackBar('Eroare de rețea: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
          : _buildStepper(),
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
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(primary: Colors.black),
        canvasColor: Colors.white,
      ),
      child: Stepper(
        physics: const ClampingScrollPhysics(),
        currentStep: _currentStep,
        onStepContinue: _currentStep < 2 ? _nextStep : _submit,
        onStepCancel: _currentStep > 0 ? _previousStep : null,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text(
                      'Înapoi',
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : details.onStepContinue,
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
                    _currentStep == 0
                        ? 'Următorul'
                        : _currentStep == 1
                        ? 'Vezi Rezumat'
                        : 'Confirmă și Adaugă',
                    style: const TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.2),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Marcă & Servicii', style: TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.w600, fontSize: 17)),
            subtitle: const Text('Alegeți marca și serviciile oferite', style: TextStyle(fontSize: 14, color: Colors.black54)),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: _buildStep1(),
          ),
          Step(
            title: const Text('Locație & Preț', style: TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.w600, fontSize: 17)),
            subtitle: const Text('Stabiliți zona și prețul', style: TextStyle(fontSize: 14, color: Colors.black54)),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : (_currentStep == 1 ? StepState.editing : StepState.indexed),
            content: _buildStep2(),
          ),
          Step(
            title: const Text('Rezumat', style: TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.w600, fontSize: 17)),
            subtitle: const Text('Verificați detaliile', style: TextStyle(fontSize: 14, color: Colors.black54)),
            isActive: _currentStep >= 2,
            state: StepState.editing,
            content: _buildStep3(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final List<dynamic> brands = _data!['brands'];
    final List<dynamic> rawCategories = _data!['services_by_category'];

    final Map<String, List<dynamic>> servicesByCat = {};
    for (final cat in rawCategories) {
      final String catName = cat['category_name'];
      final List<dynamic> services = cat['services'];
      servicesByCat[catName] = services;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Marcă Auto'),
          const SizedBox(height: 12),
          _buildLuxuryDropdown(
            value: _selectedBrandId,
            hint: 'Selectați marca',
            items: brands
                .map((b) => DropdownMenuItem<String>(
              value: b['brand_id'] as String,
              child: Text(b['brand_name'] as String, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            ))
                .toList(),
            onChanged: (v) => setState(() => _selectedBrandId = v),
          ),
          const SizedBox(height: 40),
          _buildSectionTitle('Servicii'),
          const SizedBox(height: 12),
          ...servicesByCat.entries.map((entry) {
            final String catName = entry.key;
            final List<dynamic> services = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ExpansionTile(
                  backgroundColor: Colors.grey[50],
                  collapsedBackgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Text(catName, style: const TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                  iconColor: Colors.black54,
                  collapsedIconColor: Colors.black54,
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: services.map<Widget>((s) {
                    final String id = s['service_id'];
                    final String name = s['service_name'];
                    final bool selected = _selectedServiceIds.contains(id);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? Colors.black.withOpacity(0.06) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? Colors.black87 : Colors.black54,
                            fontSize: 15.5,
                          ),
                        ),
                        value: selected,
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedServiceIds.add(id);
                            } else {
                              _selectedServiceIds.remove(id);
                            }
                          });
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

  Widget _buildStep2() {
    final List<dynamic> cities = _data!['cities'];
    final List<dynamic> sectors = _data!['sectors'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 36),

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

          // const SizedBox(height: 20),
          // _buildLocationStatus(),

          const SizedBox(height: 36),
          _buildSectionTitle('Preț (opțional)'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'SF Pro', fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'ex. 250',
              hintStyle: TextStyle(color: Colors.grey[500], fontFamily: 'SF Pro'),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    // Calculate rounded coordinates for display
    String displayLat = _currentPosition != null
        ? _currentPosition!.latitude.toStringAsFixed(6)
        : '--';
    String displayLng = _currentPosition != null
        ? _currentPosition!.longitude.toStringAsFixed(6)
        : '--';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _currentPosition != null ? Icons.location_on : Icons.location_off,
              color: _currentPosition != null ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _isGettingLocation
                  ? const Text('Obținere locație...', style: TextStyle(fontSize: 14))
                  : _currentPosition != null
                  ? Text(
                'Locație detectată: $displayLat, $displayLng',
                style: const TextStyle(fontSize: 14, color: Colors.green),
              )
                  : Text(
                _locationError ?? 'Se așteaptă permisiunea locației',
                style: const TextStyle(fontSize: 14, color: Colors.orange),
              ),
            ),
            if (_locationError != null || _currentPosition == null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _getCurrentLocation,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildStep3() {
    final brandName = _data!['brands'].firstWhere(
          (b) => b['brand_id'] == _selectedBrandId,
      orElse: () => {'brand_name': 'Necunoscut'},
    )['brand_name'] ?? 'Necunoscut';

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

    // Build services summary
    final List<String> servicesLines = [];
    for (final cat in _data!['services_by_category']) {
      final catName = cat['category_name'] as String;
      final services = cat['services'] as List<dynamic>;
      final selectedInCat = services
          .where((s) => _selectedServiceIds.contains(s['service_id']))
          .map((s) => s['service_name'] as String)
          .toList();

      if (selectedInCat.isNotEmpty) {
        servicesLines.add('$catName:');
        for (final service in selectedInCat) {
          servicesLines.add('  • $service');
        }
      }
    }
    final servicesText = servicesLines.isEmpty ? 'Niciun serviciu selectat' : servicesLines.join('\n');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            title: 'Marcă Auto',
            content: brandName,
            icon: Icons.directions_car,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Servicii Selectate',
            content: servicesText,
            icon: Icons.build,
            isMultiline: true,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Locație',
            content: '$cityLabel${sectorLabel != null ? ' ($sectorLabel)' : ''}',
            icon: Icons.location_on,
          ),
          // const SizedBox(height: 16),
          // _buildSummaryCard(
          //   title: 'Coordonate',
          //   content: _currentPosition != null
          //       ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
          //       : 'Locație nedetectată',
          //   icon: Icons.gps_fixed,
          // ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Preț',
            content: _priceCtrl.text.isEmpty ? 'Nu a fost specificat' : '${_priceCtrl.text} RON',
            icon: Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String content,
    required IconData icon,
    bool isMultiline = false,
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
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'SF Pro', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontFamily: 'SF Pro', fontSize: 16.5, fontWeight: FontWeight.w500, color: Colors.black87),
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
        style: const TextStyle(fontFamily: 'SF Pro', fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: -0.3),
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
            hint: Text(hint, style: TextStyle(color: Colors.grey[600], fontFamily: 'SF Pro')),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54, size: 26),
            style: const TextStyle(color: Colors.black87, fontSize: 16, fontFamily: 'SF Pro'),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(18),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

