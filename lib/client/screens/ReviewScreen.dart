import 'package:fixcars/client/widgets/StarRatingDisplay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ReviewService.dart';
import '../widgets/ReviewPopup.dart';

class ReviewScreen extends StatefulWidget {
  final String supplierId;
  final bool hideReviewButton; // Add this line
  const ReviewScreen({
    required this.supplierId,
    this.hideReviewButton = false,
    Key? key,
  }) : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late ReviewService _reviewService;
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reviews = await _reviewService.fetchReviews(widget.supplierId);
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String formatReviewDate(String? isoDate) {
    try {
      if (isoDate == null) return 'Recent';
      final date = DateTime.parse(isoDate);
      return DateFormat('MMMM d, y').format(date);
    } catch (e) {
      return 'Recent';
    }
  }

  @override
  Widget build(BuildContext context) {
    print(_reviews);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recenzii'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: ListView(
                        children:
                            _reviews
                                .map(
                                  (review) => Container(
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Avatar Circle
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage: NetworkImage(
                                            review['client_photo'] ??
                                                'https://via.placeholder.com/40',
                                          ),
                                          onBackgroundImageError: (
                                            exception,
                                            stackTrace,
                                          ) {
                                            // Handle image loading errors if needed
                                          },
                                        ),
                                        const SizedBox(width: 12.0),
                                        // Review Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    review['client_name'] ??
                                                        'Anonymous',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16.0,
                                                    ),
                                                  ),
                                                  Text(
                                                    formatReviewDate(
                                                      review['created_at']
                                                          ?.toString(),
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8.0),
                                              StarRatingDisplay(
                                                score:
                                                    review['rating'].toDouble(),
                                                reviews: 2,
                                                hide_reviews: true,
                                              ),
                                              const SizedBox(height: 8.0),
                                              Text(
                                                review['comment'] ??
                                                    'No comment',
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                        // _reviews
                        //     .map(
                        //       (review) => Container(
                        //         margin: const EdgeInsets.only(bottom: 16.0),
                        //         child: Column(
                        //           crossAxisAlignment:
                        //               CrossAxisAlignment.start,
                        //           children: [
                        //             Row(
                        //               mainAxisAlignment:
                        //                   MainAxisAlignment.spaceBetween,
                        //               children: [
                        //                 Text(
                        //                   review['client_name'] ??
                        //                       'Anonymous',
                        //                   style: const TextStyle(
                        //                     fontWeight: FontWeight.bold,
                        //                     fontSize: 16.0,
                        //                   ),
                        //                 ),
                        //                 Text(
                        //                   formatReviewDate(
                        //                     review['created_at']
                        //                         ?.toString(),
                        //                   ),
                        //                   style: const TextStyle(
                        //                     color: Colors.grey,
                        //                   ),
                        //                 ),
                        //               ],
                        //             ),
                        //             const SizedBox(height: 8.0),
                        //             StarRatingDisplay(
                        //               score: review['rating'].toDouble(),
                        //               reviews: 2,
                        //               hide_reviews: true,
                        //             ),
                        //             const SizedBox(height: 8.0),
                        //             Text(
                        //               review['comment'] ?? 'No comment',
                        //               style: const TextStyle(
                        //                 fontSize: 14.0,
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //     )
                        //     .toList(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    if (!widget.hideReviewButton)
                      ElevatedButton.icon(
                      icon: Image.asset(
                        'assets/chat.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text('Adaugă recenzie'),
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
                                supplierId: widget.supplierId,
                                onReviewSubmitted:
                                    _fetchReviews, // Pass the callback here
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
