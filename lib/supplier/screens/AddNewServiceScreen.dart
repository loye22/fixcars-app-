import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../shared/services/api_service.dart';
import '../services/AddNewService.dart';

class AddNewServiceScreen extends StatefulWidget {
  const AddNewServiceScreen({super.key});

  @override
  State<AddNewServiceScreen> createState() => _AddNewServiceScreenState();
}

class _AddNewServiceScreenState extends State<AddNewServiceScreen> {
  final SupplierOptionsService _service = SupplierOptionsService();

  // UI state
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  // Step 1
  String? _selectedBrandId;
  final Set<String> _selectedServiceIds = {};

  // Step 2
  String? _selectedCityValue;
  String? _selectedSectorValue;
  final TextEditingController _priceCtrl = TextEditingController();

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadOptions();
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

  void _nextStep() {
    if (_selectedBrandId == null) {
      _showSnackBar('Vă rugăm să selectați o marcă auto');
      return;
    }
    if (_selectedServiceIds.isEmpty) {
      _showSnackBar('Selectați cel puțin un serviciu');
      return;
    }
    setState(() => _currentStep = 1);
  }

  void _previousStep() => setState(() => _currentStep = 0);

  void _submit() {
    _showSnackBar('Serviciu adăugat cu succes!', backgroundColor: Colors.green);
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: backgroundColor ?? Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Adăugare Serviciu',
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontWeight: FontWeight.w600,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
        onStepContinue: _currentStep == 0 ? _nextStep : _submit,
        onStepCancel: _currentStep == 1 ? _previousStep : null,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Row(
              children: [
                if (_currentStep == 1)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text(
                      'Înapoi',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    _currentStep == 0 ? 'Următorul' : 'Adaugă Serviciul',
                    style: const TextStyle(
                      fontFamily: 'SF Pro',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text(
              'Marcă & Servicii',
              style: TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.w600, fontSize: 17),
            ),
            subtitle: const Text(
              'Alegeți marca și serviciile oferite',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: _buildStep1(),
          ),
          Step(
            title: const Text(
              'Locație & Preț',
              style: TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.w600, fontSize: 17),
            ),
            subtitle: const Text(
              'Stabiliți zona și prețul',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1
                ? StepState.complete
                : (_currentStep == 1 ? StepState.editing : StepState.indexed),
            content: _buildStep2(),
          ),
        ],
      ),
    );
  }

  // ————————————————————————
  // STEP 1 – Marcă + Servicii
  // ————————————————————————
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
          // Marcă
          _buildSectionTitle('Marcă Auto'),
          const SizedBox(height: 12),
          _buildLuxuryDropdown(
            value: _selectedBrandId,
            hint: 'Selectați marca',
            items: brands
                .map((b) => DropdownMenuItem<String>(
              value: b['brand_id'] as String,
              child: Text(
                b['brand_name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ))
                .toList(),
            onChanged: (v) => setState(() => _selectedBrandId = v),
          ),
          const SizedBox(height: 40),

          // Servicii pe categorie
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ExpansionTile(
                  backgroundColor: Colors.grey[50],
                  collapsedBackgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Text(
                    catName,
                    style: const TextStyle(
                      fontFamily: 'SF Pro',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
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

  // ————————————————————————
  // STEP 2 – Locație & Preț
  // ————————————————————————
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

          _buildSectionTitle('Sector (opțional)'),
          const SizedBox(height: 12),
          _buildLuxuryDropdown(
            value: _selectedSectorValue,
            hint: 'Selectați sectorul',
            items: sectors
                .map((s) => DropdownMenuItem<String>(
              value: s['value'] as String,
              child: Text(s['label'] as String),
            ))
                .toList(),
            onChanged: (v) => setState(() => _selectedSectorValue = v),
          ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ————————————————————————
  // Helper Widgets
  // ————————————————————————
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'SF Pro',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          letterSpacing: -0.3,
        ),
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
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
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