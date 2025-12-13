import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';

class GaugeScreen extends StatefulWidget {
  const GaugeScreen({super.key});

  @override
  State<GaugeScreen> createState() => _GaugeScreenState();
}

// Example screen that cycles the percentage for demonstration
class _GaugeScreenState extends State<GaugeScreen> {
  int _targetPercentage = 1;
  int _cycleCount = 0;

  @override
  void initState() {
    super.initState();
    // Use a Ticker to drive periodic updates for demonstration
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    //   _startDemoCycle();
    // });
  }

  void _startDemoCycle() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _cycleCount++;
        _targetPercentage = [10, 55, 80, 25, 95][_cycleCount % 5];
      });
      _startDemoCycle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedSciFiGauge(
          targetPercentage: _targetPercentage,
          key: ValueKey(_targetPercentage), // Key ensures the widget rebuilds and animation restarts
        ),
      ),
    );
  }
}


/// The core widget managing the animation state.
class AnimatedSciFiGauge extends StatefulWidget {
  final int targetPercentage;

  const AnimatedSciFiGauge({super.key, required this.targetPercentage});

  @override
  State<AnimatedSciFiGauge> createState() => _AnimatedSciFiGaugeState();
}

class _AnimatedSciFiGaugeState extends State<AnimatedSciFiGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _percentageAnimation;
  late Animation<Color?> _colorAnimation;
  int _currentPercentage = 0;

  // Gauge configuration constants
  static const double componentSize = 400.0;

  // --- Dynamic Color Logic ---
  Color _getColorForPercentage(int percentage) {
    if (percentage < 25) {
      return Colors.red.shade700; // Red
    } else if (percentage < 50) {
      return Colors.orange.shade700; // Orange
    } else if (percentage < 75) {
      return Colors.yellow.shade700; // Yellow
    } else {
      return Colors.green.shade700; // Green
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // Slightly faster
    );

    // 1. Percentage Animation (Value)
    final targetValue = widget.targetPercentage / 100.0;
    _percentageAnimation = Tween<double>(begin: 0.0, end: targetValue).animate(
      // Smooth stop curve
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() {
      setState(() {
        _currentPercentage = (_percentageAnimation.value * 100).floor();
      });
    });

    // 2. Color Animation (Smooth color transition)
    final startColor = _getColorForPercentage(0); // Start color
    final endColor = _getColorForPercentage(widget.targetPercentage); // End color

    _colorAnimation = ColorTween(
      begin: startColor,
      end: endColor,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );


    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Necessary override for stateful widget using a key in parent.
  // This is where you might handle updates to the target percentage without a key,
  // but using the key rebuilds the state which is simpler here.
  // @override
  // void didUpdateWidget(covariant AnimatedSciFiGauge oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  // }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller, // Rebuilds for both percentage and color
      builder: (context, child) {
        final currentAnimatedPercentage = _percentageAnimation.value;
        final currentAnimatedColor = _colorAnimation.value ?? Colors.red; // Default to red if null

        // --- Subtle Pulse Animation (Opacity/Scale) ---
        final pulseValue = 0.5 + (_controller.value * 0.5); // 0.5 to 1.0 at full percentage
        final scale = 1.0 + (1.0 - math.pow(1.0 - _controller.value, 2)) * 0.02; // Ease-in-out scale

        return Transform.scale(
          scale: scale, // Apply smooth scale animation
          child: SizedBox(
            width: componentSize,
            height: componentSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. ALL CUSTOM DRAWING IN ONE PAINTER
                CustomPaint(
                  painter: UnifiedSciFiGaugePainter(
                    percentage: currentAnimatedPercentage,
                    activeColor: currentAnimatedColor, // Pass the dynamic color
                  ),
                  child: Container(),
                ),

                // 2. Center Content (Text)
                Center(
                  child: Opacity(
                    // Apply opacity animation for a subtle fade-in effect
                    opacity: pulseValue.clamp(0.0, 1.0),
                    child: TextOverlay(
                      currentPercentage: _currentPercentage,
                      color: currentAnimatedColor, // Pass the dynamic color
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
}

// --- Custom Painters (Updated) ---

/// Painter for the stylized diagonal slash over the '0'
class StylizedSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black // Background color for the cut-out
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.15),
      Offset(size.width * 0.75, size.height * 0.85),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// UNIFIED PAINTER: Handles all ticks, arcs, and the needle.
class UnifiedSciFiGaugePainter extends CustomPainter {
  final double percentage; // The animating value (0.0 to 0.70)
  final Color activeColor; // The dynamically animating color

  UnifiedSciFiGaugePainter({required this.percentage, required this.activeColor});

  // Gauge configuration constants (matching the React code)
  static const double startAngleDegrees = 135;
  static const double totalAngleDegrees = 270;
  static const int totalTicks = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Radii values scaled from the React 400x400 SVG to the Flutter size.
    final gaugeRadius = size.width * (120 / 400);
    final innerTickRadius = size.width * (140 / 400);
    final outerTickRadius = size.width * (160 / 400);
    final needleLength = size.width * (140 / 400);

    // Convert angles to radians
    final startAngleRad = startAngleDegrees * math.pi / 180;
    final sweepAngleRad = totalAngleDegrees * math.pi / 180;
    final rect = Rect.fromCircle(center: center, radius: gaugeRadius);

    // --- 1. Background Ring (Dim) ---
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1a1a1a).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40.0;

    canvas.drawCircle(center, gaugeRadius, backgroundPaint);

    // --- 2. Ticks and Markers (Active/Inactive) ---
    for (int i = 0; i <= totalTicks; i++) {
      double tickProgress = i / (totalTicks - 1);
      double tickAngle = startAngleRad + (tickProgress * sweepAngleRad);

      final isActive = tickProgress <= percentage;

      final tickPaint = Paint()
      // Use the dynamic color for active ticks
        ..color = isActive ? activeColor : const Color(0xFF333333)
        ..strokeWidth = isActive ? 3.0 : 2.0
        ..strokeCap = StrokeCap.round
      // Subtle glow filter
        ..maskFilter = isActive ? const MaskFilter.blur(BlurStyle.normal, 2.0) : null;

      // Calculate start and end points of the tick lines
      double startX = center.dx + innerTickRadius * math.cos(tickAngle);
      double startY = center.dy + innerTickRadius * math.sin(tickAngle);

      double endX = center.dx + outerTickRadius * math.cos(tickAngle);
      double endY = center.dy + outerTickRadius * math.sin(tickAngle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        tickPaint,
      );
    }

    // --- 3. Inner Progress Arc (Glow) ---
    final currentArcAngleRad = sweepAngleRad * percentage;

    final arcPaint = Paint()
      ..color = activeColor // Use the dynamic color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.butt
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    canvas.drawArc(
      rect,
      startAngleRad,
      currentArcAngleRad,
      false,
      arcPaint,
    );

    // --- 4. THE NEEDLE (Drawn directly using the calculated angle) ---
    final needleAngleRad = startAngleRad + (percentage * sweepAngleRad);

    // 4a. Needle Line (Main)
    final needlePaint = Paint()
      ..color = activeColor // Use the dynamic color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

    const double needleStartRadius = 20.0;

    double startX = center.dx + needleStartRadius * math.cos(needleAngleRad);
    double startY = center.dy + needleStartRadius * math.sin(needleAngleRad);

    double endX = center.dx + needleLength * math.cos(needleAngleRad);
    double endY = center.dy + needleLength * math.sin(needleAngleRad);

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      needlePaint,
    );

    // 4b. Needle Gradient Trail (Blur)
    final trailPaint = Paint()
      ..color = activeColor.withOpacity(0.3) // Use the dynamic color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    double trailEndRadius = needleLength * 0.7;

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + trailEndRadius * math.cos(needleAngleRad), center.dy + trailEndRadius * math.sin(needleAngleRad)),
      trailPaint,
    );

    // 4c. Needle Tip Glow (use a brighter version of the active color)
    final tipPaint = Paint()..color = activeColor.withAlpha(200);
    canvas.drawCircle(
      Offset(endX, endY),
      3.0,
      tipPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    // --- 5. Center Pivot ---
    final pivotPaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;

    final pivotBorderPaint = Paint()
      ..color = activeColor // Use the dynamic color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 8.0, pivotPaint);
    canvas.drawCircle(center, 8.0, pivotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant UnifiedSciFiGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.activeColor != activeColor;
  }
}


// --- Text Overlay Widget (Updated) ---

class TextOverlay extends StatelessWidget {
  final int currentPercentage;
  final Color color; // New dynamic color parameter
  const TextOverlay({super.key, required this.currentPercentage, required this.color});

  @override
  Widget build(BuildContext context) {
    const String fontFamily = 'monospace'; // Using system monospace

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50,),
        // HEALTH label
        const Text(
          'HEALTH',
          style: TextStyle(
            color: Color(0xFFC0C0C0),
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
            fontFamily: fontFamily,
          ),
        ),
        const SizedBox(height:50),

        // Percentage Display
        Stack(
          alignment: Alignment.center,
          children: [
            // Main animated text
            Text(
              '$currentPercentage%',
              style: TextStyle(
                color: color, // Use the dynamic color
                fontSize: 60,
                fontFamily: fontFamily,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: color.withOpacity(0.6), blurRadius: 15.0), // Dynamic shadow color
                ],
              ),
            ),

            // Stylized Slash Cut-out (optional, can be removed if not needed)
          ],
        ),

        const SizedBox(height: 5),

        // SYSTEM CHECK label
      ],
    );
  }
}
