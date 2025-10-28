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
  bool _permanentlyDenied = false;   // NEW
  String? _message;
  bool _requestInProgress = false;  // debounce

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
      // 1. Service enabled?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _granted = false;
          _checking = false;
          _permanentlyDenied = false;
          _message = 'Please enable Location Services (GPS).';
        });
        _requestInProgress = false;
        return;
      }

      // 2. Current permission
      LocationPermission permission = await Geolocator.checkPermission();

      // If already denied forever → go straight to settings UI
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _granted = false;
          _checking = false;
          _permanentlyDenied = true;
          _message =
          'Permission permanently denied. Open Settings to allow location.';
        });
        _requestInProgress = false;
        return;
      }

      // 3. If simply denied → ask again
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 4. Evaluate the result of the request
      if (permission == LocationPermission.denied) {
        setState(() {
          _granted = false;
          _checking = false;
          _permanentlyDenied = false;
          _message = 'Location permission is required to continue.';
        });
      } else if (permission == LocationPermission.deniedForever) {
        setState(() {
          _granted = false;
          _checking = false;
          _permanentlyDenied = true;
          _message =
          'Permission permanently denied. Open Settings to allow location.';
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
        _message = 'Error checking permission: $e';
      });
    } finally {
      _requestInProgress = false;
    }
  }




  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    await Geolocator.openLocationSettings();
    // After returning from settings, re-check the permission
    _ensurePermission();
  }

  // ────────────────────────────────────────────────────────────────
  // Your exact requested message (with intentional typos)
  // ────────────────────────────────────────────────────────────────
  static const String _customMessage =
      "plocaion permission is requsiret to use the app please take look at out termis and contion ans privisy polisy for more info how do we use your location";

  // Silver palette
  static const Color silver = Color(0xFFD0D0D0);
  static const Color lightSilver = Color(0xFFE5E5E5);
  static const Color darkSilver = Color(0xFF9E9E9E);
  static const Color bgBlack = Colors.black;

  @override
  Widget build(BuildContext context) {
    // -----------------------------------------------------------------
    // 1. Loading
    // -----------------------------------------------------------------
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

    // -----------------------------------------------------------------
    // 2. Permission granted → show child
    // -----------------------------------------------------------------
    if (_granted) {
      return widget.child;
    }

    // -----------------------------------------------------------------
    // 3. Permission denied (normal or forever)
    // -----------------------------------------------------------------
    return Scaffold(
      backgroundColor: bgBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
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

              // Title
              const Text(
                'Location Permission Required',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: silver,
                  letterSpacing: 0.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              // Message (custom or dynamic)
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

              // -----------------------------------------------------------------
              // Buttons – change layout based on permanent denial
              // -----------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Allow button – **disabled** when permanently denied
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
                        'Allow',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),

                  // Spacer only when both buttons are shown
                  if (!_permanentlyDenied) const SizedBox(width: 18),

                  // Open Settings – always visible (especially when permanent)
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
                      'Open Settings',
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