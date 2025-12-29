import 'dart:async';
import 'package:fixcars/client/screens/ReviewScreen.dart';
import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../shared/screens/chat_screen.dart';
import '../../shared/services/NavigationService.dart';
import '../../shared/services/phone_service.dart';
import '../services/SubmitReviewsService.dart';
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
  // --- PREMIUM DARK COLOR PALETTE ---
  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _darkCard = Color(0xFF141414);
  static const Color _accentSilver = Color(0xFFB0B0B0);
  static const Color _primaryText = Color(0xFFF0F0F0);
  static const Color _secondaryText = Color(0xFFAAAAAA);

  late Future<Map<String, dynamic>> _profileFuture;
  final SupplierProfileService _profileService = SupplierProfileService();
  int currentIndex = 0;
  Timer? _timer;
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

    return Scaffold(
      backgroundColor: _darkBackground,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: LoadingAnimationWidget.newtonCradle(color: _accentSilver, size: 60));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data?['success'] != true) {
            return Center(
                child: Text(
                  snapshot.hasError ? 'Error: ${snapshot.error}' : 'No profile data available',
                  style: const TextStyle(color: Colors.redAccent),
                ));
          }

          final userProfile = profileData?['userProfile'] ?? {};
          final reviews = profileData?['reviews'] ?? {};
          final services = profileData?['services'] ?? {};

          return Stack(
            children: [
              // --- ANIMATED COVER IMAGE ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    key: ValueKey<String>(coverImages.isNotEmpty ? coverImages[currentIndex] : 'default'),
                    height: screenHeight * 0.35,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          coverImages.isNotEmpty
                              ? coverImages[currentIndex]
                              : 'https://www.seat.ps/content/dam/public/seat-website/seat-cars/car-maintenance/article-single-image-maintenance/seat-services-and-repair-maintenance.jpg',
                        ),
                        fit: BoxFit.cover,
                      //  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                      ),
                    ),
                  ),
                ),
              ),

              // --- CUSTOM APP BAR (BACK BUTTON) ---
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: _primaryText, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              // --- MAIN CONTENT CONTAINER ---
              Positioned.fill(
                top: screenHeight * 0.3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: _darkBackground,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userProfile['full_name']?.toUpperCase() ?? 'NAME',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: _primaryText,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  StarRatingDisplay(
                                    score: (reviews['averageRating'] as num?)?.toDouble() ?? 5.0,
                                    reviews: (reviews['totalReviews'] as num?)?.toInt() ?? 0,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Bio Section
                        _buildSectionHeader("DESPRE NOI"),
                        Text(
                          userProfile['bio'] ?? 'Professional services...',
                          style: const TextStyle(color: _secondaryText, height: 1.5, fontSize: 14),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons (Waze, Call, Chat)
                        _buildActionButtons(userProfile),
                        const SizedBox(height: 32),

                        // Services and Brands
                        ServicesGrid(
                          services: (services['services'] as List<dynamic>? ?? [])
                              .map((service) => {
                            'title': service['serviceName']?.toString() ?? 'Service',
                            'description': service['description']?.toString() ?? 'Description',
                          }).toList(),
                          brands: (services['carBrands'] as List<dynamic>? ?? [])
                              .map((brand) => {
                            'name': brand['name']?.toString() ?? 'Brand',
                            'imageUrl': brand['url']?.toString() ?? '',
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Reviews Section
                        ReviewListWidget(
                          supplier_id: widget.userId,
                          reviews: (reviews['reviews'] as List<dynamic>? ?? [])
                              .map((review) => {
                            'name': review['clientName'] ?? 'Anonymous',
                            'rating': review['rating'] ?? 0,
                            'comment': review['comment'] ?? 'No comment',
                            'date': review['created_at'] ?? "recent",
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- PROFILE IMAGE (Floating) ---
              Positioned(
                top: screenHeight * 0.3 - 50,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _darkBackground,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      userProfile['profile_photo'] ?? 'https://via.placeholder.com/150',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: _accentSilver,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> userProfile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildButton(
                icon: Icons.phone_in_talk,
                label: 'SUNĂ ACUM',
                color: _darkCard,
                onPressed: () => CallService.makeCall(
                  context: context,
                  phoneNumber: userProfile['phone']!.toString(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                icon: Icons.near_me,
                label: 'NAVIGARE',
                color: _accentSilver,
                textColor: Colors.black,
                onPressed: () => NavigationService.navigateTo(
                  context: context,
                  latitude: double.tryParse(profileData!['userProfile']['latitude'].toString()) ?? 0.0,
                  longitude: double.tryParse(profileData!['userProfile']['longitude'].toString()) ?? 0.0,
                  locationName: profileData?['userProfile']['business_address']?.toString(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildButton(
          icon: Icons.chat_bubble_outline,
          label: 'DISCUTĂ CU NOI',
          color: _darkCard,
          isFullWidth: true,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(otherUserUuid: profileData!["userProfile"]["user_id"]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    Color textColor = _primaryText,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 54,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20, color: textColor),
        label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class ServicesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> brands;

  const ServicesGrid({Key? key, required this.services, required this.brands}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("MĂRCI SUPORTATE"),
        BrandListHorizontal(brands: brands),
        const SizedBox(height: 24),
        _buildHeader("SERVICII OFERITE"),
        ListView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListTile(
                title: Text(service['title'], style: const TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.bold)),
                subtitle: Text(service['description'], style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13), maxLines: 2),
                trailing: const Icon(Icons.info_outline, color: Color(0xFFB0B0B0), size: 20),
                onTap: () => _showServiceDetails(context, service['title'], service['description']),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
      ),
    );
  }

  void _showServiceDetails(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(description, style: const TextStyle(color: Color(0xFFAAAAAA))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ÎNCHIDE', style: TextStyle(color: Color(0xFFB0B0B0)))),
        ],
      ),
    );
  }
}

class BrandListHorizontal extends StatelessWidget {
  final List<Map<String, dynamic>> brands;
  const BrandListHorizontal({Key? key, required this.brands}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  ApiService.baseMediaUrl + (brand['imageUrl'] ?? ''),
                  width: 40, height: 40,
                  errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, color: Color(0xFFB0B0B0)),
                ),
                const SizedBox(height: 8),
                Text(brand['name'] ?? '', style: const TextStyle(color: Color(0xFF000000), fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ReviewListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> reviews;
  final String supplier_id;
  const ReviewListWidget({required this.reviews, required this.supplier_id});

  @override
  _ReviewListWidgetState createState() => _ReviewListWidgetState();
}

class _ReviewListWidgetState extends State<ReviewListWidget> {
  String formatReviewDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return 'Recent';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("RECENZII", style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(supplierId: widget.supplier_id))),
              child: const Text("VEZI TOT", style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.reviews.take(3).map((review) => Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(review['name'] ?? 'Client', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(formatReviewDate(review['date']?.toString() ?? ''), style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: List.generate(5, (i) => Icon(Icons.star, color: i < (review['rating'] as num).toInt() ? Colors.amber : Colors.white10, size: 14))),
              const SizedBox(height: 8),
              Text(review['comment'] ?? '', style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
            ],
          ),
        )).toList(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.rate_review_outlined, color: Color(0xFFF0F0F0), size: 18),
            label: const Text("LASĂ O RECENZIE", style: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            // onPressed: () => showDialog(context: context, builder: (_) => ReviewPopup(supplierId: widget.supplier_id)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Allows sheet to move up with keyboard
                backgroundColor: Colors.transparent, // Required for custom rounded corners
                builder: (context) => _ReviewBottomSheet(supplierId: widget.supplier_id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReviewBottomSheet extends StatefulWidget {
  final String supplierId;
  const _ReviewBottomSheet({required this.supplierId});

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  // Use the SubmitReviewsService you provided
  final SubmitReviewsService _submitService = SubmitReviewsService();

  // Premium Palette matching your screen
  static const Color _sheetColor = Color(0xFF161616);
  static const Color _inputFill = Color(0xFF202020);
  static const Color _accentSilver = Color(0xFFB0B0B0);
  static const Color _primaryText = Color(0xFFF0F0F0);
  static const Color _secondaryText = Color(0xFFFFFFFF);

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Te rugăm să selectezi o notă.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Correctly calling SubmitReviewsService
      final response = await _submitService.submitReview(
        supplierId: widget.supplierId,
        rating: _selectedRating,
        comment: _commentController.text,
      );

      if (mounted) {
        if (response['success'] == true) {
          Navigator.pop(context); // Close sheet on success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Recenzia a fost trimisă!")),
          );
        } else {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? "Eroare la trimitere.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Eroare de rețea: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet when the keyboard appears
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: _sheetColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar for visual polish
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "LASĂ O RECENZIE",
              style: TextStyle(
                color: _primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Star Rating Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _selectedRating = index + 1),
                  icon: Icon(
                    index < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _selectedRating ? Colors.amber : _accentSilver.withOpacity(0.3),
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Styled TextField
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(color: _secondaryText),
              decoration: InputDecoration(
                hintText: "Spune-ne părerea ta...",
                hintStyle: TextStyle(color: _accentSilver.withOpacity(0.4), fontSize: 14),
                filled: true,
                fillColor: _inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button with Loading State
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryText,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
                    : const Text(
                  "TRIMITE RECENZIA",
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

