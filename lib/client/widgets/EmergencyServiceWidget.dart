import 'package:fixcars/client/screens/SupplierProfileScreen.dart';
import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/material.dart';

import '../../shared/services/phone_service.dart';
import 'RequestTowingPopup.dart';

class EmergencyServiceCard extends StatelessWidget {
  final String supplierID;
  final String businessName;
  final double rating;
  final int reviewCount;
  final String distance;
  final String location;
  final bool isAvailable;
  final String profileUrl;
  final String servicesUrl;
  final String carBrandUrl;
  final String phoneNr;




  const EmergencyServiceCard({
    required this.businessName,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.location,
    required this.isAvailable,
    required this.profileUrl,
    required this.servicesUrl,
    required this.carBrandUrl,
    required this.supplierID,
    required this.phoneNr,

  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                SupplierProfileScreen(userId: supplierID),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        businessName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset('assets/bluecheck.png', width: 16),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isAvailable ? Color(0xFFDCFCE7) : Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            isAvailable ? 'Deschis acum' : 'Închis',
                            style: TextStyle(
                              color:
                                  isAvailable
                                      ? Color(0xFF15803D)
                                      : Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$distance • $location',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$rating • $reviewCount reviews',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // You can add service chips here if needed
                  // Wrap(
                  //   spacing: 4,
                  //   runSpacing: 4,
                  //   children: [
                  //     Chip(label: Text('Service 1')),
                  //     Chip(label: Text('Service 2')),
                  //   ],
                  // ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Add call functionality here
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4B5563),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: GestureDetector(
                        onTap:
                            () => CallService.makeCall(
                              context: context,
                              phoneNumber: this.phoneNr,
                            ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/phone.png', width: 24),
                              const SizedBox(width: 10),
                              Text(
                                'Sună acum',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      /// immplement the requst fetcher
                      /// // To open the towing service request popup
                      showDialog(
                        context: context,
                        builder: (context) => RequestTowingPopup(
                          supplierId: this.supplierID,
                        ),
                      );

                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(2),
                              child: Text(
                                'Solicită ajutor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


