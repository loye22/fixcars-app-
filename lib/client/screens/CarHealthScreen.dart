import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:math' as math;

// Import the CarService
import '../../shared/widgets/AppDialogs.dart';
import '../services/CarService.dart';
import '../widgets/AddCarObligationBottomSheet.dart';
import '../widgets/BusinessSearchBottomSheet.dart';
import '../widgets/EditObligationSheet.dart';
import '../widgets/UpdateCarBottomSheet.dart';

enum ObligationStatus {
  expired,
  expiresSoon,
  updated,
  noData,
}

// enum ReminderType {
//   legal,
//   mechanical,
//   safety,
//   financial,
//   seasonal,
//   other,
// }

class Obligation {
  final String id; // Required for deletion
  final String title;
  final ObligationStatus status;
  final ReminderType reminderType;
  final String documentUrl;
  final DateTime? dueDate;
  final String notes;
  final String obligationType;

  Obligation({
    required this.id,
    required this.title,
    required this.status,
    required this.reminderType,
    this.documentUrl = 'https://dummy-document-link.com',
    this.dueDate,
    this.notes = '',
    this.obligationType = '',
  });
}

class ObligationCard extends StatelessWidget {
  final Obligation obligation;
  final VoidCallback onAddPressed;
  final VoidCallback onDelete; // <--- ADAUGĂ ACEASTA
  final VoidCallback onRefresh; // <--- Add this

  const ObligationCard({
    super.key,
    required this.obligation,
    required this.onAddPressed ,
    required this.onDelete, // <--- ADAUGĂ ACEASTA
    required this.onRefresh, // <--- Add this
  });

  Color _getEffectiveStatusColor() {
    if (obligation.status == ObligationStatus.noData) {
      return Colors.blueGrey.shade700;
    }
    if (obligation.status == ObligationStatus.updated) {
      return Colors.green.shade700;
    }

    if (obligation.dueDate == null) {
      return Colors.orange.shade700;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDueDate = DateTime(obligation.dueDate!.year, obligation.dueDate!.month, obligation.dueDate!.day);
    final differenceInDays = normalizedDueDate.difference(today).inDays;

    if (differenceInDays <= 0) {
      return Colors.red.shade700;
    }
    else if (differenceInDays < 120) {
      return Colors.red.shade700;
    }
    else if (differenceInDays < 183) {
      return Colors.orange.shade700;
    }

    return Colors.green.shade700;
  }

  String _getEffectiveStatusText() {
    if (obligation.status == ObligationStatus.noData) {
      return 'ADĂUGAȚI ACUM';
    }

    if (obligation.dueDate == null || obligation.status == ObligationStatus.updated) {
      return 'VALIDĂ';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDueDate = DateTime(obligation.dueDate!.year, obligation.dueDate!.month, obligation.dueDate!.day);
    final differenceInDays = normalizedDueDate.difference(today).inDays;


    if (differenceInDays <= 0) {
      return 'EXPIRATĂ';
    }
    else if (differenceInDays < 120) {
      return 'EXPIRĂ CURÂND';
    }
    else if (differenceInDays < 183) {
      return 'URMEAZĂ SĂ EXPIRĂ';
    }

    return 'VALIDĂ';
  }

  // Inside ObligationCard class in CarHealthScreen.dart
  void _showEditSheet(BuildContext context) async {
    final bool? refreshNeeded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return EditCarObligationBottomSheet(obligation: obligation);
      },
    );

    // If the sheet returned true, we need to tell the CarHealthScreen to refresh
    if (refreshNeeded == true && context.mounted) {
      // We can use a callback or, if this card is inside a stateful parent,
      // trigger the parent's refresh logic.
      // For now, let's assume you'll add an 'onRefresh' callback to ObligationCard.
      Navigator.pop(context);
      onRefresh();
    }
  }


  void _showBusinessSearch(BuildContext context, ObligationType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite modalului să ocupe 60% din ecran
      backgroundColor: Colors.transparent,
      builder: (context) => BusinessSearchBottomSheet(obligationType: type),
    );
  }



  void _showDetails(BuildContext context) {
    print(obligation.id);
    // TRIGGER: If no data, call the parent function to open Add Sheet
    if (obligation.status == ObligationStatus.noData) {
      onAddPressed();
      return;
    }

    bool isCritical = obligation.status == ObligationStatus.expired ||
        obligation.status == ObligationStatus.expiresSoon;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  Text(
                    obligation.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Divider(color: Colors.grey),

                  _buildDetailRow('Tip Obligație', obligation.obligationType.toUpperCase()),
                  _buildDetailRow('Tip Notificare', obligation.reminderType.toString().split('.').last.toUpperCase()),
                  _buildDetailRow('Data Scadenței', obligation.dueDate != null ? '${obligation.dueDate!.day}/${obligation.dueDate!.month}/${obligation.dueDate!.year}' : 'N/A'),
                  _buildDetailRow('Status', _getEffectiveStatusText(), color: _getEffectiveStatusColor()),
                  // _buildDetailRow('Link Document', obligation.documentUrl, isLink: true),
                  _buildDetailRow(
                    'Document',
                    obligation.documentUrl,
                    isLink: true,
                    onTap: () {
                      if (obligation.documentUrl.isNotEmpty) {
                        _showDocumentSheet(context, obligation.documentUrl);
                      } else {

                        AppDialogs.showConfirmDelete(
                          context: context,
                          title: 'Document Lipsă', // Missing Document
                          message: 'Nu aveți încă documente pentru această obligație. Vă rugăm să mergeți la editare pentru a adăuga documentul.',
                          onConfirm: () {
                            // This code runs when the user clicks "Șterge" (Delete)
                            print('User acknowledged the message or confirmed action');

                            // If you need to navigate the user to the edit screen immediately:
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => EditPage()));
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('Notă:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text(
                    obligation.notes.isNotEmpty ? obligation.notes : 'Fără note suplimentare.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 30),

                  Column(
                    children: [
                      if (isCritical)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: _buildActionButton(
                              context,
                              'GĂSEȘTE SERVICII PENTRU REÎNNOIRE',
                              Icons.store,
                                  (ctx) => _showBusinessSearch(ctx, _mapStringToType(obligation.obligationType)),
                              Colors.green.shade700,

                            ),
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: _buildActionButton(context, 'EDITARE', CupertinoIcons.pencil, _showEditSheet, Colors.blue.shade700),
                            ),
                          ),
                          // Locate the ȘTERGERE button inside your ObligationCard class
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: _buildActionButton(
                                  context,
                                  'ȘTERGERE',
                                  CupertinoIcons.delete,
                                      (ctx) { // <--- Change '()' to '(ctx)' to match the expected type
                                    Navigator.pop(ctx); // Use the local context 'ctx' to close the sheet
                                    onDelete();        // This calls the confirm dialog
                                  },
                                  Colors.red.shade700
                              ),
                            ),
                          ),
                          // Expanded(
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(left: 5.0),
                          //     child: _buildActionButton(context, 'ȘTERGERE', CupertinoIcons.delete, _showDeleteSheet, Colors.red.shade700),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ObligationType _mapStringToType(String type) {
    return ObligationType.values.firstWhere(
          (e) => e.name.toUpperCase() == type.toUpperCase(),
      orElse: () => ObligationType.AIR_FILTER, // Fallback
    );
  }
  void _showDocumentSheet(BuildContext context, String url) {
    String finalUrl = url;

    // State variable to track loading status
    // Since this is inside a function, we use a ValueNotifier to update the UI
    final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

    if (url.toLowerCase().endsWith('.pdf') ||
        url.toLowerCase().endsWith('.doc') ||
        url.toLowerCase().endsWith('.docx')) {
      finalUrl = "https://docs.google.com/viewer?embedded=true&url=${Uri.encodeComponent(url)}";
    }

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Hide the spinner when the page is fully loaded
            isLoading.value = false;
          },
          onWebResourceError: (WebResourceError error) {
            isLoading.value = false;
            debugPrint('WebView Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Drag Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. The WebView
                  WebViewWidget(
                    controller: controller,
                    gestureRecognizers: {
                      Factory<VerticalDragGestureRecognizer>(
                            () => VerticalDragGestureRecognizer()..onUpdate = (_) {},
                      ),
                    },
                  ),
                  // 2. The iOS-style Loading Spinner
                  ValueListenableBuilder<bool>(
                    valueListenable: isLoading,
                    builder: (context, loading, child) {
                      return loading
                          ? const Center(
                        child: CupertinoActivityIndicator(
                          radius: 15,
                          color: CupertinoColors.systemBlue,
                        ),
                      )
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, IconData icon, Function(BuildContext) onPressed, Color color) {
    return ElevatedButton.icon(
      onPressed: () => onPressed(context),
      icon: Icon(icon, size: 20 , color: Colors.white,),
      label: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value, {
        Color? color,
        bool isLink = false,
        VoidCallback? onTap,
      }) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label on the left
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade300)),

          const SizedBox(width: 12), // Space between label and button

          Flexible(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: isLink
                  ? Container(
                // Button styling
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
              //    color: Colors.blue.withOpacity(0.2), // Light blue background
                  borderRadius: BorderRadius.circular(10), // Pill shape
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                ),
                child: Text(
                  "Vezi",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade300,
                  ),
                ),
              )
                  : Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }





  void showDocumentSheet(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadRequest(
                Uri.parse(
                  'https://docs.google.com/gview?embedded=true&url=$url',
                ),
              ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getEffectiveStatusColor();
    bool needsAction = _getEffectiveStatusText() != 'VALIDĂ' && obligation.status != ObligationStatus.noData;

    return Card(
      elevation: 4,
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: needsAction ? BorderSide(color: statusColor, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  obligation.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  _getEffectiveStatusText(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VehicleInfoCard extends StatelessWidget {
  final String model;
  final String year;
  final String vin;
  final String plateLicense;
  final String mileage;
  final String? imageUrl;

  const VehicleInfoCard({
    super.key,
    required this.model,
    required this.year,
    required this.vin,
    required this.plateLicense,
    required this.mileage,
    this.imageUrl,
  });

  Widget _buildStaticCarHeader(String model, double height, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (imageUrl != null && imageUrl!.isNotEmpty)
          Image.network(
            imageUrl!,
            height: height,
            width: width,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                height: height,
                width: width,
                child: const Center(
                  child: Icon(Icons.directions_car, size: 40, color: Colors.white70),
                ),
              );
            },
          )
        else
          SizedBox(
            height: height,
            width: width,
            child: const Center(child: Icon(Icons.directions_car, size: 40, color: Colors.white)),
          ),
        const SizedBox(height: 5),
        Text(
          model,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color ?? Colors.cyan.shade300, size: 22),
          const SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade400, fontWeight: FontWeight.w400),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 15, bottom: 30, left: 16, right: 16),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _buildStaticCarHeader(model, 60, 60),
          ),

          const Text(
            'PANOU VEHICUL',
            style: TextStyle(
              color: Color(0xFF808080),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.8,
            ),
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 35),

          _buildInfoRow(Icons.local_shipping_outlined, 'Model', model, color: Colors.amber.shade400),
          _buildInfoRow(Icons.date_range_outlined, 'An', year, color: Colors.orange.shade300),
          _buildInfoRow(Icons.recent_actors_outlined, 'Nr. Înmatriculare', plateLicense, color: Colors.teal.shade300),
          _buildInfoRow(Icons.vpn_key_outlined, 'VIN', vin, isMonospace: true, color: Colors.indigo.shade300),
          _buildInfoRow(Icons.speed_outlined, 'Kilometraj Actual', mileage, color: Colors.lightBlue.shade300),
        ],
      ),
    );
  }
}

class CarHealthScreen extends StatefulWidget {
  const CarHealthScreen({super.key});

  @override
  State<CarHealthScreen> createState() => _CarHealthScreenState();
}

class _CarHealthScreenState extends State<CarHealthScreen> with SingleTickerProviderStateMixin {

  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _carData;
  List<Obligation> _obligations = [];
  double healthScore = 0.50;

  late AnimationController _animationController;
  late Animation<double> _carScaleAnimation;
  late Animation<double> _gaugeOpacityAnimation;

  final CarService _carService = CarService();


  void _openAddObligationSheet() async {
    final bool? refreshNeeded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCarObligationBottomSheet(),
    );

    if (!mounted) return;

    if (refreshNeeded == true) {
      setState(() {
        _isLoading = true;
      });

      await _loadCarData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obligația a fost salvată cu succes!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _carScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _gaugeOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _loadCarData();
  }

  ObligationStatus _getObligationStatus(DateTime? dueDate) {
    if (dueDate == null) {
      return ObligationStatus.updated;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final differenceInDays = normalizedDueDate.difference(today).inDays;

    if (differenceInDays <= 0) {
      return ObligationStatus.expired;
    }
    else if (differenceInDays < 183) {
      return ObligationStatus.expiresSoon;
    }
    else {
      return ObligationStatus.updated;
    }
  }

  Future<void> _loadCarData() async {
    try {
      final List<Map<String, dynamic>> cars = await _carService.fetchCars();

      if (cars.isNotEmpty) {
        // Taking the first car from the "data" list in your response
        final Map<String, dynamic> car = cars[0];
        List<Obligation> loadedObligations = [];

        // 1. Process Missing Obligations
        if (car['missing_obligations'] != null) {
          final List<dynamic> missing = car['missing_obligations'];
          for (var item in missing) {
            loadedObligations.add(Obligation(
              id: 'missing_${item['obligation_type']}', // Temporary ID for UI
              title: item['obligation_type_display'] ?? 'Obligație Necunoscută',
              status: ObligationStatus.noData,
              reminderType: _mapReminderType(item['obligation_type']),
              notes: 'Lipsesc date pentru această obligație.',
              obligationType: item['obligation_type'] ?? 'ALTELE',
            ));
          }
        }

        // 2. Process Existing Obligations
        if (car['existing_obligations'] != null) {
          final List<dynamic> existing = car['existing_obligations'];
          for (var item in existing) {
            final DateTime? dueDate = item['due_date'] != null ? DateTime.tryParse(item['due_date']) : null;
            final ObligationStatus status = _getObligationStatus(dueDate);

            loadedObligations.add(Obligation(
              id: item['id']?.toString() ?? '', // Important: Capture the ID for deletion
              title: item['obligation_type_display'] ?? item['obligation_type'] ?? 'Obligație',
              status: status,
              reminderType: _mapReminderType(item['obligation_type']),
              dueDate: dueDate,
              documentUrl: item['doc_url'] ?? '',
              notes: item['note'] ?? '',
              obligationType: item['obligation_type'] ?? 'ALTELE',
            ));
          }
        }

        // 3. Calculate Score
        int totalExpected = loadedObligations.length;
        int missingCount = loadedObligations.where((o) => o.status == ObligationStatus.noData).length;
        int criticalCount = loadedObligations.where((o) => o.status == ObligationStatus.expired || o.status == ObligationStatus.expiresSoon).length;

        double calculatedScore = totalExpected > 0
            ? (totalExpected - missingCount - criticalCount) / totalExpected
            : 0.0;

        // 1. Define the order you want (Expired first, No Data last)
        final priority = {
          ObligationStatus.expired: 0,
          ObligationStatus.expiresSoon: 1,
          ObligationStatus.updated: 2,
          ObligationStatus.noData: 3,
        };

        // 2. Sort the list
        loadedObligations.sort((a, b) =>
            priority[a.status]!.compareTo(priority[b.status]!)
        );


        if (mounted) {
          setState(() {
            _carData = car; // Fixed naming: matches your state variable
            _obligations = loadedObligations;
            healthScore = calculatedScore.clamp(0.0, 1.0);
            _isLoading = false;
          });
          _animationController.forward();
        }
      } else {
        if (mounted) setState(() { _errorMessage = 'Nu au fost găsite mașini.'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Eroare: $e'; _isLoading = false; });
    }
  }



  ReminderType _mapReminderType(String? type) {
    if (type == null) return ReminderType.OTHER;
    switch (type.toUpperCase()) {
      case 'RCA':
      case 'CASCO':
      case 'AUTO_TAX':
        return ReminderType.FINANCIAL;
      case 'ITP':
      case 'ROVINIETA':
        return ReminderType.LEGAL;
      case 'TIRES':
        return ReminderType.SEASONAL;
      case 'BRAKE_CHECK':
      case 'FIRE_EXTINGUISHER':
      case 'FIRST_AID_KIT':
        return ReminderType.SAFETY;
      case 'OIL_CHANGE':
      case 'BATTERY':
      case 'WIPERS':
      case 'COOLANT':
      case 'AIR_FILTER':
      case 'CABIN_FILTER':
        return ReminderType.MECHANICAL;
      default:
        return ReminderType.OTHER;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildCarImage({required double height, required double width, String? url}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url != null && url.isNotEmpty
          ? Image.network(
        url,
        height: height,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            height: height,
            width: width,
            child: const Center(
              child: Icon(Icons.directions_car, size: 50, color: Colors.white70),
            ),
          );
        },
      )
          : SizedBox(
        height: height,
        width: width,
        child: const Center(
          child: Icon(Icons.directions_car, size: 50, color: Colors.white70),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(title: const Text('Sănătate Mașină'), backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() { _isLoading = true; _errorMessage = ''; });
                  _loadCarData();
                },
                child: const Text('Reîncearcă'),
              )
            ],
          ),
        ),
      );
    }

    final String carName = '${_carData?['brand_name'] ?? ''} ${_carData?['model'] ?? ''}';
    final String photoUrl = _carData?['brand_photo'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Stare Tehnică', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInvalidCounter(), // Add it here

            SizedBox(
              height: 400,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: _gaugeOpacityAnimation.value,
                        child: AnimatedSciFiGauge(
                          targetPercentage: (healthScore * 100).toInt(),
                          key: ValueKey(healthScore),
                        ),
                      ),
                      Center(
                        child: Opacity(
                          opacity: _carScaleAnimation.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _carScaleAnimation.value.clamp(0.0, 1.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildCarImage(height: 150.0, width: 150.0, url: photoUrl),
                                const SizedBox(height: 5),
                                Text(
                                  carName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            InkWell(
              onTap: () async {
                final bool? refreshNeeded = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const UpdateCarBottomSheet(),
                );

                if (!mounted) return;

                if (refreshNeeded == true) {
                  setState(() {
                    _isLoading = true;
                  });

                  await _loadCarData();

                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: VehicleInfoCard(
                model: carName,
                year: '${_carData?['year'] ?? 'N/A'}',
                vin: _carData?['vin'] ?? 'N/A',
                plateLicense: _carData?['license_plate'] ?? 'N/A',
                mileage: '${_carData?['current_km'] ?? 0} km',
                imageUrl: photoUrl,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Obligații Critice',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(child: SizedBox(width: 8)),
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                    onPressed: _openAddObligationSheet,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey),

            if (_obligations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Nu au fost găsite obligații.", style: TextStyle(color: Colors.grey)),
              )
            else
            // Replace your current map loop with this:
              ..._obligations.map((o) => ObligationCard(
                onRefresh: _loadCarData,
                obligation: o,
                onAddPressed: _openAddObligationSheet,
                onDelete: () {
                  // Check if it's an existing obligation (has a real ID) before trying to delete
                  if (!o.id.contains('missing')) {
                    _confirmDelete(_carData!['id'].toString(), o.id);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Această obligație nu există încă, deci nu poate fi ștearsă.'))
                    );
                  }
                },
              )).toList(),


            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  void _showObligationInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              'Ce sunt obligațiile mașinii?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Obligațiile mașinii sunt toate lucrurile importante pe care trebuie să le faci pentru ca mașina ta să funcționeze corect și să fie în regulă din punct de vedere legal. FixCar te ajută să le urmărești pe toate într-un singur loc.',
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'După ce adaugi obligațiile în FixCar, vei primi notificări din timp, astfel încât să nu uiți nimic important. De exemplu, schimbul de ulei, rotația anvelopelor, inspecția tehnică, asigurarea sau reînnoirea înmatriculării.',
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cu FixCar, rămâi organizat, eviți problemele neașteptate, economisești bani pe termen lung și ai liniștea că mașina ta este mereu îngrijită.',
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('AM ÎNȚELES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  int get _invalidCount => _obligations.where((o) =>
  o.status == ObligationStatus.expired ||
      o.status == ObligationStatus.expiresSoon ||
      o.status == ObligationStatus.noData
  ).length;

  Widget _buildInvalidCounter() {
    if (_invalidCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade900.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.notification_important, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ai $_invalidCount obligații care necesită atenție',
              style: TextStyle(
                color: Colors.red.shade200,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // The Help Icon integrated into the counter
          GestureDetector(
            onTap: _showObligationInfo,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_sharp,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _confirmDelete(String carId, String obligationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirmare ștergere', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Sigur doriți să ștergeți această obligație? Această acțiune este ireversibilă.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _handleDeleteObligation(carId, obligationId);
            },
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteObligation(String carId, String obligationId) async {
    // Show a loading indicator if preferred, or just proceed to API
    final result = await _carService.deleteCarObligation(
      carId: carId,
      obligationId: obligationId,
    );

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          // 1. Remove from the local list immediately for a snappy UI
          _obligations.removeWhere((o) => o.id == obligationId);
        });

        // 2. Refresh the car data to update the Health Score gauge
        await _loadCarData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Obligația a fost ștearsă.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Eroare la ștergerea obligației.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


}

class AnimatedSciFiGauge extends StatefulWidget {
  final int targetPercentage;

  const AnimatedSciFiGauge({super.key, required this.targetPercentage});

  @override
  State<AnimatedSciFiGauge> createState() => _AnimatedSciFiGaugeState();
}

class _AnimatedSciFiGaugeState extends State<AnimatedSciFiGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _percentageAnimation;
  late Animation<Color?> _colorAnimation;
  int _currentPercentage = 0;

  static const double componentSize = 400.0;

  Color _getColorForPercentage(int percentage) {
    if (percentage < 25) {
      return Colors.red.shade700;
    } else if (percentage < 50) {
      return Colors.orange.shade700;
    } else if (percentage < 75) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green.shade700;
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    final targetValue = widget.targetPercentage / 100.0;
    _percentageAnimation = Tween<double>(begin: 0.0, end: targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() {
      setState(() {
        _currentPercentage = (_percentageAnimation.value * 100).floor();
      });
    });

    final startColor = _getColorForPercentage(0);
    final endColor = _getColorForPercentage(widget.targetPercentage);

    _colorAnimation = ColorTween(
      begin: startColor,
      end: endColor,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );


    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentAnimatedPercentage = _percentageAnimation.value;
        final currentAnimatedColor = _colorAnimation.value ?? Colors.red;

        final scale = 1.0 + (1.0 - math.pow(1.0 - _controller.value, 2)) * 0.02;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: componentSize,
            height: componentSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: UnifiedSciFiGaugePainter(
                    percentage: currentAnimatedPercentage,
                    activeColor: currentAnimatedColor,
                  ),
                  child: Container(),
                ),

                Center(
                  child: Opacity(
                    opacity: _controller.value.clamp(0.0, 1.0),
                    child: TextOverlay(
                      currentPercentage: _currentPercentage,
                      color: currentAnimatedColor,
                    ),
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

class UnifiedSciFiGaugePainter extends CustomPainter {
  final double percentage;
  final Color activeColor;

  UnifiedSciFiGaugePainter({required this.percentage, required this.activeColor});

  static const double startAngleDegrees = 135;
  static const double totalAngleDegrees = 270;
  static const int totalTicks = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final gaugeRadius = size.width * (120 / 400);
    final innerTickRadius = size.width * (140 / 400);
    final outerTickRadius = size.width * (160 / 400);
    final needleLength = size.width * (140 / 400);

    final startAngleRad = startAngleDegrees * math.pi / 180;
    final sweepAngleRad = totalAngleDegrees * math.pi / 180;
    final rect = Rect.fromCircle(center: center, radius: gaugeRadius);

    final backgroundPaint = Paint()
      ..color = const Color(0xFF1a1a1a).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40.0;

    canvas.drawCircle(center, gaugeRadius, backgroundPaint);

    for (int i = 0; i <= totalTicks; i++) {
      double tickProgress = i / (totalTicks - 1);
      double tickAngle = startAngleRad + (tickProgress * sweepAngleRad);

      final isActive = tickProgress <= percentage;

      final tickPaint = Paint()
        ..color = isActive ? activeColor : const Color(0xFF333333)
        ..strokeWidth = isActive ? 3.0 : 2.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = isActive ? const MaskFilter.blur(BlurStyle.normal, 2.0) : null;

      double startX = center.dx + innerTickRadius * math.cos(tickAngle);
      double startY = center.dy + innerTickRadius * math.sin(tickAngle);

      double endX = center.dx + outerTickRadius * math.cos(tickAngle);
      double endY = center.dy + outerTickRadius * math.sin(tickAngle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        tickPaint,
      );
    }

    final currentArcAngleRad = sweepAngleRad * percentage;

    final arcPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.butt
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    canvas.drawArc(
      rect,
      startAngleRad,
      currentArcAngleRad,
      false,
      arcPaint,
    );

    final needleAngleRad = startAngleRad + (percentage * sweepAngleRad);

    final needlePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

    const double needleStartRadius = 20.0;

    double startX = center.dx + needleStartRadius * math.cos(needleAngleRad);
    double startY = center.dy + needleStartRadius * math.sin(needleAngleRad);

    double endX = center.dx + needleLength * math.cos(needleAngleRad);
    double endY = center.dy + needleLength * math.sin(needleAngleRad);

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      needlePaint,
    );

    final trailPaint = Paint()
      ..color = activeColor.withOpacity(0.3)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    double trailEndRadius = needleLength * 0.7;

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + trailEndRadius * math.cos(needleAngleRad), center.dy + trailEndRadius * math.sin(needleAngleRad)),
      trailPaint,
    );

    final tipPaint = Paint()..color = activeColor.withAlpha(200);
    canvas.drawCircle(
      Offset(endX, endY),
      3.0,
      tipPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    final pivotPaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;

    final pivotBorderPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 8.0, pivotPaint);
    canvas.drawCircle(center, 8.0, pivotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant UnifiedSciFiGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.activeColor != activeColor;
  }
}

class TextOverlay extends StatelessWidget {
  final int currentPercentage;
  final Color color;
  const TextOverlay({super.key, required this.currentPercentage, required this.color});

  @override
  Widget build(BuildContext context) {
    const String fontFamily = 'monospace';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50,),
        const Text(
          'SĂNĂTATE',
          style: TextStyle(
            color: Color(0xFFC0C0C0),
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
            fontFamily: fontFamily,
          ),
        ),
        const SizedBox(height:50),
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$currentPercentage%',
              style: TextStyle(
                color: color,
                fontSize: 60,
                fontFamily: fontFamily,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: color.withOpacity(0.6), blurRadius: 15.0),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}