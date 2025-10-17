import 'dart:async';
import 'package:fixcars/client/screens/ReviewScreen.dart';
import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../shared/screens/chat_screen.dart';
import '../../shared/services/NavigationService.dart';
import '../../shared/services/phone_service.dart';
import '../services/SupplierProfileService.dart';
import '../widgets/ReviewPopup.dart';
import '../widgets/StarRatingDisplay.dart';
import 'package:intl/intl.dart';

class SupplierProfileScreen extends StatefulWidget {
  final String userId;

  const SupplierProfileScreen({super.key, required this.userId});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  final SupplierProfileService _profileService = SupplierProfileService();
  int currentIndex = 0;
  // late Timer _timer;
  Timer? _timer; // Make this nullable
  List<String> coverImages = [];
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.fetchSupplierProfile(userId: widget.userId);
    _profileFuture.then((data) {
      if (data['success'] == true) {
        setState(() {
          profileData = data['data'];
          coverImages = (profileData?['coverPhotos'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();
          // Start timer only if we have cover images
          if (coverImages.isNotEmpty) {
            _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
              setState(() {
                currentIndex = (currentIndex + 1) % coverImages.length;
              });
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data?['success'] != true) {
            return Center(
              child: Text(
                snapshot.hasError ? 'Error: ${snapshot.error}' : 'No profile data available',
                style: const TextStyle(fontSize: 16),
              ));
              }

              final userProfile = profileData?['userProfile'] ?? {};
            final reviews = profileData?['reviews'] ?? {};
            final services = profileData?['services'] ?? {};

              return Stack(
              clipBehavior: Clip.none,
              children: [
                /// --- BACK COVER IMAGE (changes every 2s) ---
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      key: ValueKey<String>(coverImages.isNotEmpty ? coverImages[currentIndex] : 'default'),
                      width: double.infinity,
                      height: screenHeight * 0.3,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            coverImages.isNotEmpty
                                ? coverImages[currentIndex]
                                : 'https://www.seat.ps/content/dam/public/seat-website/seat-cars/car-maintenance/article-single-image-maintenance/seat-services-and-repair-maintenance.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Image.asset('assets/back.png', width: 40, height: 40),
                        ),

                        // Review button
                        // IconButton(
                        //   onPressed: () => print("Review button pressed"),
                        //   icon: Image.asset(
                        //     'assets/review2.png',
                        //     width: 40,
                        //     height: 40,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),

                /// --- WHITE PROFILE DATA CONTAINER ---
                Positioned(
                  top: screenHeight * 0.25,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: screenWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 150),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width - 200, // subtract the SizedBox(150) padding
                                    child: Text(
                                      userProfile['full_name'] ?? 'John Doe',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Color(0xFF1F2937),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis, // add ... if too long
                                      maxLines: 2, // allow wrapping into 2 lines
                                      softWrap: true,
                                    ),
                                  ),

                                  StarRatingDisplay(
                                    score: (reviews['averageRating'] as num?)?.toDouble() ?? 5.0,
                                    reviews: (reviews['totalReviews'] as num?)?.toInt() ?? 195,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            userProfile['bio'] ?? 'Professional auto mechanic with over 10 years of experience...',
                            style: const TextStyle(color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons
                          Column(
                            children: [
                              Row(
                                children: [
                                  // Call Now button
                                  Expanded(

                                    child: ElevatedButton.icon(
                                      icon: Image.asset(
                                        'assets/phone2.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                      label: const Text(
                                        'Sună acum',
                                        style: TextStyle(
                                          color: Color(0xFF374151),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE5E7EB),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => CallService.makeCall(
                                        context: context,
                                        phoneNumber: userProfile['phone']!.toString(),
                                      ),

                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Go Now button
                                  Expanded(
                                    child: ElevatedButton(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset('assets/waze.png', width: 30),
                                          const SizedBox(width: 10),
                                          const Text('Vizitați-ne acum'),
                                        ],
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4B5563),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: ()
                                      => NavigationService.navigateTo(
                                        context: context,
                                        latitude: double.tryParse(profileData!['userProfile']['latitude'].toString()) ?? 0.0,
                                        longitude: double.tryParse(profileData!['userProfile']['longitude'].toString()) ?? 0.0,
                                        locationName: profileData?['userProfile']['business_address']?.toString(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Chat with Mechanic button
                              ElevatedButton.icon(
                                icon: Image.asset(
                                  'assets/chat.png',
                                  width: 24,
                                  height: 24,
                                ),
                                label: const Text('Discută cu noi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD1D5DB),
                                  foregroundColor: const Color(0xFF374151),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  print(profileData);

                                  String otherUserUuid = profileData!["userProfile"]["user_id"];
                                  String otherUserName = profileData!["userProfile"]["full_name"];
                                  String profile_photo = profileData!["userProfile"]["user_id"];

                                  print("otherUserUuid $otherUserUuid");
                                  print("otherUserName $otherUserName");
                                  print("profile_photo $profile_photo");

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                      otherUserUuid: otherUserUuid,),
                                    ),
                                  );

                                },
                              ),
                            ],
                          ),

                          // Services Grid with Car Brands
                          /// here
                          ServicesGrid(
                            services: (services['services'] as List<dynamic>? ?? [])
                                .map((service) => {
                              'title': service['serviceName']?.toString() ?? 'Service',  // Convert to string
                              'description': service['description']?.toString() ?? 'Description',
                            })
                                .toList(),
                            brands: (services['carBrands'] as List<dynamic>? ?? [])
                                .map((brand) => {
                              'name': brand['name']?.toString() ?? 'Brand',
                              'imageUrl': brand['url']?.toString() ?? '',
                            })
                                .toList(),
                          ),

                          const SizedBox(height: 20),

                          // Reviews
                          ReviewListWidget(
                            supplier_id: widget.userId,
                            reviews: (reviews['reviews'] as List<dynamic>? ?? [])
                                .map((review) => {
                              'name': review['clientName'] ?? 'Anonymous',
                              'rating': review['rating'] ?? 0,
                              'comment': review['comment'] ?? 'No comment',
                              'date': review['created_at'] ?? "recent", // API doesn't provide date
                            })
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                /// --- PROFILE IMAGE ---
                Positioned(
                  top: screenHeight * 0.2,
                  left: 40,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundImage: NetworkImage(
                        userProfile['profile_photo'] ??
                            'https://d1gymyavdvyjgt.cloudfront.net/drive/images/uploads/headers/ws_cropper/1_0x0_790x520_0x520_car-service-checklist.jpg',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
      ),
    );
  }
}

class ServicesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> brands;

  const ServicesGrid({
    Key? key,
    required this.services,
    required this.brands,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Suportăm următoarele mărci auto',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        BrandListHorizontal(
          brands: brands,
        ),
        const SizedBox(height: 10),
        const Text(
          'Servicii oferite',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            final title = service['title']?.toString() ?? 'Service';
            final description = service['description']?.toString() ?? 'Description';


            return GestureDetector(
              onTap: () => _showServiceDetails(context, title, description),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _showServiceDetails(
      BuildContext context,
      String title,
      String description,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: SingleChildScrollView(child: Text(description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandListHorizontal extends StatelessWidget {
  final List<Map<String, dynamic>> brands;  // Changed from String to dynamic

  const BrandListHorizontal({Key? key, required this.brands}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          // CHANGES HERE - convert to string with null safety
          final name = brand['name']?.toString() ?? '';
          final imageUrl = brand['imageUrl']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      ApiService.baseMediaUrl + imageUrl,  // Now using the converted string
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 30),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return LoadingAnimationWidget.threeArchedCircle(color: Colors.white, size: 24);

                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,  // Now using the converted string
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ReviewListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> reviews;
  final String supplier_id ;

  const ReviewListWidget({required this.reviews , required this.supplier_id});

  @override
  _ReviewListWidgetState createState() => _ReviewListWidgetState();
}

class _ReviewListWidgetState extends State<ReviewListWidget> {
  String formatReviewDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMMM d, y').format(date);
    } catch (e) {
      return 'Recent';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recenzii recente',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("vezi toate"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReviewScreen(supplierId: widget.supplier_id)),
                  );


                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ...widget.reviews.map((review) => Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      review['name'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      formatReviewDate(review['date']?.toString() ?? ''),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (review['rating'] as num).toInt()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.yellow,
                      size: 20.0,
                    );
                  }),
                ),
                const SizedBox(height: 8.0),
                Text(
                    review['comment'] ?? 'No comment',
                    style: const TextStyle(fontSize: 14.0)
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 16.0),
          ElevatedButton.icon(
            icon: Image.asset('assets/rating.png', width: 34, height: 34),
            label: const Text('Lasă-ne o recenzie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD1D5DB),
              foregroundColor: const Color(0xFF374151),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => ReviewPopup(
                  supplierId: widget.supplier_id,


                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


