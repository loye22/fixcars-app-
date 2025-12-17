import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/CarService.dart';

class AddCarObligationBottomSheet extends StatefulWidget {
  const AddCarObligationBottomSheet({super.key});

  @override
  State<AddCarObligationBottomSheet> createState() => _AddCarObligationBottomSheetState();
}

class _AddCarObligationBottomSheetState extends State<AddCarObligationBottomSheet> {
  final CarService _carService = CarService();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  // Form Fields
  ObligationType _selectedObligation = ObligationType.ITP;
  ReminderType _selectedReminder = ReminderType.LEGAL;
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _docUrlController = TextEditingController();

  // Helper to show iOS Bottom Picker for Enums
  void _showCupertinoPicker({
    required String title,
    required List<String> items,
    required int initialIndex,
    required Function(int) onSelect,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
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
                children: items.map((item) => Center(
                  child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 18)),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C), // Slightly lighter than the background
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                decoration: TextDecoration.none, // Removes yellow line
              )
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
                "GATA",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none, // Removes yellow line
                )
            ),
          ),
        ],
      ),
    );
  }
  // Widget _buildPickerHeader(String title) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     decoration: const BoxDecoration(
  //       color: Color(0xFF2C2C2C),
  //       border: Border(bottom: BorderSide(color: Colors.white10)),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
  //         CupertinoButton(
  //           padding: EdgeInsets.zero,
  //           child: const Text("Gata", style: TextStyle(color: Colors.blueAccent)),
  //           onPressed: () => Navigator.pop(context),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // 1. First, paste your provided method into the state class
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

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final result = await _carService.addCarObligation(
      obligationType: _selectedObligation,
      reminderType: _selectedReminder,
      dueDate: _selectedDate,
      note: _noteController.text,
      documentUrl:  _docUrlController.text,
    );

    // SAFETY CHECK: Ensure the user didn't dismiss the sheet manually
    // while the API request was still flying.
    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success']) {
      Navigator.pop(context, true);
    } else {
      // This uses 'context' internally, so the 'mounted' check above protects it
      _showElegantErrorDialog(result['error'] ?? 'Eroare la adăugare');
    }
  }

  // // 2. Updated Submit logic to call the dialog
  // Future<void> _submit() async {
  //   setState(() => _isSubmitting = true);
  //
  //   try {
  //     final result = await _carService.addCarObligation(
  //       obligationType: _selectedObligation,
  //       reminderType: _selectedReminder,
  //       dueDate: _selectedDate,
  //       note: _noteController.text,
  //       documentUrl: _docUrlController.text,
  //     );
  //
  //     setState(() => _isSubmitting = false);
  //
  //     if (result['success']) {
  //       Navigator.pop(context, true); // Success: Close sheet and refresh
  //     } else {
  //       // CALL YOUR ERROR DIALOG HERE
  //       _showElegantErrorDialog(result['error'] ?? 'A apărut o eroare neașteptată.');
  //     }
  //   } catch (e) {
  //     setState(() => _isSubmitting = false);
  //     _showElegantErrorDialog("Conexiunea cu serverul a eșuat. Verifică internetul.");
  //   }
  // }
  //
  //
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
            // Handle bar
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Adaugă Obligație", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),

            // iOS Style Selectors
            _buildIosSelector(
              label: "Tip Obligație",
              value: _selectedObligation.name,
              onTap: () => _showCupertinoPicker(
                title: "Selectează Tipul",
                items: ObligationType.values.map((e) => e.name).toList(),
                initialIndex: _selectedObligation.index,
                onSelect: (i) => setState(() => _selectedObligation = ObligationType.values[i]),
              ),
            ),

            _buildIosSelector(
              label: "Tip Notificare",
              value: _selectedReminder.name,
              onTap: () => _showCupertinoPicker(
                title: "Notificare",
                items: ReminderType.values.map((e) => e.name).toList(),
                initialIndex: _selectedReminder.index,
                onSelect: (i) => setState(() => _selectedReminder = ReminderType.values[i]),
              ),
            ),

            _buildIosSelector(
              label: "Data Scadenței",
              value: DateFormat('dd MMMM yyyy').format(_selectedDate),
              // onTap: () => showCupertinoModalPopup(
              //   context: context,
              //   builder: (context) => Container(
              //     height: 250,
              //     color: const Color(0xFF1E1E1E),
              //     child: Column(
              //       children: [
              //         _buildPickerHeader("Alege Data"),
              //         Expanded(
              //           child: CupertinoDatePicker(
              //             mode: CupertinoDatePickerMode.date,
              //             initialDateTime: _selectedDate,
              //             onDateTimeChanged: (val) => setState(() => _selectedDate = val),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              onTap: () => showCupertinoModalPopup(
                context: context,
                builder: (context) => Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 300,
                //    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildPickerHeader("Alege Data"),
                        Expanded(
                          child: CupertinoTheme(
                            data: const CupertinoThemeData(
                              brightness: Brightness.dark,
                              // This is the key to changing the picker text color
                              textTheme: CupertinoTextThemeData(
                                dateTimePickerTextStyle: TextStyle(
                                  color: Colors.white, // Changes the text to Red
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                       //       maximumDate: DateTime.now(),
                              initialDateTime: _selectedDate,
                              onDateTimeChanged: (val) => setState(() => _selectedDate = val),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            _buildTextField("URL Document", _docUrlController),
            // _buildTextField("Notă", _noteController),

            _buildTextField(
              "Notă personală (Opțional)",
              _noteController,
              isMultiLine: true, // New parameter
              maxLength: 500,    // Character limit
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: Colors.blueAccent,
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text("SALVEAZĂ", style: TextStyle(fontWeight: FontWeight.bold , color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
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
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
                const Icon(CupertinoIcons.chevron_down, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool isMultiLine = false,
        int? maxLength,
      }) {
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
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),

          // --- Multi-line logic ---
          minLines: isMultiLine ? 3 : 1, // Shows at least 3 lines if it's a note
          maxLines: isMultiLine ? null : 1, // null allows infinite expansion vertically
          keyboardType: isMultiLine ? TextInputType.multiline : TextInputType.text,
          textInputAction: isMultiLine ? TextInputAction.newline : TextInputAction.done,

          // --- Character limit logic ---
          maxLength: maxLength,
          // This styles the "0/500" counter that appears
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  // Widget _buildTextField(String label, TextEditingController controller) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
  //       const SizedBox(height: 8),
  //       CupertinoTextField(
  //         controller: controller,
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  //         placeholder: "Introdu $label",
  //         placeholderStyle: const TextStyle(color: Colors.white24),
  //         style: const TextStyle(color: Colors.white),
  //         decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
  //       ),
  //       const SizedBox(height: 16),
  //     ],
  //   );
  // }
}