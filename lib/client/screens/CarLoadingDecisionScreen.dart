
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/CarService.dart';
import 'CarHealthScreen.dart';
import 'car_initiate_screen.dart';      // Assuming this file contains CarInitiateScreen

enum CarScreenState {
  loading,
  hasCar, // Corresponds to CarHealthScreen
  noCar,  // Corresponds to CarInitiateScreen
  error,
}

// --- 2. The Loading and Decision Widget ---
class CarLoadingDecisionScreen extends StatefulWidget {
  const CarLoadingDecisionScreen({super.key});

  @override
  State<CarLoadingDecisionScreen> createState() => _CarLoadingDecisionScreenState();
}

class _CarLoadingDecisionScreenState extends State<CarLoadingDecisionScreen> {
  CarScreenState _currentState = CarScreenState.loading;

  // Data holder for CarHealthScreen (minimal data needed now)
  Map<String, dynamic>? _carData;
  String _errorMessage = '';

  // Assuming CarService is defined in my_car_screen_management.dart or imported
  final CarService _carService = CarService();

  @override
  void initState() {
    super.initState();
    _checkCarExistence();
  }

  // --- The Simplified Data Loading and State Switching Logic ---
  Future<void> _checkCarExistence() async {
    // Set the state to loading right before the API call
    if (mounted) {
      setState(() {
        _currentState = CarScreenState.loading;
        _errorMessage = '';
      });
    }

    try {
      final List<Map<String, dynamic>> cars = await _carService.fetchCars();

      if (cars.isNotEmpty) {
        // Car exists. Store the first car object.
        if (mounted) {
          setState(() {
            _carData = cars[0];
            _currentState = CarScreenState.hasCar; // SWITCH TO CarHealthScreen
          });
        }
      } else {
        // No car exists.
        if (mounted) {
          setState(() {
            _currentState = CarScreenState.noCar; // SWITCH TO CarInitiateScreen
          });
        }
      }
    } catch (e) {
      // Error handling
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: $e';
          _currentState = CarScreenState.error;
        });
      }
    }
  }

  // --- 3. Conditional Rendering ---
  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case CarScreenState.loading:
        return  Scaffold(
          backgroundColor: Color(0xFF1A1A1A),
          body: Center(child:
          LoadingAnimationWidget.threeArchedCircle(
            color: Color(0xFFFFFFFF),
            size: 40,
          )

          ),
        );

      case CarScreenState.hasCar:
      // Pass the essential car data to the health screen
        if (_carData == null) {
          return const Text('Data inconsistency error.', style: TextStyle(color: Colors.red));
        }
        return CarHealthScreen();

      case CarScreenState.noCar:
      // Render CarInitiateScreen
        return CarInitiateScreen();

      case CarScreenState.error:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $_errorMessage'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _checkCarExistence, // Retry function
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        );
    }
  }
}