import 'package:fixcars/client/widgets/StarRatingDisplay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ReviewService.dart';
import '../services/SubmitReviewsService.dart'; // Ensure this path is correct
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewScreen extends StatefulWidget {
  final String supplierId;
  final bool hideReviewButton;

  const ReviewScreen({
    required this.supplierId,
    this.hideReviewButton = false,
    Key? key,
  }) : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // --- PREMIUM THEME COLORS ---
  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _sheetColor = Color(0xFF161616); // Slightly lighter for contrast
  static const Color _inputFill = Color(0xFF202020);
  static const Color _accentSilver = Color(0xFFB0B0B0);
  static const Color _primaryText = Color(0xFFF0F0F0);
  static const Color _secondaryText = Color(0xFFFFFFFF);

  late ReviewService _reviewService;
  final SubmitReviewsService _submitReviewsService = SubmitReviewsService(); // Initialized here
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _reviewService = ReviewService();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reviews = await _reviewService.fetchReviews(widget.supplierId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showModernReviewSheet() {
    double selectedRating = 5.0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: _sheetColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'SCRIE O RECENZIE',
                        style: TextStyle(
                          color: _primaryText,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rating Bar
                      RatingBar.builder(
                        initialRating: 5,
                        minRating: 1,
                        itemSize: 40,
                        unratedColor: Colors.white10,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                        onRatingUpdate: (rating) => selectedRating = rating,
                      ),

                      const SizedBox(height: 24),

                      // Text Field
                      TextField(
                        controller: commentController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Spune-ne părerea ta...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                          filled: true,
                          fillColor: _inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                            if (commentController.text.trim().isEmpty) return;

                            setSheetState(() => isSubmitting = true); // Set loading inside sheet

                            final response = await _submitReviewsService.submitReview(
                              supplierId: widget.supplierId,
                              rating: selectedRating.toInt(),
                              comment: commentController.text.trim(),
                            );

                            if (response['success']) {
                              Navigator.pop(context); // Close sheet
                              _fetchReviews(); // Reload list
                            } else {
                              setSheetState(() => isSubmitting = false); // Stop loading on error
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response['error'] ?? 'Eroare')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            disabledBackgroundColor: Colors.white24,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                              : const Text('TRIMITE', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios , color: Colors.white,),
          onPressed: () {
            Navigator.pop(context); // Go back to previous screen
          },
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A1A),
        centerTitle: true,
        title: const Text(
          'RECENZII CLIENȚI',
          style: TextStyle(color: _primaryText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
      ),
      body: _isLoading
          ? Center(child: LoadingAnimationWidget.newtonCradle(color: _accentSilver, size: 60))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _reviews.length,
              itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
            ),
          ),
          if (!widget.hideReviewButton) _buildFixedAddButton(),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(review['client_photo'] ?? 'https://via.placeholder.com/150'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (review['client_name'] ?? 'Anonim').toUpperCase(),
                  style: const TextStyle(color: _primaryText, fontWeight: FontWeight.w800, fontSize: 11),
                ),
                const SizedBox(height: 4),
                StarRatingDisplay(
                  score: (review['rating'] as num).toDouble(),
                  reviews: 0, size: 10, hide_reviews: true,
                ),
                const SizedBox(height: 8),
                Text(
                  review['comment'] ?? '',
                  style: const TextStyle(color: _secondaryText, fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedAddButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _showModernReviewSheet,
          child: const Text('ADAUGĂ RECENZIE', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

