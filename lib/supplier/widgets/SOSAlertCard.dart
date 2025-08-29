import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // Add this for Clipboard

import '../../shared/services/NavigationService.dart';
import '../../shared/services/phone_service.dart';
import '../../shared/services/api_service.dart';
import '../services/UpdateRequestService.dart';


class SOSAlertCard extends StatefulWidget {
  final Map<String, dynamic> alertData;

  const SOSAlertCard({required this.alertData, super.key});

  @override
  _SOSAlertCardState createState() => _SOSAlertCardState();
}

class _SOSAlertCardState extends State<SOSAlertCard> {
  String _address = 'Încărcare adresă...';
  String _distance = 'Calculare distanță...';
  bool _isLoading = true;
  Position? _currentPosition;
  bool _isUpdatingStatus = false;
  final RequestService _requestService = RequestService();

  // Helper methods to extract data from the map
  String get status => widget.alertData['status']?.toString() ?? 'pending';
  String get requestId => widget.alertData['id']?.toString() ?? '';
  String get userName => widget.alertData['client_name']?.toString() ?? 'Utilizator Necunoscut';
  String get timeAgo => _getTimeAgo(widget.alertData['created_at']);
  String get description => widget.alertData['reason']?.toString() ?? 'Nicio descriere furnizată';
  String get phoneNumber => widget.alertData['phone_number']?.toString() ?? '';
  String get vehicleInfo => widget.alertData['vehicle_info']?.toString() ?? 'Informații vehicul indisponibile';
  double get latitude => double.tryParse(widget.alertData['latitude']?.toString() ?? '') ?? 0.0;
  double get longitude => double.tryParse(widget.alertData['longitude']?.toString() ?? '') ?? 0.0;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndData();
  }

  Future<void> _initializeLocationAndData() async {
    await _getCurrentLocation();
    if (_currentPosition != null) {
      await Future.wait([
        _getAddressFromCoordinates(),
        _calculateDistance(),
      ]);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          setState(() {
            _distance = 'Permisiune locație refuzată';
            _address = 'Adresă indisponibilă';
          });
          return;
        }
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      setState(() {
        _distance = 'Eroare locație';
        _address = 'Adresă indisponibilă';
      });
    }
  }

  Future<void> _getAddressFromCoordinates() async {
    if (latitude == 0.0 || longitude == 0.0) {
      setState(() => _address = 'Coordonate invalide');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1'),
        headers: {'User-Agent': 'YourAppName/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _address = data['display_name'] ?? 'Adresă indisponibilă');
      } else {
        setState(() => _address = 'Adresă indisponibilă');
      }
    } catch (e) {
      setState(() => _address = 'Eroare adresă');
    }
  }

  Future<void> _calculateDistance() async {
    if (_currentPosition == null || latitude == 0.0 || longitude == 0.0) {
      setState(() => _distance = 'Distanță indisponibilă');
      return;
    }

    try {
      const distance = Distance();
      final km = distance(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(latitude, longitude),
      ) / 1000; // Convert meters to kilometers

      setState(() => _distance = '${km.toStringAsFixed(1)} km');
    } catch (e) {
      setState(() => _distance = 'Eroare distanță');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 6,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/sos1.png', width: 50),
                    const SizedBox(width: 8.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehicleInfo,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                Image.asset('assets/sos2.png', width: 70),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              '$timeAgo  $_distance',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.red),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    _isLoading ? 'Încărcare adresă...' : _address,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (status == 'pending' || status == 'accepted') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _makeCall(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFF9CA3AF), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/phone.png', width: 24),
                          const Text(
                            'Sună',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showOnMap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B5563),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/waze.png', width: 24),
                          const Text(
                            'Arată pe hartă',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
            _buildStatusSection(context),
          ],
        ),
      ),
    );
  }

  void _makeCall(BuildContext context) {
    if (phoneNumber.isNotEmpty) {
      CallService.makeCall(
        context: context,
        phoneNumber: phoneNumber,
        isTestMode: false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Număr de telefon indisponibil')),
      );
    }
  }

  void _showOnMap(BuildContext context) {
    if (latitude != 0.0 && longitude != 0.0) {
      NavigationService.navigateTo(
        context: context,
        latitude: latitude,
        longitude: longitude,
        locationName: _address,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordonate invalide')),
      );
    }
  }

  Widget _buildStatusSection(BuildContext context) {
    switch (status) {
      case 'pending':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdatingStatus ? null : () => _acceptSOSAlert(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUpdatingStatus
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Acceptă Alertă SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdatingStatus ? null : () => _rejectSOSAlert(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7280),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUpdatingStatus
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Respinge Alertă SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      case 'accepted':
        return Column(
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Acceptat de tine',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdatingStatus ? null : () => _completeSOSAlert(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUpdatingStatus
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Marchează ca finalizat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      case 'rejected':
        return Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            const Text(
              'Ai respins această cerere',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case 'expired':
        return Row(
          children: [
            const Icon(Icons.access_time, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Această cerere a expirat',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case 'completed':
        return Row(
          children: [
            const Icon(Icons.verified, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              'Cerere finalizată cu succes',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _acceptSOSAlert(BuildContext context) {
    _showStatusDialog(
      context,
      title: 'Acceptă Alertă SOS',
      content: 'Ești sigur că vrei să accepti această alertă SOS?',
      confirmText: 'Acceptă',
      confirmColor: const Color(0xFFDC2626),
      onConfirm: () => _updateRequestStatus(context, RequestStatus.accepted),
    );
  }

  void _rejectSOSAlert(BuildContext context) {
    _showStatusDialog(
      context,
      title: 'Respinge Alertă SOS',
      content: 'Ești sigur că vrei să respingi această alertă SOS?',
      confirmText: 'Respinge',
      confirmColor: const Color(0xFF6B7280),
      onConfirm: () => _updateRequestStatus(context, RequestStatus.rejected),
    );
  }

  void _completeSOSAlert(BuildContext context) {
    _showStatusDialog(
      context,
      title: 'Finalizează Alertă SOS',
      content: 'Ești sigur că vrei să marchezi această alertă SOS ca finalizată?',
      confirmText: 'Finalizează',
      confirmColor: Colors.blue,
      onConfirm: () => _updateRequestStatus(context, RequestStatus.completed),
    );
  }

  void _showStatusDialog(
      BuildContext context, {
        required String title,
        required String content,
        required String confirmText,
        required Color confirmColor,
        required VoidCallback onConfirm,
      }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: 32,
                  color: Colors.orange.shade700,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Anulează',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(confirmText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateRequestStatus(BuildContext context, RequestStatus newStatus) async {
    if (requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID-ul cererii este invalid')),
      );
      return;
    }

    setState(() => _isUpdatingStatus = true);

    try {
      final response = await _requestService.updateRequestStatus(
        requestId: requestId,
        status: newStatus,
      );

      // Update the local data to reflect the new status
      widget.alertData['status'] = newStatus.value;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statusul a fost actualizat cu succes: ${newStatus.value}')),
      );

      // Trigger a rebuild to show the updated status
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la actualizarea statusului: $e')),
      );
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return 'Timp necunoscut';

    try {
      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(createdDate);

      if (difference.inMinutes < 1) return 'Chiar acum';
      if (difference.inMinutes < 60) return '${difference.inMinutes} min în urmă';
      if (difference.inHours < 24) return '${difference.inHours} ore în urmă';
      return '${difference.inDays} zile în urmă';
    } catch (e) {
      return 'Timp necunoscut';
    }
  }
}
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'dart:convert';
//
// import '../../shared/services/NavigationService.dart';
// import '../../shared/services/phone_service.dart';
//
// class SOSAlertCard extends StatefulWidget {
//   final Map<String, dynamic> alertData;
//
//   const SOSAlertCard({required this.alertData, super.key});
//
//   @override
//   _SOSAlertCardState createState() => _SOSAlertCardState();
// }
//
// class _SOSAlertCardState extends State<SOSAlertCard> {
//   String _address = 'Încărcare adresă...';
//   String _distance = 'Calculare distanță...';
//   bool _isLoading = true;
//   Position? _currentPosition;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeLocationAndData();
//   }
//
//   // Helper methods to extract data from the map
//   String get status => widget.alertData['status']?.toString() ?? 'pending';
//   String get userName => widget.alertData['client_name']?.toString() ?? 'Utilizator Necunoscut';
//   String get timeAgo => _getTimeAgo(widget.alertData['created_at']);
//   String get description => widget.alertData['reason']?.toString() ?? 'Nicio descriere furnizată';
//   String get phoneNumber => widget.alertData['phone_number']?.toString() ?? '';
//   String get vehicleInfo => widget.alertData['vehicle_info']?.toString() ?? 'Informații vehicul indisponibile';
//   double get latitude => double.tryParse(widget.alertData['latitude']?.toString() ?? '') ?? 0.0;
//   double get longitude => double.tryParse(widget.alertData['longitude']?.toString() ?? '') ?? 0.0;
//
//   Future<void> _initializeLocationAndData() async {
//     await _getCurrentLocation();
//     if (_currentPosition != null) {
//       await Future.wait([
//         _getAddressFromCoordinates(),
//         _calculateDistance(),
//       ]);
//     }
//     setState(() => _isLoading = false);
//   }
//
//   Future<void> _getCurrentLocation() async {
//     try {
//       // Check and request location permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
//           setState(() {
//             _distance = 'Permisiune locație refuzată';
//             _address = 'Adresă indisponibilă';
//           });
//           return;
//         }
//       }
//
//       // Get current position
//       _currentPosition = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (e) {
//       setState(() {
//         _distance = 'Eroare locație';
//         _address = 'Adresă indisponibilă';
//       });
//     }
//   }
//
//   Future<void> _getAddressFromCoordinates() async {
//     if (latitude == 0.0 || longitude == 0.0) {
//       setState(() => _address = 'Coordonate invalide');
//       return;
//     }
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1'),
//         headers: {'User-Agent': 'YourAppName/1.0'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() => _address = data['display_name'] ?? 'Adresă indisponibilă');
//       } else {
//         setState(() => _address = 'Adresă indisponibilă');
//       }
//     } catch (e) {
//       setState(() => _address = 'Eroare adresă');
//     }
//   }
//
//   Future<void> _calculateDistance() async {
//     if (_currentPosition == null || latitude == 0.0 || longitude == 0.0) {
//       setState(() => _distance = 'Distanță indisponibilă');
//       return;
//     }
//
//     try {
//       const distance = Distance();
//       final km = distance(
//         LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//         LatLng(latitude, longitude),
//       ) / 1000; // Convert meters to kilometers
//
//       setState(() => _distance = '${km.toStringAsFixed(1)} km');
//     } catch (e) {
//       setState(() => _distance = 'Eroare distanță');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: Colors.white,
//       elevation: 6,
//       margin: const EdgeInsets.all(16.0),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     Image.asset('assets/sos1.png', width: 50),
//                     const SizedBox(width: 8.0),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           userName,
//                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           vehicleInfo,
//                           style: const TextStyle(fontSize: 12, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 Image.asset('assets/sos2.png', width: 70),
//               ],
//             ),
//             const SizedBox(height: 8.0),
//             Text(
//               '$timeAgo  $_distance',
//               style: const TextStyle(color: Colors.grey),
//             ),
//             const SizedBox(height: 16.0),
//             Text(
//               description,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 8.0),
//             Row(
//               children: [
//                 const Icon(Icons.location_pin, color: Colors.red),
//                 const SizedBox(width: 8.0),
//                 Expanded(
//                   child: Text(
//                     _isLoading ? 'Încărcare adresă...' : _address,
//                     style: const TextStyle(fontSize: 14),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16.0),
//             if (status == 'pending' || status == 'accepted') ...[
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () => _makeCall(context),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFFFFFFF),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           side: const BorderSide(color: Color(0xFF9CA3AF), width: 2),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset('assets/phone.png', width: 24),
//                           const Text(
//                             'Sună',
//                             style: TextStyle(
//                               color: Color(0xFF9CA3AF),
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () => _showOnMap(context),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF4B5563),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset('assets/waze.png', width: 24),
//                           const Text(
//                             'Arată pe hartă',
//                             style: TextStyle(
//                               color: Color(0xFFFFFFFF),
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16.0),
//             ],
//             _buildStatusSection(context),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _makeCall(BuildContext context) {
//     if (phoneNumber.isNotEmpty) {
//       CallService.makeCall(
//         context: context,
//         phoneNumber: phoneNumber,
//         isTestMode: false,
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Număr de telefon indisponibil')),
//       );
//     }
//   }
//
//   void _showOnMap(BuildContext context) {
//     if (latitude != 0.0 && longitude != 0.0) {
//       NavigationService.navigateTo(
//         context: context,
//         latitude: latitude,
//         longitude: longitude,
//         locationName: _address,
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Coordonate invalide')),
//       );
//     }
//   }
//
//   Widget _buildStatusSection(BuildContext context) {
//     switch (status) {
//       case 'pending':
//         return Column(
//           children: [
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => _acceptSOSAlert(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFDC2626),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Acceptă Alertă SOS',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => _rejectSOSAlert(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF6B7280), // Gray for reject
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Respinge Alertă SOS',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       case 'accepted':
//         return Column(
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.check_circle, color: Colors.green),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Acceptat de tine',
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Marchează ca finalizat',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       case 'rejected':
//         return Row(
//           children: [
//             const Icon(Icons.cancel, color: Colors.red),
//             const SizedBox(width: 8),
//             const Text(
//               'Ai respins această cerere',
//               style: TextStyle(
//                 color: Colors.red,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         );
//       case 'expired':
//         return Row(
//           children: [
//             const Icon(Icons.access_time, color: Colors.orange),
//             const SizedBox(width: 8),
//             const Text(
//               'Această cerere a expirat',
//               style: TextStyle(
//                 color: Colors.orange,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         );
//       case 'completed':
//         return Row(
//           children: [
//             const Icon(Icons.verified, color: Colors.green),
//             const SizedBox(width: 8),
//             const Text(
//               'Cerere finalizată cu succes',
//               style: TextStyle(
//                 color: Colors.green,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         );
//       default:
//         return const SizedBox.shrink();
//     }
//   }
//
//   void _acceptSOSAlert(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Acceptă Alertă SOS'),
//         content: const Text('Ești sigur că vrei să accepti această alertă SOS?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Anulează'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Alertă SOS acceptată')),
//               );
//             },
//             child: const Text('Acceptă'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _getTimeAgo(String? createdAt) {
//     if (createdAt == null) return 'Timp necunoscut';
//
//     try {
//       final createdDate = DateTime.parse(createdAt);
//       final now = DateTime.now();
//       final difference = now.difference(createdDate);
//
//       if (difference.inMinutes < 1) return 'Chiar acum';
//       if (difference.inMinutes < 60) return '${difference.inMinutes} min în urmă';
//       if (difference.inHours < 24) return '${difference.inHours} ore în urmă';
//       return '${difference.inDays} zile în urmă';
//     } catch (e) {
//       return 'Timp necunoscut';
//     }
//   }
//
//   void _rejectSOSAlert(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Respinge Alertă SOS'),
//         content: const Text('Ești sigur că vrei să respingi această alertă SOS?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Anulează'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Alertă SOS respinsă')),
//               );
//             },
//             child: const Text('Respinge'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF6B7280), // Gray color for reject
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }