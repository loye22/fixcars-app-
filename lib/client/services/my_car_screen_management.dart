import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

// Import the CarService
import 'CarService.dart';

enum ObligationStatus {
  expired,
  expiresSoon, // Used for both Red and Orange status
  updated,
  noData,
}

enum ReminderType {
  legal,
  mechanical,
  safety,
  financial,
  seasonal,
  other,
}

class Obligation {
  final String title;
  final ObligationStatus status;
  final ReminderType reminderType;
  final String documentUrl;
  final DateTime? dueDate;
  final String notes;
  final String obligationType;

  Obligation({
    required this.title,
    required this.status,
    required this.reminderType,
    this.documentUrl = 'https://dummy-document-link.com',
    this.dueDate,
    this.notes = '',
    this.obligationType = '',
  });
}

// --- 2. Obligation Card Widget (MODIFIED: Refined Actions Logic) ---

class ObligationCard extends StatelessWidget {
  final Obligation obligation;

  const ObligationCard({super.key, required this.obligation});

  // Helper to determine the effective color based on status and date
  Color _getEffectiveStatusColor() {
    // 1. Handle noData or valid/updated first
    if (obligation.status == ObligationStatus.noData) {
      return Colors.blueGrey.shade700;
    }
    if (obligation.status == ObligationStatus.updated) {
      return Colors.green.shade700;
    }

    // 2. Date-based logic for EXPIRED / EXPIRES SOON
    if (obligation.dueDate == null) {
      return Colors.orange.shade700;
    }

    // Normalize dates to midnight for consistent comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDueDate = DateTime(obligation.dueDate!.year, obligation.dueDate!.month, obligation.dueDate!.day);
    final differenceInDays = normalizedDueDate.difference(today).inDays;

    if (differenceInDays <= 0) { // Expired: Today or in the past
      return Colors.red.shade700;
    }
    // Less than 4 months and > 0 days (Red Status)
    else if (differenceInDays < 120) {
      return Colors.red.shade700;
    }
    // Less than 6 months and >= 4 months (Orange Status)
    else if (differenceInDays < 183) {
      return Colors.orange.shade700;
    }

    // Should default to green if logic is skipped due to updated status from model
    return Colors.green.shade700;
  }

  // Helper to determine the effective status text
  String _getEffectiveStatusText() {
    if (obligation.status == ObligationStatus.noData) {
      return 'ADD NOW';
    }

    if (obligation.dueDate == null || obligation.status == ObligationStatus.updated) {
      return 'VALID';
    }

    // Normalize dates to midnight for consistent comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDueDate = DateTime(obligation.dueDate!.year, obligation.dueDate!.month, obligation.dueDate!.day);
    final differenceInDays = normalizedDueDate.difference(today).inDays;


    if (differenceInDays <= 0) {
      return 'EXPIRED'; // Today or in the past
    }
    // Less than 4 months (Red, marked as 'expiring soon')
    else if (differenceInDays < 120) {
      return 'EXPIRING SOON';
    }
    // Less than 6 months (Orange, marked as 'expires soon')
    else if (differenceInDays < 183) {
      return 'EXPIRES SOON';
    }

    return 'VALID';
  }

  // Placeholder for 'Add Now' bottom sheet
  void _showAddNowSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const Center(
            child: Text('ADD NOW Form (To be implemented)',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        );
      },
    );
  }

  // Placeholder for 'Edit' bottom sheet
  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Center(
            child: Text('EDIT Obligation Form (To be implemented)',
                style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
        );
      },
    );
  }

  // Placeholder for 'Delete' bottom sheet
  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.3,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Center(
            child: Text('DELETE Confirmation (To be implemented)',
                style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
        );
      },
    );
  }

  // NEW: Placeholder for 'Check Best Businesses' bottom sheet
  void _showBusinessSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Center(
            child: Text(
              'Searching for best businesses for ${obligation.title} near you... (To be implemented)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  // MODIFIED: _showDetails to conditionally add the new button
  void _showDetails(BuildContext context) {
    // If no data, show the "Add Now" sheet immediately.
    if (obligation.status == ObligationStatus.noData) {
      _showAddNowSheet(context);
      return;
    }

    // Check for critical status to conditionally display the new button
    bool isCritical = obligation.status == ObligationStatus.expired ||
        obligation.status == ObligationStatus.expiresSoon;


    // For existing data, show the details/action sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65, // Increased size for details
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

                  // Display REQUIRED Details
                  _buildDetailRow('Obligation Type', obligation.obligationType.toUpperCase()),
                  _buildDetailRow('Reminder Type', obligation.reminderType.toString().split('.').last.toUpperCase()),
                  _buildDetailRow('Due Date', obligation.dueDate != null ? '${obligation.dueDate!.day}/${obligation.dueDate!.month}/${obligation.dueDate!.year}' : 'N/A'),
                  _buildDetailRow('Status', _getEffectiveStatusText(), color: _getEffectiveStatusColor()),
                  _buildDetailRow('Document URL', obligation.documentUrl, isLink: true),

                  // Display Note
                  const SizedBox(height: 10),
                  const Text('Note:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text(
                    obligation.notes.isNotEmpty ? obligation.notes : 'No additional notes.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 30),

                  // MODIFIED: ACTION BUTTONS SECTION (Conditional Button)
                  Column(
                    children: [
                      // 1. Critical Action Button (Full Width, only if needed)
                      if (isCritical)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: _buildActionButton(
                              context,
                              'CHECK BEST BUSINESSES TO RENEW',
                              Icons.store,
                              _showBusinessSearch,
                              Colors.green.shade700,
                            ),
                          ),
                        ),

                      // 2. Edit and Delete Row (Split Width)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: _buildActionButton(context, 'EDIT', CupertinoIcons.pencil, _showEditSheet, Colors.blue.shade700),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: _buildActionButton(context, 'DELETE', CupertinoIcons.delete, _showDeleteSheet, Colors.red.shade700),
                            ),
                          ),
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

  // MODIFIED: _buildActionButton removed the inner Expanded to allow for flexible layout
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

  // Re-used helper function for detail rows
  Widget _buildDetailRow(String label, String value, {Color? color, bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade300)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isLink ? Colors.blue.shade300 : (color ?? Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getEffectiveStatusColor();
    // Needs action if not valid and not missing data
    bool needsAction =
        _getEffectiveStatusText() != 'VALID' && obligation.status != ObligationStatus.noData;

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

// --- 3. Vehicle Information Card (Unchanged) ---
// ... (VehicleInfoCard remains the same as previously defined) ...

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
            'VEHICLE DASHBOARD',
            style: TextStyle(
              color: Color(0xFF808080),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.8,
            ),
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 35),

          _buildInfoRow(Icons.local_shipping_outlined, 'Model', model, color: Colors.amber.shade400),
          _buildInfoRow(Icons.date_range_outlined, 'Year', year, color: Colors.orange.shade300),
          _buildInfoRow(Icons.recent_actors_outlined, 'License Plate', plateLicense, color: Colors.teal.shade300),
          _buildInfoRow(Icons.vpn_key_outlined, 'VIN', vin, isMonospace: true, color: Colors.indigo.shade300),
          _buildInfoRow(Icons.speed_outlined, 'Current Mileage', mileage, color: Colors.lightBlue.shade300),
        ],
      ),
    );
  }
}

// --- 4. Main Screen Widget (Stateful for Animation - MODIFIED: Corrected Status Logic) ---

class CarHealthScreen extends StatefulWidget {
  CarHealthScreen({super.key});

  @override
  State<CarHealthScreen> createState() => _CarHealthScreenState();
}

class _CarHealthScreenState extends State<CarHealthScreen> with SingleTickerProviderStateMixin {

  // State variables for API data
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _carData;
  List<Obligation> _obligations = [];
  double healthScore = 0.50; // Default until calculation

  late AnimationController _animationController;
  late Animation<double> _carScaleAnimation;
  late Animation<double> _gaugeOpacityAnimation;

  final CarService _carService = CarService();

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

  // CORRECTED Helper function to map date to ObligationStatus based on the full rules
  ObligationStatus _getObligationStatus(DateTime? dueDate) {
    if (dueDate == null) {
      return ObligationStatus.updated;
    }

    final now = DateTime.now();

    // FIX: Normalize dates to midnight for date-only comparison.
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    // Calculate difference based on normalized dates.
    final differenceInDays = normalizedDueDate.difference(today).inDays;

    // 1. Expired: Today or in the Past (differenceInDays <= 0)
    if (differenceInDays <= 0) {
      return ObligationStatus.expired;
    }

    // 2. Expiring Soon (Red/Orange): Less than 6 months (approx 183 days).
    else if (differenceInDays < 183) {
      return ObligationStatus.expiresSoon;
    }

    // 3. Valid: More than 6 months away.
    else {
      return ObligationStatus.updated;
    }
  }


  Future<void> _loadCarData() async {
    try {
      final List<Map<String, dynamic>> cars = await _carService.fetchCars();

      if (cars.isNotEmpty) {
        final Map<String, dynamic> car = cars[0];

        List<Obligation> loadedObligations = [];

        // 1. Process Missing Obligations
        if (car['missing_obligations'] != null) {
          final List<dynamic> missing = car['missing_obligations'];
          for (var item in missing) {
            loadedObligations.add(Obligation(
              title: item['obligation_type_display'] ?? 'Unknown Obligation',
              status: ObligationStatus.noData,
              reminderType: _mapReminderType(item['obligation_type']),
              notes: 'This obligation is missing data. Please update.',
              obligationType: item['obligation_type'] ?? 'OTHER',
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
              title: item['obligation_type_display'] ?? item['obligation_type'] ?? 'Obligation',
              status: status, // Use calculated status
              reminderType: _mapReminderType(item['obligation_type']),
              dueDate: dueDate,
              documentUrl: item['doc_url'] ?? 'https://dummy-document-link.com',
              notes: item['note'] ?? '',
              obligationType: item['obligation_type'] ?? 'OTHER',
            ));
          }
        }

        int totalExpected = loadedObligations.length;
        int missingCount = loadedObligations.where((o) => o.status == ObligationStatus.noData).length;
        int criticalCount = loadedObligations.where((o) => o.status == ObligationStatus.expired || o.status == ObligationStatus.expiresSoon).length;

        double calculatedScore = totalExpected > 0
            ? (totalExpected - missingCount - criticalCount) / totalExpected
            : 0.0;
        calculatedScore = calculatedScore.clamp(0.0, 1.0);


        if (mounted) {
          setState(() {
            _carData = car;
            _obligations = loadedObligations;
            healthScore = calculatedScore;
            _isLoading = false;
          });
          _animationController.forward();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No cars found.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: $e';
          _isLoading = false;
        });
      }
    }
  }

  ReminderType _mapReminderType(String? type) {
    if (type == null) return ReminderType.other;
    switch (type.toUpperCase()) {
      case 'RCA':
      case 'CASCO':
      case 'AUTO_TAX':
        return ReminderType.financial;
      case 'ITP':
      case 'ROVINIETA':
        return ReminderType.legal;
      case 'TIRES':
        return ReminderType.seasonal;
      case 'BRAKE_CHECK':
      case 'FIRE_EXTINGUISHER':
      case 'FIRST_AID_KIT':
        return ReminderType.safety;
      case 'OIL_CHANGE':
      case 'BATTERY':
      case 'WIPERS':
      case 'COOLANT':
      case 'AIR_FILTER':
      case 'CABIN_FILTER':
        return ReminderType.mechanical;
      default:
        return ReminderType.other;
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
    print("_errorMessage+++++++++++++++++++++++");
    print(_errorMessage);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: const Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(title: const Text('Car Health'), backgroundColor: Colors.transparent),
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
                child: const Text('Retry'),
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
        title: const Text('Car Health Card', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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

            VehicleInfoCard(
              model: carName,
              year: '${_carData?['year'] ?? 'N/A'}',
              vin: _carData?['vin'] ?? 'N/A',
              plateLicense: _carData?['license_plate'] ?? 'N/A',
              mileage: '${_carData?['current_km'] ?? 0} km',
              imageUrl: photoUrl,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Critical Obligations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
                ],
              ),
            ),
            const Divider(color: Colors.grey),

            if (_obligations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No obligations found.", style: TextStyle(color: Colors.grey)),
              )
            else
              ..._obligations.map((o) => ObligationCard(obligation: o)).toList(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}


// --- GAUGE WIDGETS (FROM speedometer.dart - Unchanged) ---

/// The core widget managing the animation state.
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

/// UNIFIED PAINTER: Handles all ticks, arcs, and the needle.
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

    // 1. Background Ring (Dim)
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1a1a1a).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40.0;

    canvas.drawCircle(center, gaugeRadius, backgroundPaint);

    // 2. Ticks and Markers (Active/Inactive)
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

    // 3. Inner Progress Arc (Glow)
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

    // 4. THE NEEDLE
    final needleAngleRad = startAngleRad + (percentage * sweepAngleRad);

    // 4a. Needle Line (Main)
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

    // 4b. Needle Gradient Trail (Blur)
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

    // 4c. Needle Tip Glow
    final tipPaint = Paint()..color = activeColor.withAlpha(200);
    canvas.drawCircle(
      Offset(endX, endY),
      3.0,
      tipPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    // 5. Center Pivot
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


// --- Text Overlay Widget (Unchanged) ---

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
          'HEALTH',
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