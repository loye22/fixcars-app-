import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../shared/services/api_service.dart';
import '../screens/CarHealthScreen.dart';
import '../screens/client_home_page.dart';
import '../services/CarService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/CarService.dart';

class EditCarObligationBottomSheet extends StatefulWidget {
  final Obligation obligation;

  const EditCarObligationBottomSheet({super.key, required this.obligation});

  @override
  State<EditCarObligationBottomSheet> createState() => _EditCarObligationBottomSheetState();
}

class _EditCarObligationBottomSheetState extends State<EditCarObligationBottomSheet> {
  final CarService _carService = CarService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  // Form Fields
  late ObligationType _selectedObligation;
  late ReminderType _selectedReminder;
  late DateTime _selectedDate;
  late TextEditingController _noteController;

  // File State
  File? _selectedFile;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.obligation.notes);
    _selectedDate = widget.obligation.dueDate ?? DateTime.now();
    _selectedObligation = _parseObligationType(widget.obligation.obligationType);
    _selectedReminder = _mapReminderTypeToEnum(widget.obligation.reminderType);
    _loadFreshData();
  }

  Future<void> _loadFreshData() async {
    try {
      final result = await _carService.fetchCurrentCarDetails();
      if (result['success'] == true && mounted) {
        final currentCar = result['data']['current_car'];
        final List existing = currentCar['existing_obligations'] ?? [];
        final freshData = existing.firstWhere(
              (o) => o['id'].toString() == widget.obligation.id,
          orElse: () => null,
        );

        if (freshData != null) {
          setState(() {
            _noteController.text = freshData['note'] ?? '';
            _selectedObligation = _parseObligationType(freshData['obligation_type']);
            if (freshData['due_date'] != null) {
              _selectedDate = DateTime.parse(freshData['due_date']);
            }
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CUSTOM STYLED DIALOG ---

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
                    _pickImage(ImageSource.gallery);
                  },
                ),

                const SizedBox(height: 12),

                // Files Option
                _buildPopupButton(
                  label: "FIȘIERE / ICLOUD",
                  icon: CupertinoIcons.folder,
                  onPressed: () {
                    Navigator.pop(context);
                    _pickFile();
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

  Widget _buildPopupButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.blueAccent),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }

  // --- SELECTION LOGIC ---

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _fileName = image.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  // --- UI RENDER ---

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isLoading
          ? const SizedBox(height: 300, child: Center(child: CupertinoActivityIndicator()))
          : SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10))),
            const Text("EDITARE OBLIGAȚIE", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.grey, height: 30),

            _buildPickerRow("Tip Obligație", _selectedObligation.name, () => _showEnumPicker<ObligationType>(ObligationType.values, _selectedObligation, (val) => setState(() => _selectedObligation = val))),
            _buildPickerRow("Tip Notificare", _selectedReminder.name, () => _showEnumPicker<ReminderType>(ReminderType.values, _selectedReminder, (val) => setState(() => _selectedReminder = val))),
            _buildPickerRow("Data Scadenței", DateFormat('dd/MM/yyyy').format(_selectedDate), _showCupertinoDatePicker),

            TextField(
              controller: _noteController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Note / Detalii"),
            ),
            const SizedBox(height: 20),

            _buildUploadSection(),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: Colors.blue.shade700,
                onPressed: _handleUpdate,
                child: const Text("ACTUALIZEAZĂ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    bool hasUrl = widget.obligation.documentUrl.isNotEmpty && !widget.obligation.documentUrl.contains('dummy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DOCUMENT", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        InkWell(
          onTap: _showSelectionDialog,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _selectedFile != null ? Colors.blueAccent : Colors.white10),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                  color: _selectedFile != null ? Colors.greenAccent : Colors.blueAccent,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile != null ? "Fișier selectat" : (hasUrl ? "Înlocuiește documentul" : "Încarcă document"),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _fileName ?? (hasUrl ? "Există deja un document atașat" : "Alege Sursa"),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- PICKER HELPERS (Same as before for white text) ---

  void _showCupertinoDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _buildPickerWrapper(
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _selectedDate,
          onDateTimeChanged: (val) => setState(() => _selectedDate = val),
        ),
      ),
    );
  }

  void _showEnumPicker<T>(List<T> values, dynamic currentValue, Function(T) onSelected) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _buildPickerWrapper(
        child: CupertinoPicker(
          itemExtent: 35,
          scrollController: FixedExtentScrollController(initialItem: values.indexOf(currentValue)),
          onSelectedItemChanged: (index) => onSelected(values[index]),
          children: values.map((e) => Center(child: Text(e.toString().split('.').last, style: const TextStyle(color: Colors.white, fontSize: 18)))).toList(),
        ),
      ),
    );
  }

  Widget _buildPickerWrapper({required Widget child}) {
    return Container(
      height: 300,
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: const BoxDecoration(color: Color(0xFF2C2C2C), border: Border(bottom: BorderSide(color: Colors.white10))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text("Gata", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(child: CupertinoTheme(data: const CupertinoThemeData(brightness: Brightness.dark), child: child)),
        ],
      ),
    );
  }

  Widget _buildPickerRow(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.grey),
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent)),
  );

  // Future<void> _handleUpdate() async {
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     String? finalDocUrl = widget.obligation.documentUrl;
  //
  //     // 1. Upload new file if selected
  //     if (_selectedFile != null) {
  //       final ApiService apiService = ApiService();
  //       final uploadResult = await apiService.uploadFile2(_selectedFile!);
  //
  //       if (uploadResult['success'] == true) {
  //         // Extract the URL from the response data structure
  //         finalDocUrl = uploadResult['data']['file_url'] ?? uploadResult['data']['url'];
  //       } else {
  //         _showErrorDialog(uploadResult['error'] ?? "Eroare la încărcarea fișierului.");
  //         setState(() => _isLoading = false);
  //         return;
  //       }
  //     }
  //
  //     // 2. Perform the update request
  //     final result = await _carService.updateCarObligation(
  //       obligationId: widget.obligation.id,
  //       obligationType: _selectedObligation,
  //       reminderType: _selectedReminder,
  //       dueDate: _selectedDate,
  //       documentUrl: finalDocUrl,
  //       note: _noteController.text,
  //     );
  //
  //     // 3. Handle response
  //     if (result['success'] == true) {
  //       // Return true so the parent screen knows to refresh the list
  //       Navigator.pop(context, true);
  //     } else {
  //       _showErrorDialog(result['error'] ?? "A apărut o problemă la salvarea datelor.");
  //     }
  //   } catch (e) {
  //     _showErrorDialog("Eroare neașteptată: $e");
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }


  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);

    try {
      String? finalDocUrl = widget.obligation.documentUrl;

      // 1. Upload file if needed
      if (_selectedFile != null) {
        final ApiService apiService = ApiService();
        final uploadResult = await apiService.uploadFile2(_selectedFile!);

        if (uploadResult['success'] == true) {
          finalDocUrl = uploadResult['data']['file_url'] ?? uploadResult['data']['url'];
        } else {
          _showErrorDialog(uploadResult['error'] ?? "Eroare la upload");
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. API Update
      final response = await _carService.updateCarObligation(
        obligationId: widget.obligation.id,
        obligationType: _selectedObligation,
        reminderType: _selectedReminder,
        dueDate: _selectedDate,
        documentUrl: finalDocUrl,
        note: _noteController.text,
      );

      // 3. SUCCESS: Navigate to Home Screen and clear the history ("no go back")
      if (response['success'] == true) {
        if (mounted) {

          Navigator.pop(context, true);
        }
      } else {
        _showErrorDialog(response['error'] ?? "Eroare la actualizare");
      }
    } catch (e) {
      _showErrorDialog("Eroare neașteptată: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
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
                const Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.redAccent, size: 40),
                const SizedBox(height: 20),
                const Text(
                  "EROARE",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(color: Color(0xFFC0C0C0), fontSize: 13, decoration: TextDecoration.none, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                _buildPopupButton(
                  label: "ÎNCHIDE",
                  icon: CupertinoIcons.xmark,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  // void _handleUpdate() {
  //   print("=== FINAL UPDATE DATA ===");
  //   print("Obligation ID: ${widget.obligation.id}");
  //   print("Type: $_selectedObligation");
  //   print("Note: ${_noteController.text}");
  //   print("File: ${_fileName ?? 'Original URL maintained'}");
  //   Navigator.pop(context);
  // }

  ObligationType _parseObligationType(String? type) {
    return ObligationType.values.firstWhere((e) => e.name == type?.toUpperCase(), orElse: () => ObligationType.ITP);
  }

  ReminderType _mapReminderTypeToEnum(dynamic type) {
    final String typeStr = type.toString().split('.').last.toUpperCase();
    return ReminderType.values.firstWhere((e) => e.name == typeStr, orElse: () => ReminderType.OTHER);
  }
}



