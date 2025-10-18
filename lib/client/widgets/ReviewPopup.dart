
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/SubmitReviewsService.dart';

class ReviewPopup extends StatefulWidget {
  final String supplierId;
  final VoidCallback? onReviewSubmitted; // Add this

  const ReviewPopup({Key? key, required this.supplierId , this.onReviewSubmitted}) : super(key: key);

  @override
  _ReviewPopupState createState() => _ReviewPopupState();
}

class _ReviewPopupState extends State<ReviewPopup> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  final SubmitReviewsService _submitReviewsService = SubmitReviewsService();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _showCustomToast(BuildContext context, String message, bool isSuccess) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _CustomToast(
        message: message,
        isSuccess: isSuccess,
        onDismiss: () {
          overlayEntry?.remove();
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Automatically remove the toast after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    final response = await _submitReviewsService.submitReview(
      supplierId: widget.supplierId,
      rating: _rating.toInt(),
      comment: _reviewController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (response['success']) {
      _showCustomToast(context, 'Recenzie trimisă cu succes!', true);
      widget.onReviewSubmitted?.call(); // Call the callback here
      Navigator.of(context).pop();
    } else {
      _showCustomToast(context, response['error'] ?? 'Eroare la trimiterea recenziei', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildPopupContent(context),
    );
  }

  Widget _buildPopupContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05), // Responsive padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView( // Allow scrolling to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min, // Minimize column height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8), // Space for close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scrie o Recenzie',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.05, // Responsive font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Responsive spacing
            Text(
              'Evaluare',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Center(
              child: RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              'Recenzia Ta',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Împărtășește-ți experiența...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Anulează',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _canSubmit() && !_isSubmitting ? _submitReview : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Trimite Recenzia',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildPopupContent(BuildContext context) {
  //   return Container(
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Stack(
  //       children: [
  //         Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const SizedBox(height: 8), // Space for close button
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 const Text(
  //                   'Scrie o Recenzie',
  //                   style: TextStyle(
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 IconButton(
  //                   icon: const Icon(Icons.close, color: Colors.grey),
  //                   onPressed: () => Navigator.of(context).pop(),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 16),
  //             const Text(
  //               'Evaluare',
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Center(
  //               child: RatingBar.builder(
  //                 initialRating: _rating,
  //                 minRating: 1,
  //                 direction: Axis.horizontal,
  //                 allowHalfRating: false,
  //                 itemCount: 5,
  //                 itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
  //                 itemBuilder: (context, _) => const Icon(
  //                   Icons.star,
  //                   color: Colors.amber,
  //                 ),
  //                 onRatingUpdate: (rating) {
  //                   setState(() {
  //                     _rating = rating;
  //                   });
  //                 },
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             const Text(
  //               'Recenzia Ta',
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             TextField(
  //               controller: _reviewController,
  //               maxLines: 4,
  //               decoration: InputDecoration(
  //                 hintText: 'Împărtășește-ți experiența...',
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(8),
  //                   borderSide: const BorderSide(color: Colors.grey),
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(8),
  //                   borderSide: const BorderSide(color: Colors.grey),
  //                 ),
  //               ),
  //               onChanged: (value) => setState(() {}), // Update state when text changes
  //             ),
  //             const SizedBox(height: 24),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.end,
  //               children: [
  //                 TextButton(
  //                   onPressed: () => Navigator.of(context).pop(),
  //                   child: const Text(
  //                     'Anulează',
  //                     style: TextStyle(color: Colors.grey),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 16),
  //                 ElevatedButton(
  //                   onPressed: _canSubmit() && !_isSubmitting
  //                       ? _submitReview
  //                       : null,
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.blue,
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                   ),
  //                   child: _isSubmitting
  //                       ? const SizedBox(
  //                     width: 20,
  //                     height: 20,
  //                     child: CircularProgressIndicator(
  //                       color: Colors.white,
  //                       strokeWidth: 2,
  //                     ),
  //                   )
  //                       : const Text(
  //                     'Trimite Recenzia',
  //                     style: TextStyle(color: Colors.white),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  bool _canSubmit() {
    return _rating > 0 && _reviewController.text.trim().isNotEmpty;
  }
}

class _CustomToast extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;

  const _CustomToast({
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
  });

  @override
  _CustomToastState createState() => _CustomToastState();
}

class _CustomToastState extends State<_CustomToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Automatically reverse the animation before dismissing
    Future.delayed(const Duration(seconds: 2, milliseconds: 700), () {
      _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}