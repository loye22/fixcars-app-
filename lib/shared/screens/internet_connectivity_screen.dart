import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class InternetConnectivityScreen extends StatefulWidget {
  final Widget child;

  const InternetConnectivityScreen({super.key, required this.child});

  @override
  _InternetConnectivityScreenState createState() =>
      _InternetConnectivityScreenState();
}

class _InternetConnectivityScreenState extends State<InternetConnectivityScreen> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Could not check connectivity status: $e');
      setState(() {
        _hasInternetConnection = false;
      });
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      _hasInternetConnection = results.any((result) =>
      result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _hasInternetConnection ? widget.child : NoInternetScreen(
      onRetry: () async {
        await _initConnectivity();
      },
    );
  }
}





class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF2E2E3A),
              child: Icon(Icons.wifi_off, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Mod Offline',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              'Conexiune Pierdută',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Stare rețea',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'În prezent sunteți offline',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Nu putem conecta la serverele noastre. Vă rugăm verificați conexiunea la internet și încercați din nou.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Stare Conectivitate',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(Icons.circle, color: Colors.red, size: 12),
                        SizedBox(width: 5),
                        Text('Internet'),
                        Spacer(),
                        Text('Deconectat'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: const [
                        Icon(Icons.circle, color: Colors.yellow, size: 12),
                        SizedBox(width: 5),
                        Text('Rețea Locală'),
                        Spacer(),
                        Text('Limitată'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: const [
                        Icon(Icons.circle, color: Colors.red, size: 12),
                        SizedBox(width: 5),
                        Text('Conexiune Server'),
                        Spacer(),
                        Text('Eșuată'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Încercați din nou',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFF2E2E3A),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Disponibil Offline',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Puteți accesa următoarele funcții în timp ce sunteți offline:',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    Text('• Vizualizați conținut încărcat anterior'),
                    Text('• Accesați documentele salvate'),
                    Text('• Actualizați informațiile profilului (se va sincroniza mai târziu)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




