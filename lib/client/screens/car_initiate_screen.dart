import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../services/BrandService.dart';


// Enum pentru a gestiona culorile themei
enum ColorTheme { Emerald, Gray }

class CarInitiateScreen extends StatefulWidget {
  ColorTheme colorTheme;
   CarInitiateScreen({super.key,   this.colorTheme = ColorTheme.Gray});

  @override
  State<CarInitiateScreen> createState() => _CarInitiateScreenState();
}

class _CarInitiateScreenState extends State<CarInitiateScreen> {
  final BrandService _brandService = BrandService();
  late Future<List<Map<String, dynamic>>> _brandsFuture;

  // Culorile se ajustează în funcție de tema aleasă
  late Color _bgDark;
  late Color _cardColor;
  late Color _accentColor;
  late List<Color> _gradientColors;

  @override
  void initState() {
    super.initState();
    _setColors(widget.colorTheme);
    _loadData();
  }

  // Setează paleta de culori
  void _setColors(ColorTheme theme) {
    if (theme == ColorTheme.Emerald) {
      _bgDark = const Color(0xFF14171A);
      _cardColor = const Color(0xFF1D242B);
      _accentColor = const Color(0xFF1ABC9C); // Emerald Green
      _gradientColors = [const Color(0xFF1ABC9C), const Color(0xFF2ECC71)];
    } else {
      // Gray/Silver Theme
      _bgDark = const Color(0xFF14171A);
      _cardColor = const Color(0xFF1D242B);
      _accentColor = const Color(0xFF95A5A6); // Muted Silver
      _gradientColors = [const Color(0xFF95A5A6), const Color(0xFFBDC3C7)];
    }
  }

  void _loadData() {
    setState(() {
      _brandsFuture = _brandService.fetchBrands();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-set colors in case the theme changed (if this were a dynamic widget)
    _setColors(widget.colorTheme);

    return Scaffold(
      backgroundColor: _bgDark,
      extendBodyBehindAppBar: true,

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _brandsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CupertinoActivityIndicator(color: _accentColor),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final brands = snapshot.data ?? [];
          return Stack(
            children: [
              // A. Animated Background of Logos
              Positioned.fill(
                child: _AnimatedLogoBackground(brands: brands),
              ),

              // B. Gradient Overlay (Focus on the center)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _bgDark.withOpacity(0.9),
                        _bgDark.withOpacity(0.8),
                        _accentColor.withOpacity(0.2),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // C. Main Content (The Floating Card)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logos/t1.png',
                    height: 105,
                    color: Colors.white, // Asigură-te că logo-ul se vede pe fundalul întunecat
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: _cardColor.withOpacity(0.9), // Card translucid
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Titlu
                            const Text(
                              "Adaugă Vehiculul Tău",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Icon Group (Visual Cue)
                            _buildDocumentIcons(),

                            const SizedBox(height: 20),

                            // Propunerea de Valoare
                            Text(
                              "Păstrează toate documentele esențiale asigurare, inspecție tehnică (ITP), etc. într-un singur loc sigur.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Textul de Reminder Evidențiat
                            _buildReminderText(),

                            const SizedBox(height: 32),

                            // Buton CTA
                            _buildCtaButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Widget-uri Ajutătoare ---

  Widget _buildDocumentIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CupertinoTheme(
          data: const CupertinoThemeData(brightness: Brightness.dark),
          child: Icon(CupertinoIcons.doc_text_fill, color: _accentColor, size: 40),
        ),
        const SizedBox(width: 20),
        CupertinoTheme(
          data: const CupertinoThemeData(brightness: Brightness.dark),
          child: Icon(CupertinoIcons.calendar, color: _accentColor.withOpacity(0.8), size: 40),
        ),
        const SizedBox(width: 20),
        CupertinoTheme(
          data: const CupertinoThemeData(brightness: Brightness.dark),
          child: Icon(CupertinoIcons.shield_lefthalf_fill, color: _accentColor.withOpacity(0.6), size: 40),
        ),
      ],
    );
  }

  Widget _buildReminderText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: Icon(CupertinoIcons.bell_fill, color: _accentColor, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Te vom notifica automat înainte ca orice document să expire. Evită penalizările, amenzile sau stresul.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigare către formularul de Adăugare Mașină
            HapticFeedback.heavyImpact();
            print("Începe Urmărirea Documentelor Tapped");
          },
          borderRadius: BorderRadius.circular(12),
          child: const Center(
            child: Text(
              "Începe Urmărirea Documentelor",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoTheme(
              data: const CupertinoThemeData(brightness: Brightness.dark),
              child: Icon(CupertinoIcons.cloud_bolt_rain_fill, size: 48, color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              "Conexiune Întreruptă",
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Nu am putut încărca baza de date auto.",
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _loadData,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accentColor,
                side: BorderSide(color: _accentColor),
              ),
              child: const Text("Reîncercă"),
            )
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// BACKGROUND ANIMATION WIDGETS (Shared between themes)
// ---------------------------------------------------------------------------

class _AnimatedLogoBackground extends StatefulWidget {
  final List<Map<String, dynamic>> brands;
  const _AnimatedLogoBackground({required this.brands});

  @override
  State<_AnimatedLogoBackground> createState() => _AnimatedLogoBackgroundState();
}

class _AnimatedLogoBackgroundState extends State<_AnimatedLogoBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row1 = widget.brands.take(10).toList();
    final row2 = widget.brands.skip(10).take(10).toList();
    final row3 = widget.brands.skip(20).toList();

    return Transform.rotate(
      angle: math.pi / 20,
      child: ScaleTransition(
        scale: const AlwaysStoppedAnimation(1.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScrollingRow(brands: row1, controller: _controller, speedMultiplier: 1.0, reverse: true),
            _ScrollingRow(brands: row2, controller: _controller, speedMultiplier: 0.8),
            _ScrollingRow(brands: row3, controller: _controller, speedMultiplier: 1.2, reverse: true),
          ],
        ),
      ),
    );
  }
}

class _ScrollingRow extends StatelessWidget {
  final List<Map<String, dynamic>> brands;
  final AnimationController controller;
  final double speedMultiplier;
  final bool reverse;

  const _ScrollingRow({
    required this.brands,
    required this.controller,
    this.speedMultiplier = 1.0,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        double offset = controller.value * screenWidth * 2 * speedMultiplier;
        if (reverse) offset *= -1;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...brands, ...brands, ...brands
            ].map((brand) => _buildLogoItem(brand)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildLogoItem(Map<String, dynamic> brand) {
    return Container(
      width: 120,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Opacity(
        opacity: 0.2,
        child: Image.network(
          brand['brand_photo'] ?? '',
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(CupertinoIcons.car_fill, color: Colors.white10, size: 40);
          },
        ),
      ),
    );
  }
}