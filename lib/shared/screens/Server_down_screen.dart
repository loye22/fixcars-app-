import 'package:flutter/material.dart';
import 'package:fixcars/shared/services/api_service.dart'; // Import your ApiService

class ServerDownWrapper extends StatefulWidget {
  final Widget child;
  final ApiService apiService;

  const ServerDownWrapper({
    super.key,
    required this.child,
    required this.apiService
  });

  @override
  _ServerDownWrapperState createState() => _ServerDownWrapperState();
}

class _ServerDownWrapperState extends State<ServerDownWrapper> {
  bool _isServerReachable = true;
  bool _isCheckingServer = false;

  @override
  void initState() {
    super.initState();
    _checkServerReachability();
  }

  Future<void> _checkServerReachability() async {
    if (_isCheckingServer) return;

    setState(() {
      _isCheckingServer = true;
    });

    try {
      final isReachable = await widget.apiService.isServerReachable();
      setState(() {
        _isServerReachable = isReachable;
        _isCheckingServer = false;
      });
    } catch (e) {
      print('Eroare la verificarea accesibilității serverului: $e');
      setState(() {
        _isServerReachable = false;
        _isCheckingServer = false;
      });
    }
  }

  Future<void> _retryConnection() async {
    await _checkServerReachability();
  }

  @override
  Widget build(BuildContext context) {
    // Show server down screen if server is not reachable
    if (!_isServerReachable) {
      return ServerDownScreen(
        onRetry: _retryConnection,
      );
    }

    // Show loading indicator while checking server status
    if (_isCheckingServer) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Verific conexiunea la server...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Show the child widget if server is reachable
    return widget.child;
  }
}

// Your existing ServerDownScreen class remains the same
class ServerDownScreen extends StatefulWidget {
  final VoidCallback onRetry;

  const ServerDownScreen({super.key, required this.onRetry});

  @override
  _ServerDownScreenState createState() => _ServerDownScreenState();
}

class _ServerDownScreenState extends State<ServerDownScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100,),
              Image.asset('assets/serverdown.png', width: 150),
              const SizedBox(height: 10),
              const Text(
                'Server Închis',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                'Server Indisponibil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Stare Server',
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
                        'Server Indisponibil',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Întâmpinăm probleme cu serverul. Vă rugăm să încercați mai târziu.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Stare Server',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.circle, color: Colors.red, size: 12),
                          SizedBox(width: 5),
                          Text('Conexiune Server'),
                          Spacer(),
                          Text('Eșuată'),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: const [
                          Icon(Icons.circle, color: Colors.red, size: 12),
                          SizedBox(width: 5),
                          Text('Server'),
                          Spacer(),
                          Text('Indisponibil'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: widget.onRetry,
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
                        'Funcții Offline',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Puteți accesa următoarele funcții în timp ce serverul este indisponibil:',
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
      ),
    );
  }
}