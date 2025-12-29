import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../shared/services/api_service.dart';
import '../services/CarService.dart';

class AddCarObligationBottomSheet extends StatefulWidget {
  const AddCarObligationBottomSheet({super.key});

  @override
  State<AddCarObligationBottomSheet> createState() => _AddCarObligationBottomSheetState();
}

class _AddCarObligationBottomSheetState extends State<AddCarObligationBottomSheet> {
  final CarService _carService = CarService();
  final ApiService apiService = ApiService();

  bool _isSubmitting = false;

  // Form Fields
  ObligationType _selectedObligation = ObligationType.ITP;
  ReminderType _selectedReminder = ReminderType.LEGAL;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  // File State
  File? _selectedFile;
  String? _fileName;

  /// ELEGANT SELECTION POPUP: Matches your Error Dialog theme exactly
  void _showSelectionDialog() {
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
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.doc_on_doc, color: Colors.blueAccent, size: 40),
                const SizedBox(height: 20),
                const Text(
                  "Încarcă Document",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Alege sursa documentului pentru această obligație",
                  style: TextStyle(color: Color(0xFFC0C0C0), fontSize: 13, decoration: TextDecoration.none, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Gallery Option
                _buildPopupButton(
                  label: "GALERIE FOTO",
                  icon: CupertinoIcons.photo,
                  onPressed: () {
                    Navigator.pop(context);
                    _handleFileSelection(FileType.image);
                  },
                ),

                const SizedBox(height: 12),

                // Files Option
                _buildPopupButton(
                  label: "FIȘIERE / ICLOUD",
                  icon: CupertinoIcons.folder,
                  onPressed: () {
                    Navigator.pop(context);
                    _handleFileSelection(FileType.any);
                  },
                ),

                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ANULEAZĂ", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper for Popup Buttons
  Widget _buildPopupButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileSelection(FileType type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: type);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showElegantErrorDialog("Eroare la selectarea fișierului: $e");
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    String documentUrl = "";

    if (_selectedFile != null) {
      final uploadResult = await apiService.uploadFile2(_selectedFile!);
      if (uploadResult['success']) {
        documentUrl = uploadResult['data']['file_url'] ?? "";
      } else {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showElegantErrorDialog(uploadResult['error'] ?? 'Încărcarea a eșuat');
        return;
      }
    }

    final result = await _carService.addCarObligation(
      obligationType: _selectedObligation,
      reminderType: _selectedReminder,
      dueDate: _selectedDate,
      note: _noteController.text,
      documentUrl: documentUrl,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success']) {
      Navigator.pop(context, true);
    } else {
      _showElegantErrorDialog(result['error'] ?? 'Eroare la adăugare');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Adaugă Obligație", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),

            _buildIosSelector(
              label: "Tip Obligație",
              value: _selectedObligation.displayName, // Change from .name to .displayName
              onTap: () => _showCupertinoPicker(
                title: "Selectează Tipul",
                items: ObligationType.values.map((e) => e.displayName).toList(), // Place it here
                initialIndex: _selectedObligation.index,
                onSelect: (i) => setState(() => _selectedObligation = ObligationType.values[i]),
              ),
            ),
            // _buildIosSelector(
            //   label: "Tip Obligație",
            //   value: _selectedObligation.name,
            //   onTap: () => _showCupertinoPicker(
            //     title: "Selectează Tipul",
            //     items: ObligationType.values.map((e) => e.name).toList(),
            //     initialIndex: _selectedObligation.index,
            //     onSelect: (i) => setState(() => _selectedObligation = ObligationType.values[i]),
            //   ),
            // ),

            _buildIosSelector(
              label: "Tip Notificare",
              value: _selectedReminder.displayName, // Change from .name to .displayName
              onTap: () => _showCupertinoPicker(
                title: "Notificare",
                items: ReminderType.values.map((e) => e.displayName).toList(), // Place it here
                initialIndex: _selectedReminder.index,
                onSelect: (i) => setState(() => _selectedReminder = ReminderType.values[i]),
              ),
            ),
            // _buildIosSelector(
            //   label: "Tip Notificare",
            //   value: _selectedReminder.name,
            //   onTap: () => _showCupertinoPicker(
            //     title: "Notificare",
            //     items: ReminderType.values.map((e) => e.name).toList(),
            //     initialIndex: _selectedReminder.index,
            //     onSelect: (i) => setState(() => _selectedReminder = ReminderType.values[i]),
            //   ),
            // ),

            _buildIosSelector(
              label: "Data Scadenței",
              value: DateFormat('dd MMMM yyyy').format(_selectedDate),
              onTap: () => _showDatePicker(),
            ),

            _buildFileSelector(
              label: "Încărcare Document",
              fileName: _fileName,
              onTap: _showSelectionDialog,
            ),

            _buildTextField("Notă personală (Opțional)", _noteController, isMultiLine: true, maxLength: 500),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: Colors.blueAccent,
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text("SALVEAZĂ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material( // Material wrap fixes text issues
        color: Colors.transparent,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildPickerHeader("Alege Data"),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(brightness: Brightness.dark),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate,
                    onDateTimeChanged: (val) => setState(() => _selectedDate = val),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCupertinoPicker({required String title, required List<String> items, required int initialIndex, required Function(int) onSelect}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material( // Material wrap fixes text issues
        color: Colors.transparent,
        child: Container(
          height: 250,
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              _buildPickerHeader(title),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 40,
                  onSelectedItemChanged: onSelect,
                  children: items.map((item) => Center(child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 18)))).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text("GATA", style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelector({required String label, String? fileName, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: fileName != null ? Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(fileName ?? "Selectează document...", style: TextStyle(color: fileName != null ? Colors.white : Colors.white24, fontSize: 16)),
                ),
                Icon(fileName != null ? CupertinoIcons.cloud_upload : CupertinoIcons.cloud_upload_fill, color: fileName != null ? Colors.blueAccent : Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIosSelector({required String label, required String value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16))),
                const Icon(CupertinoIcons.chevron_down, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isMultiLine = false, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          placeholder: "Introdu $label",
          placeholderStyle: const TextStyle(color: Colors.white24),
          style: const TextStyle(color: Colors.white),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
          minLines: isMultiLine ? 3 : 1,
          maxLines: isMultiLine ? null : 1,
          maxLength: maxLength,
        ),
        const SizedBox(height: 16),
      ],
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
                const Text("Eroare de validare", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                const SizedBox(height: 15),
                Text(message, style: const TextStyle(color: Color(0xFFC0C0C0), fontSize: 14, decoration: TextDecoration.none, fontWeight: FontWeight.normal), textAlign: TextAlign.center),
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
}
