import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionGate extends StatefulWidget {
  final Widget child;
  const LocationPermissionGate({super.key, required this.child});

  @override
  State<LocationPermissionGate> createState() => _LocationPermissionGateState();
}

class _LocationPermissionGateState extends State<LocationPermissionGate> {
  bool _checking = true;
  bool _granted = false;
  bool _permanentlyDenied = false;
  String? _message;
  bool _requestInProgress = false;

  @override
  void initState() {
    super.initState();
    _ensurePermission();
  }

  Future<void> _ensurePermission() async {
    if (_requestInProgress) return;
    _requestInProgress = true;

    setState(() {
      _checking = true;
      _message = null;
      _permanentlyDenied = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _granted = false;
          _checking = false;
          _permanentlyDenied = false;
          _message = 'Vă rugăm să activați Serviciile de Localizare (GPS).';
        });
        _requestInProgress = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _granted = false;
          _checking = false;
          _permanentlyDenied = true;
          _message =
          'Permisiunea este respinsă permanent. Deschideți Setările pentru a permite localizarea.';
        });
        _requestInProgress = false;
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _granted = false;
          _checking = false;
          _permanentlyDenied = false;
          _message = 'Permisiunea de localizare este necesară pentru a continua.';
        });
      } else if (permission == LocationPermission.deniedForever) {
        setState(() {
          _granted = false;
          _checking = false;
          _permanentlyDenied = true;
          _message =
          'Permisiunea este respinsă permanent. Deschideți Setările pentru a permite localizarea.';
        });
      } else {
        setState(() {
          _granted = true;
          _checking = false;
        });
      }
    } catch (e) {
      setState(() {
        _granted = false;
        _checking = false;
        _permanentlyDenied = false;
        _message = 'Eroare la verificarea permisiunii: $e';
      });
    } finally {
      _requestInProgress = false;
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    await Geolocator.openLocationSettings();
    _ensurePermission();
  }

  // ────────────────────────────────────────────────────────────────
  // Mesajul personalizat cu greșeli intenționate (tradus în română)
  // ────────────────────────────────────────────────────────────────
  static const String _customMessage =
      "permisiunea de locație este necesară pentru a utiliza aplicația te rugăm să consulți termenii și condițiile noastre și politica de confidențialitate pentru mai multe informații despre cum folosim locația ta";

  // Paletă argintie
  static const Color silver = Color(0xFFD0D0D0);
  static const Color lightSilver = Color(0xFFE5E5E5);
  static const Color darkSilver = Color(0xFF9E9E9E);
  static const Color bgBlack = Colors.black;

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: bgBlack,
        body: Center(
          child: CircularProgressIndicator(
            color: silver,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_granted) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: bgBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Iconiță
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade900,
                  boxShadow: [
                    BoxShadow(
                      color: silver.withOpacity(0.25),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on, size: 82, color: silver),
              ),
              const SizedBox(height: 36),

              // Titlu
              const Text(
                'Permisiune de Localizare Necesară',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: silver,
                  letterSpacing: 0.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              // Mesaj (dinamic sau personalizat)
              Text(
                _message ?? _customMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: lightSilver,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Butoane – aspect diferit dacă e respins permanent
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Buton "Permite" – dezactivat dacă e respins permanent
                  if (!_permanentlyDenied)
                    ElevatedButton(
                      onPressed: _requestInProgress ? null : _ensurePermission,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: silver,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 6,
                        shadowColor: silver.withOpacity(0.4),
                      ),
                      child: const Text(
                        'Permite',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),

                  if (!_permanentlyDenied) const SizedBox(width: 18),

                  // Deschide Setări – întotdeauna vizibil
                  OutlinedButton(
                    onPressed: _openSettings,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: silver,
                      side: const BorderSide(color: darkSilver, width: 1.8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Deschide Setări',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}