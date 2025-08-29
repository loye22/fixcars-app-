///RequestsScreen
/// LocationDetailsCard()

import 'package:fixcars/supplier/widgets/LocationDetailsCard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../shared/services/GetRequestsService.dart';
import '../widgets/SOSAlertCard.dart';
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final GetRequestsService _requestsService = GetRequestsService();
  List<dynamic> _services = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final services = await _requestsService.getRequestsList();

      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Eroare la încărcarea serviciilor: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'ALERTĂ SOS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Asistență urgentă necesară',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _services.isEmpty
          ? Center(child: Text('Nu există servicii disponibile'))
          : SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ..._services.map((service) => SOSAlertCard(alertData: service)).toList(),
          ],
        ),
      ),
    );
  }
}
// import 'package:fixcars/supplier/widgets/LocationDetailsCard.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import '../widgets/SOSAlertCard.dart';
//
// class RequestsScreen extends StatelessWidget {
//   const RequestsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Text(
//               'ALERTĂ SOS',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 20.0,
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 2),
//             Text(
//               'Asistență urgentă necesară',
//               style: TextStyle(
//                 fontSize: 14.0,
//                 color: Colors.white.withOpacity(0.9),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.red[700],
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 8,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(
//             bottom: Radius.circular(16),
//           ),
//         ),
//       ),
//
//      backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SOSAlertCard(),
//            // LocationDetailsCard()
//
//
//
//           ],
//         ),
//       ),
//     );
//   }
// }
