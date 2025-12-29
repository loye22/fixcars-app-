import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../services/BrandService.dart';
// NOU: Importă CarService
import '../services/CarService.dart';
import 'CarLoadingDecisionScreen.dart';


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

  // NOU: Metodă pentru afișarea Bottom Sheet-ului (Stil Cupertino)
  void _showAddCarBottomSheet(BuildContext context) {
    HapticFeedback.lightImpact(); // Feedback haptic iOS la apăsare
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        // Învelim în Material pentru a permite utilizarea widget-urilor din Material Design
        // (cum ar fi Image.network) și pentru a menține consistența temei întunecate,
        // dar conținutul intern este Cupertino.
        return Material(
          color: Colors.transparent, // Face fundalul transparent
          child: Padding(
            // Ajustează padding-ul pentru a ridica formularul deasupra tastaturii
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _AddCarBottomSheet(
              brandService: _brandService,
              bgDark: _bgDark,
              accentColor: _accentColor,
              gradientColors: _gradientColors,
            ),
          ),
        );
      },
    );
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
                  // Logo-ul aplicației
                  Image.asset(
                    'assets/logos/t1.png',
                    height: 105,
                    color: Colors.white, // Asigură-te că logo-ul se vede pe fundalul întunecat
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ClipRRect( // 1. Clip the blur effect to the border radius
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter( // 2. Apply the blur filter
                          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                          child: Container(
                            padding: const EdgeInsets.all(32.0),
                            decoration: BoxDecoration(
                              // 3. Keep opacity low (0.1 to 0.3) for the glassy feel
                              color:Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              // 4. A subtle white border makes the edges "catch the light"
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                _buildDocumentIcons(),
                                const SizedBox(height: 20),
                                Text(
                                  "Păstrează toate documentele esențiale într-un singur loc sigur.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9), // Higher opacity for readability
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildReminderText(),
                                const SizedBox(height: 32),
                                _buildCtaButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  // Center(
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  //     child: Container(
                  //       padding: const EdgeInsets.all(32.0),
                  //       decoration: BoxDecoration(
                  //         color: _cardColor.withOpacity(0.9), // Card translucid
                  //         borderRadius: BorderRadius.circular(20),
                  //         border: Border.all(color: Colors.white.withOpacity(0.1)),
                  //         boxShadow: [
                  //           BoxShadow(
                  //             color: Colors.black.withOpacity(0.4),
                  //             blurRadius: 30,
                  //             offset: const Offset(0, 15),
                  //           ),
                  //         ],
                  //       ),
                  //       child: Column(
                  //         mainAxisSize: MainAxisSize.min,
                  //         crossAxisAlignment: CrossAxisAlignment.stretch,
                  //         children: [
                  //           // Titlu
                  //           const Text(
                  //             "Adaugă Vehiculul Tău",
                  //             textAlign: TextAlign.center,
                  //             style: TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 24,
                  //               fontWeight: FontWeight.bold,
                  //               letterSpacing: 0.5,
                  //             ),
                  //           ),
                  //           const SizedBox(height: 12),
                  //
                  //           // Icon Group (Visual Cue)
                  //           _buildDocumentIcons(),
                  //
                  //           const SizedBox(height: 20),
                  //
                  //           // Propunerea de Valoare
                  //           Text(
                  //             "Păstrează toate documentele esențiale asigurare, inspecție tehnică (ITP), etc. într-un singur loc sigur.",
                  //             textAlign: TextAlign.center,
                  //             style: TextStyle(
                  //               color: Colors.white.withOpacity(0.7),
                  //               fontSize: 15,
                  //               height: 1.4,
                  //             ),
                  //           ),
                  //           const SizedBox(height: 24),
                  //
                  //           // Textul de Reminder Evidențiat
                  //           _buildReminderText(),
                  //
                  //           const SizedBox(height: 32),
                  //
                  //           // Buton CTA
                  //           _buildCtaButton(),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
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
      // Removed fixed height to allow for text scaling,
      // or use constraints for a "minimum" height.
      constraints: const BoxConstraints(minHeight: 56),
      width: double.infinity, // Ensures it fills the available width
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
      child: InkWell(
        onTap: () => _showAddCarBottomSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          // Added padding so text never touches the edges
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: Text(
              "Începe Urmărirea Documentelor",
              textAlign: TextAlign.center, // Center text if it wraps
              style: TextStyle(
                color: Colors.black87,
                // Use a slightly smaller base size or keep 16
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
              // Added overflow handling
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
  // Widget _buildCtaButton() {
  //   return Container(
  //     height: 56,
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(12),
  //       gradient: LinearGradient(
  //         colors: _gradientColors,
  //         begin: Alignment.centerLeft,
  //         end: Alignment.centerRight,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: _accentColor.withOpacity(0.5),
  //           blurRadius: 20,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: InkWell(
  //       onTap: () {
  //         // ACȚIUNE ACTUALIZATĂ: Arată bottom sheet (stil iOS)
  //         _showAddCarBottomSheet(context);
  //       },
  //       borderRadius: BorderRadius.circular(12),
  //       child:  Center(
  //         child: Text(
  //           "Începe Urmărirea Documentelor",
  //           style: TextStyle(
  //             color: Colors.black87,
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //             letterSpacing: 0.8,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
// NOU: WIDGET PENTRU FORMULARUL DE ADAUGARE A MAȘINII (BOTTOM SHEET - STIL IOS)
// ---------------------------------------------------------------------------

class _AddCarBottomSheet extends StatefulWidget {
  final BrandService brandService;
  final Color bgDark;
  final Color accentColor;
  final List<Color> gradientColors;

  const _AddCarBottomSheet({
    required this.brandService,
    required this.bgDark,
    required this.accentColor,
    required this.gradientColors,
  });

  @override
  State<_AddCarBottomSheet> createState() => _AddCarBottomSheetState();
}

class _AddCarBottomSheetState extends State<_AddCarBottomSheet> {
  // SERVICES
  final CarService _carService = CarService(); // NOU: Instanța CarService

  // Form State
  String? _selectedBrandId;
  String _model = '';
  int? _year;
  String? _licensePlate;
  String? _vin;
  int? _currentKm;
  DateTime? _lastKmUpdatedAt;

  // UI State
  bool _isLoading = false;
  Map<String, List<String>> _fieldErrors = {}; // Pentru erorile de validare de la API

  // Data
  late Future<List<Map<String, dynamic>>> _brandsFuture;

  @override
  void initState() {
    super.initState();
    _brandsFuture = widget.brandService.fetchBrands();
    // Setează data KM la azi ca valoare inițială obligatorie
    _lastKmUpdatedAt = DateTime.now();
  }

  // Logica de validare: butonul e activ doar când CÂMPURILE OBLIGATORII sunt completate
  bool get _isFormValid {
    return _selectedBrandId != null &&
        _model.isNotEmpty &&
        _year != null &&
        _currentKm != null &&
        _lastKmUpdatedAt != null;
  }

  // NOU: Metodă de apel API
  Future<void> _addCar() async {
    if (!_isFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _fieldErrors = {}; // Resetare erori la începutul cererii
    });

    // Construiește corpul cererii
    final String lastKmDate = _lastKmUpdatedAt!.toIso8601String().substring(0, 10); // Format YYYY-MM-DD

    try {
      final response = await _carService.addCar(
        brandId: _selectedBrandId!,
        model: _model,
        year: _year!,
        currentKm: _currentKm!,
        lastKmUpdatedAt: lastKmDate,
        licensePlate: _licensePlate,
        vin: _vin,
      ); //

      if (response['success'] == true) {
        // Succes
        Navigator.pop(context); // Închide bottom sheet


        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => CarLoadingDecisionScreen(),
          ),
        );

        //_showSuccessNotification('Mașina adăugată: ${_model} (${_year})!');
      } else {
        // Erori de Validare (Dublicate VIN/License Plate sau câmpuri lipsă)
        if (response.containsKey('fieldErrors') && response['fieldErrors'] is Map) {
          setState(() {
            _fieldErrors = Map<String, List<String>>.from(response['fieldErrors'].map((k, v) => MapEntry(k, List<String>.from(v))));
          });
          // Afișează o notificare de eroare generală, erorile specifice pe câmpuri
          // vor fi gestionate în `_buildCupertinoTextField`
          _showErrorNotification('Eroare de validare: verificați câmpurile.');
        } else {
          // Eroare Generală (Server, Conexiune)
          _showErrorNotification(response['error'] ?? 'Eroare necunoscută la adăugarea mașinii.');
        }
      }
    } catch (e) {
      // Eroare Neașteptată
      _showErrorNotification('Eroare neașteptată. Reîncercați.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Metodă de afișare a notificărilor (Stil iOS)
  void _showSuccessNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: widget.accentColor,
        )
    );
  }

  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: CupertinoColors.systemRed,
        )
    );
  }


  // Metodă de afișare a Date Picker-ului (Stil Cupertino)
  Future<void> _selectDate(BuildContext context) async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250.0,
        padding: const EdgeInsets.only(top: 6.0),
        // Fundalul se ajustează pentru modul Dark/Light al sistemului, dar culoarea e forțată
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // Toolbar cu butonul Done/Gata
            Container(
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey5)),
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Gata', style: TextStyle(color: widget.accentColor)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
                initialDateTime: _lastKmUpdatedAt ?? DateTime.now(),
                mode: CupertinoDatePickerMode.date,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    _lastKmUpdatedAt = newDate;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Metodă de afișare a Brand Picker-ului (Stil Cupertino)
  void _showBrandPicker(List<Map<String, dynamic>> brands) {
    int initialIndex = brands.indexWhere((b) => b['brand_id'] == _selectedBrandId);
    initialIndex = initialIndex == -1 ? 0 : initialIndex; // Default la primul item

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250.0,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              // Toolbar cu butonul Done/Gata
              Container(
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey5)),
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Gata', style: TextStyle(color: widget.accentColor)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 40.0,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedBrandId = brands[index]['brand_id'];
                      // S-a selectat o marcă, elimină eventualele erori de câmp
                      _fieldErrors.remove('brand_id');
                    });
                  },
                  children: brands.map((brand) {
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Afișează logo-ul mărcii
                          Image.network(
                            brand['brand_photo'] ?? '',
                            width: 20,
                            height: 20,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                                CupertinoIcons.car_fill,
                                size: 20,
                                color: CupertinoColors.systemGrey
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            brand['brand_name'] ?? '',
                            style: const TextStyle(color: CupertinoColors.label),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      // Designul iOS pentru sheets are colțuri rotunjite (dar nu la fel de mari)
      decoration: BoxDecoration(
        color: widget.bgDark, // Păstrăm culoarea de fundal a temei
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bara de drag & close (opțional, pentru aspect iOS)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            Text(
              "Adaugă o Mașină Nouă",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 1. Selecția Mărcii (Brand Selection - Stil iOS)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _brandsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CupertinoActivityIndicator(color: widget.accentColor));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildErrorState('Eroare la încărcarea mărcilor auto.');
                }

                final List<Map<String, dynamic>> brands = snapshot.data!;
                return _buildBrandSelectionField(brands);
              },
            ),
            _buildErrorText(_fieldErrors['brand_id']),
            const SizedBox(height: 15),

            // 2. Model (Cupertino TextField)
            _buildCupertinoTextField(
              label: 'Model',
              onChanged: (value) => setState(() { _model = value; _fieldErrors.remove('model'); }),
              fieldError: _fieldErrors['model'],
            ),
            const SizedBox(height: 15),

            // 3. Anul (Cupertino TextField)
            _buildCupertinoTextField(
              label: 'Anul',
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() { _year = int.tryParse(value); _fieldErrors.remove('year'); }),
              fieldError: _fieldErrors['year'],
            ),
            const SizedBox(height: 15),

            // 4. KM (Cupertino TextField)
            _buildCupertinoTextField(
              label: 'Kilometrajul Actual',
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() { _currentKm = int.tryParse(value); _fieldErrors.remove('current_km'); }),
              fieldError: _fieldErrors['current_km'],
            ),
            const SizedBox(height: 15),

            // 5. Data Ultima Actualizare KM (Cupertino Date Picker)
            _buildDatePickerField(),
            _buildErrorText(_fieldErrors['last_km_updated_at']),
            const SizedBox(height: 15),

            // 6. Placă de Înmatriculare (Cupertino TextField - Optional)
            _buildCupertinoTextField(
              label: 'Placă de Înmatriculare',
              onChanged: (value) => setState(() { _licensePlate = value.isEmpty ? null : value; _fieldErrors.remove('license_plate'); }),
              isOptional: true,
              fieldError: _fieldErrors['license_plate'],
            ),
            const SizedBox(height: 15),

            // 7. VIN (Cupertino TextField - Optional)
            _buildCupertinoTextField(
              label: 'VIN / Serie Șasiu',
              onChanged: (value) => setState(() { _vin = value.isEmpty ? null : value; _fieldErrors.remove('vin'); }),
              isOptional: true,
              fieldError: _fieldErrors['vin'],
            ),
            const SizedBox(height: 30),

            // 8. Butonul de Adăugare (Cupertino Button)
            _buildAddCarButton(),
          ],
        ),
      ),
    );
  }

  // --- Widget Builders (Cupertino Style) ---

  Widget _buildBrandSelectionField(List<Map<String, dynamic>> brands) {
    final selectedBrand = brands.firstWhere(
          (b) => b['brand_id'] == _selectedBrandId,
      orElse: () => {'brand_name': 'Selectează Marca *', 'brand_photo': null},
    );

    // Verifică dacă există eroare pentru brand_id
    final bool hasError = _fieldErrors.containsKey('brand_id');

    return GestureDetector(
      onTap: _isLoading ? null : () => _showBrandPicker(brands),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          // Stil iOS-like pentru câmpul de selecție
          color: CupertinoColors.systemGrey5.resolveFrom(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: hasError ? CupertinoColors.systemRed : widget.accentColor.withOpacity(0.3)
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.network(
                  selectedBrand['brand_photo'] ?? '',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      CupertinoIcons.car_fill,
                      size: 24,
                      color: CupertinoColors.systemGrey3
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  selectedBrand['brand_name'] ?? 'Selectează Marca *',
                  style: TextStyle(
                    color: _selectedBrandId == null ? CupertinoColors.systemGrey : Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Icon(CupertinoIcons.chevron_down, size: 16, color: CupertinoColors.systemGrey)
          ],
        ),
      ),
    );
  }

  Widget _buildCupertinoTextField({
    required String label,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool isOptional = false,
    List<String>? fieldError, // NOU: pentru afișarea erorilor
  }) {
    final displayPlaceholder = isOptional ? '$label (Opțional)' : '$label *';
    final bool hasError = fieldError != null && fieldError.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          onChanged: (value) {
            onChanged(value);
          },
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
          placeholder: displayPlaceholder,
          placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
          style: const TextStyle(color: CupertinoColors.white, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5.resolveFrom(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: hasError ? CupertinoColors.systemRed : widget.accentColor.withOpacity(0.3)
            ),
          ),
          cursorColor: widget.accentColor,
          readOnly: _isLoading,
        ),
        if (hasError) _buildErrorText(fieldError),
      ],
    );
  }

  Widget _buildDatePickerField() {
    // Verifică dacă există eroare pentru data
    final bool hasError = _fieldErrors.containsKey('last_km_updated_at');

    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(
                  color: hasError ? CupertinoColors.systemRed : widget.accentColor.withOpacity(0.3)
              ),
              borderRadius: BorderRadius.circular(10),
              color: CupertinoColors.systemGrey5.resolveFrom(context).withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Wrap the label in Expanded to allow text wrapping
                Expanded(
                  child: Text(
                    'Data Ultima Actualizare KM *',
                    style: TextStyle(color: widget.accentColor, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10), // 2. Add a gap so text doesn't touch
                // 3. Wrap the value in Flexible to handle tight spaces
                Flexible(
                  child: Text(
                    _lastKmUpdatedAt == null
                        ? 'Selectează'
                        : '${_lastKmUpdatedAt!.day}.${_lastKmUpdatedAt!.month}.${_lastKmUpdatedAt!.year}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _lastKmUpdatedAt == null ? CupertinoColors.systemGrey : CupertinoColors.white,
                      fontWeight: _lastKmUpdatedAt == null ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          )
          // Container(
          //   padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          //   decoration: BoxDecoration(
          //     border: Border.all(
          //         color: hasError ? CupertinoColors.systemRed : widget.accentColor.withOpacity(0.3)
          //     ),
          //     borderRadius: BorderRadius.circular(10),
          //     color: CupertinoColors.systemGrey5.resolveFrom(context).withOpacity(0.1),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Text(
          //         'Data Ultima Actualizare KM *',
          //         style: TextStyle(color: widget.accentColor, fontSize: 16),
          //       ),
          //       Text(
          //         _lastKmUpdatedAt == null
          //             ? 'Selectează'
          //             : '${_lastKmUpdatedAt!.day}.${_lastKmUpdatedAt!.month}.${_lastKmUpdatedAt!.year}',
          //         style: TextStyle(
          //           color: _lastKmUpdatedAt == null ? CupertinoColors.systemGrey : CupertinoColors.white,
          //           fontWeight: _lastKmUpdatedAt == null ? FontWeight.normal : FontWeight.bold,
          //           fontSize: 16,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ),
        if (hasError) _buildErrorText(_fieldErrors['last_km_updated_at']),
      ],
    );
  }

  Widget _buildAddCarButton() {
    final bool canSubmit = _isFormValid && !_isLoading;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 15),
      color: canSubmit ? widget.accentColor : CupertinoColors.systemGrey3, // Culoare Accent sau Gri dezactivat
      borderRadius: BorderRadius.circular(12),
      onPressed: canSubmit ? _addCar : null,
      child: _isLoading
          ? CupertinoActivityIndicator(color: CupertinoColors.black)
          : Text(
        "Adaugă Mașina",
        style: TextStyle(
          color: canSubmit ? CupertinoColors.black : CupertinoColors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorText(List<String>? errors) {
    if (errors == null || errors.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, left: 5.0),
      child: Text(
        errors.join('\n'),
        style: const TextStyle(
          color: CupertinoColors.systemRed,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemRed),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: CupertinoColors.systemRed, fontSize: 14),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// BACKGROUND ANIMATION WIDGETS (Logică Păstrată)
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

