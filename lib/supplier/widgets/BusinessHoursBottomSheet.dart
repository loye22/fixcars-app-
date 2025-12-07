import 'package:fixcars/supplier/services/BusinessHourService.dart';
import 'package:flutter/material.dart';

class BusinessHoursBottomSheet extends StatefulWidget {
  const BusinessHoursBottomSheet({super.key});

  @override
  State<BusinessHoursBottomSheet> createState() => _BusinessHoursBottomSheetState();
}

class _BusinessHoursBottomSheetState extends State<BusinessHoursBottomSheet> {
  Map<String, dynamic>? businessHours;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessHours();
  }

  Future<void> _loadBusinessHours() async {
    try {
      final service = BusinessHourService();
      final data = await service.getBusinessHours();

      if (!mounted) return; // <- important: stop if widget is disposed

      setState(() {
        businessHours = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        businessHours = null; // or show error
      });
      print('Error fetching business hours: $e');
    }
  }

  // Future<void> _loadBusinessHours() async {
  //   final service = BusinessHourService();
  //   final data = await service.getBusinessHours();
  //   if (mounted) {
  //     setState(() {
  //       businessHours = data;
  //       isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time_filled, color: Color(0xFF1E88E5), size: 28),
              SizedBox(width: 12),
              Text(
                'Program de Lucru',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildBusinessHoursList(businessHours),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Închide',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBusinessHoursList(Map<String, dynamic>? data) {
    if (data == null) return [];
    final List<Widget> widgets = [];
    data.forEach((day, info) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(day[0].toUpperCase() + day.substring(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(info['closed'] ? 'Închis' : '${info['open']} - ${info['close']}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ));
    });
    return widgets;
  }
}
