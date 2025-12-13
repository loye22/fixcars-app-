
import 'package:flutter/material.dart';
import 'dart:math' as math; // Used for PI, cos, sin in CustomPainter

// --- 1. Enumerations and Model ---

enum ObligationStatus {
  expired,
  expiresSoon,
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

    Obligation({
    required this.title,
    required this.status,
    required this.reminderType,
    this.documentUrl = 'https://dummy-document-link.com',
    this.dueDate,
    this.notes = 'This is a sample note about the obligation status and requirement.',
  });
}

// --- 2. Custom Painter for Health Indicator (Futuristic Orange Design) ---

class CircularHealthPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth = 8.0;

  CircularHealthPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2 - strokeWidth / 2;
    double innerRadius = radius * 0.85;

    // 1. Background Ring (Dark Grey)
    Paint backgroundPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 2. Ticks (Segmented markings from image_085f44.png)
    Paint tickPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2.0;

    // Draw 60 ticks around the circle
    for (int i = 0; i < 60; i++) {
      double angle = 2 * math.pi * (i / 60);
      double tickLength = i % 5 == 0 ? 8.0 : 4.0; // Longer ticks every 5th mark

      Offset start = Offset(
        center.dx + innerRadius * 0.95 * math.cos(angle),
        center.dy + innerRadius * 0.95 * math.sin(angle),
      );
      Offset end = Offset(
        center.dx + (innerRadius + tickLength) * math.cos(angle),
        center.dy + (innerRadius + tickLength) * math.sin(angle),
      );

      canvas.drawLine(start, end, tickPaint);
    }

    // 3. Progress Arc (Orange Gradient)
    Paint foregroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA000), Color(0xFFFFEB3B)], // Orange to Yellow gradient
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from the top
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


// --- 3. Obligation Card Widget (Updated with Edit and View Docs in Modal) ---

class ObligationCard extends StatelessWidget {
  final Obligation obligation;

  const ObligationCard({super.key, required this.obligation});

  Color _getStatusColor(ObligationStatus status) {
    switch (status) {
      case ObligationStatus.expired:
        return Colors.red.shade700;
      case ObligationStatus.expiresSoon:
        return Colors.orange.shade700;
      case ObligationStatus.updated:
        return Colors.green.shade700;
      case ObligationStatus.noData:
        return Colors.blueGrey.shade700;
    }
  }

  String _getStatusText(ObligationStatus status) {
    switch (status) {
      case ObligationStatus.expired:
        return 'EXPIRED';
      case ObligationStatus.expiresSoon:
        return 'EXPIRES SOON';
      case ObligationStatus.updated:
        return 'VALID';
      case ObligationStatus.noData:
        return 'ADD STATUS';
    }
  }

  void _showEditOptions(BuildContext context) {
    // Dummy action for Edit
    Navigator.pop(context); // Close details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening Edit form for ${obligation.title}')),
    );
  }

  void _showDocumentation(BuildContext context) {
    // Dummy action for View Documentation
    Navigator.pop(context); // Close details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing document: ${obligation.documentUrl}')),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
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
                  _buildDetailRow('Reminder Type', obligation.reminderType.toString().split('.').last.toUpperCase()),
                  _buildDetailRow('Due Date', obligation.dueDate != null ? '${obligation.dueDate!.day}/${obligation.dueDate!.month}/${obligation.dueDate!.year}' : 'N/A'),
                  _buildDetailRow('Status', _getStatusText(obligation.status), color: _getStatusColor(obligation.status)),
                  _buildDetailRow('Document URL', obligation.documentUrl, isLink: true),
                  const SizedBox(height: 10),
                  const Text('Notes:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text(
                    obligation.notes,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 30),

                  // Action buttons row (Edit & View Documentation)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(context, 'EDIT', Icons.edit, _showEditOptions, Colors.blue.shade700),
                      _buildActionButton(context, 'VIEW DOCS', Icons.file_copy, _showDocumentation, Colors.teal.shade700),
                    ],
                  ),

                  if (obligation.status != ObligationStatus.updated && obligation.status != ObligationStatus.noData)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Simulating renewal for ${obligation.title}')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getStatusColor(obligation.status),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'RENEW NOW',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, String text, IconData icon, Function(BuildContext) onPressed, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: ElevatedButton.icon(
          onPressed: () => onPressed(context),
          icon: Icon(icon, size: 20),
          label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

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
    Color statusColor = _getStatusColor(obligation.status);
    bool needsAction =
        obligation.status == ObligationStatus.expired || obligation.status == ObligationStatus.expiresSoon;

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
              // Status Indicator Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  _getStatusText(obligation.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (needsAction) ...[
                const SizedBox(width: 10),
                // Renew Now Button (Small version on the main card)
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Renewing ${obligation.title} now...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Renew Now',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// --- 4. Main Screen Widget (Updated with Car Model and Health Indicator) ---

class CarHealthScreen extends StatelessWidget {
  CarHealthScreen({super.key});

  final String carModel = 'BMW i8 Concept'; // Car model variable added

  final List<Obligation> _obligations =   [
    Obligation(
      title: 'ITP (Technical Inspection)',
      status: ObligationStatus.updated,
      reminderType: ReminderType.legal,
      dueDate: DateTime(2026, 10, 25),
    ),
    Obligation(
      title: 'RCA Insurance (Liability)',
      status: ObligationStatus.expiresSoon,
      reminderType: ReminderType.financial,
      dueDate: DateTime(2025, 12, 31),
      notes: 'RCA must be renewed before the end of the year to avoid a lapse in coverage.',
    ),
    Obligation(
      title: 'CASCO Insurance (Collision)',
      status: ObligationStatus.expired,
      reminderType: ReminderType.financial,
      dueDate: DateTime(2024, 11, 1),
    ),
    Obligation(
      title: 'Rovinieta (Road Toll)',
      status: ObligationStatus.updated,
      reminderType: ReminderType.legal,
      dueDate: DateTime(2026, 6, 15),
    ),
    Obligation(
      title: 'Oil Change',
      status: ObligationStatus.expiresSoon,
      reminderType: ReminderType.mechanical,
      dueDate: DateTime(2025, 11, 20),
    ),
    Obligation(
      title: 'Winter Tires Switch',
      status: ObligationStatus.noData,
      reminderType: ReminderType.seasonal,
      notes: 'The law mandates winter tires during the cold season. Please add switch status.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const double healthScore = 0.70; // 70% to match the indicator image

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


            // --- 2. Car Image (BMW Placeholder) ---
            const SizedBox(height: 20),
            _buildCarImage(),

            const SizedBox(height: 30),
            // --- 3. Obligations List Title ---
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

            // --- 4. Obligations List ---
            ..._obligations.map((o) => ObligationCard(obligation: o)).toList(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }


  Widget _buildCarImage() {
    // A placeholder for a dark-colored sports car logo
    const String dummyCarImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/BMW_logo_%28gray%29.svg/2048px-BMW_logo_%28gray%29.svg.png';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),

      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          dummyCarImageUrl,
          height: 250,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              height: 150,
              width: 250,
              child: Center(
                child: Text('Car Image (BMW Placeholder)', style: TextStyle(color: Colors.white70)),
              ),
            );
          },
        ),
      ),
    );
  }
}


// --- 5. Main Application Entry Point ---

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Health App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          color: Colors.transparent,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800), // Orange for primary buttons
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        useMaterial3: true,
      ),
      home: CarHealthScreen(),
    );
  }
}

