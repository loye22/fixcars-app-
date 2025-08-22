import 'package:fixcars/shared/screens/NotificationScreen.dart';
import 'package:fixcars/client/screens/SupplierProfileScreen.dart';
import 'package:fixcars/supplier/screens/AddNewServiceScreen.dart';
import 'package:fixcars/supplier/screens/MyServicesScreen.dart';
import 'package:fixcars/supplier/screens/RequestsScreen.dart';
import 'package:flutter/material.dart';
import '../../shared/services/OneSignalService.dart';
import '../../shared/services/api_service.dart';
import '../services/MarkNotificationAsReadService.dart';
import '../services/SupplierProfileService.dart';
import '../widgets/NotificationItemWidget.dart';

class supplier_home_page extends StatefulWidget {
  const supplier_home_page({super.key});

  @override
  State<supplier_home_page> createState() => _supplier_home_pageState();
}

class _supplier_home_pageState extends State<supplier_home_page> {
  final SupplierProfileSummaryService _profileService =
      SupplierProfileSummaryService();
  Map<String, dynamic>? _supplierData;
  bool _isLoading = true;
  String _errorMessage = '';

  final NotificationService _notificationService = NotificationService();
  @override
  void initState() {
    super.initState();
    _fetchSupplierProfile();
  }

  Future<void> _fetchSupplierProfile() async {
    try {
      final data = await _profileService.fetchSupplierProfile();
      setState(() {
        _supplierData = data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Eroare la încărcarea profilului: $e';
        _isLoading = false;
      });
    }
  }
  Widget _buildStat(
      String number,
      String label,
      String assetImagePath,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Ensures taps are registered
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF212A39),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetImagePath,
              height: 48, // Slightly smaller for better fit
              color: color,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 6),
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // Slightly smaller for better fit
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildStat(
  //   String number,
  //   String label,
  //   String assetImagePath,
  //   Color color,
  //   VoidCallback onTap,
  // ) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       width: 120,
  //       padding: const EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF212A39),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Column(
  //         children: [
  //           Image.asset(assetImagePath, height: 56, color: color),
  //           const SizedBox(height: 6),
  //           Text(
  //             number,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           Text(
  //             label,
  //             style: const TextStyle(color: Colors.white70, fontSize: 12),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(child: Text(_errorMessage)),
      );
    }

    final supplier = _supplierData;
    final isOpen = supplier?['isOpen'] ?? false;
    final supplierID = supplier?['supplierId'] ??"";
    final completedRequests = supplier?['completedRequests']?.toString() ?? '0';
    final averageRating =
        supplier?['reviews']?['averageRating']?.toString() ?? '0';
    final offeredServicesCount =
        supplier?['offeredServicesCount']?.toString() ?? '0';
    final supplierPhotoUrl =
        supplier?['supplierPhotoUrl'] ??
        'https://cdn-icons-png.flaticon.com/512/9203/9203764.png';
    final notifications = supplier?['notifications'] ?? [];
    final String supplierFullName =
        supplier?['supplierFullName'] ?? "404Notfound";
    final businessHours = supplier?['businessHours'] ?? {};

    return Scaffold(

      backgroundColor: Colors.grey[100],
      body:

      SingleChildScrollView(
        child: Column(
          children: [

            Stack(
              clipBehavior: Clip.none,
              children: [
                // Dark Header Background
                Container(
                  height: 420, // Increased height to accommodate quick actions card
                  decoration: const BoxDecoration(
                    color: Color(0xFF161E2D),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 60,
                      left: 20,
                      right: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile + Status
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(supplierPhotoUrl),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bună, $supplierFullName",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              SupplierProfileScreen(userId: supplierID)),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    _showBusinessHoursDialog(context, businessHours, isOpen);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOpen ? Color(0xFF1B4239) : Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/check2.png',
                                          width: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          isOpen ? "În serviciu" : "Închis",
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed to spaceEvenly for better spacing
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add spacing
                                child: _buildStat(
                                  offeredServicesCount,
                                  "Servicii",
                                  "assets/setting3.png",
                                  Colors.blue,
                                      () {
                                    print("Servicii apăsat!");
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: _buildStat(
                                  completedRequests,
                                  "Finalizate",
                                  "assets/check3.png",
                                  Colors.green,
                                      () {
                                    print("Finalizate apăsat!");
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: _buildStat(
                                  averageRating,
                                  "Evaluare",
                                  "assets/rating4.png",
                                  Colors.orange,
                                      () {
                                    print("Evaluare apăsat!");
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Quick Actions Card
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.40, // Adjusted for better visibility
                  // top: MediaQuery.of(context).size.height * 0.45, // Adjusted for better visibility
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              print("SOS button tapped!");
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RequestsScreen()),
                              );
                            },
                            splashColor: Colors.red.withOpacity(0.3),
                            highlightColor: Colors.red.withOpacity(0.1),
                            child: buildQuickAction(
                              "Alertă SOS",
                              "assets/ass2.png",
                              const Color(0xFFFEF2F2),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              print("Serviciile mele tapped!");
                              // Add navigation or action for "Serviciile mele"
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MyServicesScreen()),
                              );
                            },
                            child: buildQuickAction(
                              "Serviciile mele",
                              "assets/ass1.png",
                              const Color(0xFFEFF6FF),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              print("Adaugă serviciu tapped!");
                              // Add navigation or action for "Adaugă serviciu"
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddNewServiceScreen()),
                              );
                            },
                            child: buildQuickAction(
                              "Adaugă serviciu",
                              "assets/ass3.png",
                              const Color(0xFFF0FDF4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 150),

            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:   [
                        Text(
                          "Notificări",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: (){

                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NotificationScreen()),
                            );
                          },
                          child: Text(
                            "Vezi toate",
                            style: TextStyle(color: Colors.blue, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Display notifications from API
                    if (notifications.isNotEmpty)
                      ...notifications
                          .map<Widget>(
                            (notification) => NotificationItemWidget(
                              notification: notification,
                              onTap: () {
                                _markNotificationAsRead(notification["notification_id"]);



                              },
                            ),
                          )
                          .toList()
                    else
                      Text(
                        "Nu există notificări",
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  void _showBusinessHoursDialog(BuildContext context, Map<String, dynamic> businessHours, bool isOpen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Program de lucru",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildBusinessHoursList(businessHours),
                const SizedBox(height: 16),
                Divider(),
                const SizedBox(height: 8),
                Text(
                  "Pentru a modifica programul de lucru, vă rugăm să contactați echipa noastră de support la support@fixcars.ro",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        "Închide",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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


  List<Widget> _buildBusinessHoursList(Map<String, dynamic> businessHours) {
    final days = [
      {'key': 'monday', 'label': 'Luni'},
      {'key': 'tuesday', 'label': 'Marți'},
      {'key': 'wednesday', 'label': 'Miercuri'},
      {'key': 'thursday', 'label': 'Joi'},
      {'key': 'friday', 'label': 'Vineri'},
      {'key': 'saturday', 'label': 'Sâmbătă'},
      {'key': 'sunday', 'label': 'Duminică'},
    ];

    return days.map((day) {
      final dayData = businessHours[day['key']];
      final isClosed = dayData['closed'] ?? true;

      // Format time from "19:00:00" to "19:00"
      String formatTime(String timeString) {
        if (timeString.length >= 5) {
          return timeString.substring(0, 5);
        }
        return timeString;
      }

      final openTime = isClosed ? '' : formatTime(dayData['open'] ?? '');
      final closeTime = isClosed ? '' : formatTime(dayData['close'] ?? '');

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day['label']!,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              isClosed ? 'Închis' : '$openTime - $closeTime',
              style: TextStyle(
                color: isClosed ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  // Quick Action Widget with container background + rounded border
  Widget buildQuickAction(
    String title,
    String assetImagePath,
    Color containerBg,

  )
  {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(assetImagePath, width: 48, height: 48),
            const SizedBox(height: 8),
            Text(
              title.replaceAll(" ", "\n"),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markNotificationAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      print('Notification marked as read successfully');
      // Optionally update UI or show a success message
    } catch (e) {
      print('Error: $e');
      // Optionally show an error message to the user
    }
  }

}


