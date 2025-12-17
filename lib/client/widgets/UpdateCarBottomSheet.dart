import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/CarService.dart';

class UpdateCarBottomSheet extends StatefulWidget {
  const UpdateCarBottomSheet({super.key});

  @override
  State<UpdateCarBottomSheet> createState() => _UpdateCarBottomSheetState();
}

class _UpdateCarBottomSheetState extends State<UpdateCarBottomSheet> {
  final CarService _carService = CarService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  String? _errorMessage;

  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _plateController;
  late TextEditingController _vinController;
  late TextEditingController _kmController;

  List<dynamic> _brands = [];
  Map<String, dynamic>? _selectedBrand;
  String? _carId;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController();
    _yearController = TextEditingController();
    _plateController = TextEditingController();
    _vinController = TextEditingController();
    _kmController = TextEditingController();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final response = await _carService.fetchCurrentCarDetails();
      if (response['success'] == true) {
        final data = response['data'];
        final currentCar = data['current_car'];

        setState(() {
          _brands = data['available_brands'] ?? [];
          if (currentCar != null) {
            _carId = currentCar['car_id'];
            _modelController.text = currentCar['model'] ?? '';
            _yearController.text = currentCar['year']?.toString() ?? '';
            _plateController.text = currentCar['license_plate'] ?? '';
            _vinController.text = currentCar['vin'] ?? '';
            _kmController.text = currentCar['current_km']?.toString() ?? '';

            _selectedBrand = _brands.firstWhere(
                  (b) => b['brand_id'] == currentCar['brand_id'],
              orElse: () => _brands.isNotEmpty ? _brands.first : null,
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Eroare la încărcarea datelor.";
        _isLoading = false;
      });
    }
  }

  // --- NOUL DIALOG ELEGANT (TEMA DARK) ---
  void _showElegantConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A), // Fundal asortat cu cardurile
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade800, width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
             //   const Icon(Icons.info_outline, color: Colors.orange, size: 40),
                const SizedBox(height: 20),
                const Text(
                  "Confirmare actualizare",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Ești sigur că vrei să actualizezi detaliile mașinii?",
                  style: TextStyle(color: Color(0xFF808080), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("ANULEAZĂ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Închide dialogul
                          _performUpdate(); // Execută print-ul
                        },
                        child: const Text("CONFIRMĂ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // În interiorul _UpdateCarBottomSheetState

  void _performUpdate() async {
    setState(() => _isLoading = true);

    // Formatăm data exact cum cere serverul: YYYY-MM-DD
    final now = DateTime.now();
    final String formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      final result = await _carService.updateCar(
        carId: _carId!,
        brandId: _selectedBrand!['brand_id'].toString(),
        model: _modelController.text,
        year: int.parse(_yearController.text),
        currentKm: int.parse(_kmController.text),
        lastKmUpdatedAt: formattedDate, // Folosim formatul corect
        licensePlate: _plateController.text,
        vin: _vinController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);

        // Extragem eroarea specifică din map-ul de erori trimis de server
        String displayError = result['error'] ?? "A apărut o eroare.";

        if (result['fieldErrors'] != null && result['fieldErrors'] is Map) {
          final Map<String, dynamic> errors = result['fieldErrors'];
          // Dacă serverul trimite eroarea de format dată, o extragem:
          if (errors.containsKey('last_km_updated_at')) {
            displayError = errors['last_km_updated_at'][0];
          } else {
            // Luăm prima eroare găsită în orice alt câmp
            displayError = errors.values.first[0];
          }
        }

        _showElegantErrorDialog(displayError);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showElegantErrorDialog("Eroare de conexiune la server.");
    }
  }
  void _showBrandPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: const Color(0xFF1E1E1E),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF2C2C2C),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(child: const Text('Anulează'), onPressed: () => Navigator.pop(context)),
                  CupertinoButton(child: const Text('Gata'), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 45,
                scrollController: FixedExtentScrollController(
                  initialItem: _brands.indexWhere((b) => b['brand_id'] == _selectedBrand?['brand_id']),
                ),
                onSelectedItemChanged: (index) {
                  setState(() => _selectedBrand = _brands[index]);
                },
                children: _brands.map((brand) {
                  return Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (brand['brand_photo'] != null) Image.network(brand['brand_photo'], width: 24, height: 24),
                        const SizedBox(width: 12),
                        Text(brand['brand_name'], style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showElegantErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 20),
                const Text(
                  "Eroare de validare",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  style: const TextStyle(color: Color(0xFFC0C0C0), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ÎNCHIDE", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF121212), // Fundal Dark elegant
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: _isLoading
          ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Colors.orange)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text("Actualizare Detalii Vehicul", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 25),

              // Brand Selector
              const Text("Marcă", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showBrandPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade800)),
                  child: Row(
                    children: [
                      if (_selectedBrand != null) Image.network(_selectedBrand!['brand_photo'], width: 24),
                      const SizedBox(width: 12),
                      Text(_selectedBrand?['brand_name'] ?? "Selectează Marca", style: const TextStyle(color: Colors.white, fontSize: 16)),
                      const Spacer(),
                      const Icon(CupertinoIcons.chevron_down, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildTextField("Model", _modelController),
              _buildTextField("An Fabricație", _yearController, isNumeric: true),
              _buildTextField("Număr Înmatriculare", _plateController, isRequired: false),
              _buildTextField("Serie Șasiu (VIN)", _vinController, isRequired: false),
              _buildTextField("Kilometraj Actual (km)", _kmController, isNumeric: true),

              const SizedBox(height: 30),
              // SizedBox(
              //   width: double.infinity,
              //   height: 55,
              //   child: ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.orange.shade700,
              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              //       elevation: 5,
              //     ),
              //     onPressed: () {
              //       if (_formKey.currentState!.validate()) {
              //         _showElegantConfirmationDialog();
              //       }
              //     },
              //     child: const Text("ACTUALIZEAZĂ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              //   ),
              // ),
              // În metoda build din UpdateCarBottomSheet
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : () { // Dezactivat dacă se încarcă
                    if (_formKey.currentState!.validate()) {
                      _showElegantConfirmationDialog();
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Text("ACTUALIZEAZĂ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumeric = false, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return 'Acest câmp este obligatoriu';
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              errorStyle: const TextStyle(color: Colors.redAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}