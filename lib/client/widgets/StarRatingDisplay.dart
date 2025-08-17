import 'package:flutter/material.dart';

class StarRatingDisplay extends StatelessWidget {
  final double score;
  final int reviews;
  final double size;
  bool hide_reviews ;

   StarRatingDisplay({
    Key? key,
    required this.score,
    required this.reviews,
    this.size = 16.0,
    this.hide_reviews = false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            if (index < score.floor()) {
              return Icon(Icons.star, color: Colors.amber, size: size);
            } else if (index == score.floor() && score % 1 >= 0.5) {
              return Icon(Icons.star_half, color: Colors.amber, size: size);
            } else {
              return Icon(Icons.star_border, color: Colors.amber, size: size);
            }
          }),
        ),
        const SizedBox(width: 4),
        // Score and reviews
        this.hide_reviews ? SizedBox.shrink() :
        Text(
          '${score.toStringAsFixed(1)} • $reviews',
          style: TextStyle(
            fontSize: size * 0.8,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}