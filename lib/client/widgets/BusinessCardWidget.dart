import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/material.dart';

class BusinessCardWidget extends StatelessWidget {
  final String businessName;
  final double rating;
  final int reviewCount;
  final String distance;
  final String location;
  final bool isAvailable;
  final String profileUrl;
  final String servicesUrl;
  final String carBrandUrl;

  const BusinessCardWidget({
    required this.businessName,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.location,
    required this.isAvailable,
    required this.profileUrl,
    required this.servicesUrl,
    required this.carBrandUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Top Content Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column (Text Content)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Name + Verification Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              businessName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Image.asset('assets/bluecheck.png', width: 16),
                        ],
                      ),

                      // Rating Row
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Image.asset('assets/review.png', width: 18),
                          SizedBox(width: 4),
                          Text('$rating', style: TextStyle(color: Color(0xFF000000))),
                          Text('($reviewCount recenzii)',
                              style: TextStyle(color: Color(0xFF6B7280))),
                        ],
                      ),

                      // Location Row
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset('assets/locationd.png', height: 16),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text('$distance \u2022 $location',
                                style: TextStyle(color: Color(0xFF6B7280))),
                          ),
                        ],
                      ),

                      // Availability Row
                      SizedBox(height: 4),
                      Row(
                        children: [
                          // Show clock if available, otherwise show red X
                          Image.asset(
                            isAvailable ? 'assets/clock.png' : 'assets/redx.png',
                            width: 20,
                          ),
                          const SizedBox(width: 4),

                          // Text with conditional color
                          Text(
                            isAvailable ? 'Disponibil acum' : 'Nu este disponibil',
                            style: TextStyle(
                              color: isAvailable ? Color(0xFF16A34A) : Color(0xFFFF4141),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )

                    ],
                  ),
                ),

                // Right Column (Images)
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(profileUrl),
                    ),
                    SizedBox(height: 15),
                    Container(
                      width: 50,
                      height: 50,
                      child: Image.network(
                        ApiService.baseMediaUrl + carBrandUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace){
                          print("error $error");
                          return Icon(Icons.error) ;
                        }
                            ,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Card "Cut" Divider
          Container(
            height: 3,
            color: Colors.grey[100],  // Light gray divider
          ),

          // Button Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text(
                  'Contactează',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4B5563),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}