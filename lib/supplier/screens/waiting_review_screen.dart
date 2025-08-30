import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WaitingReviewScreen extends StatefulWidget {
  const WaitingReviewScreen({super.key});

  @override
  _WaitingReviewScreenState createState() => _WaitingReviewScreenState();
}

class _WaitingReviewScreenState extends State<WaitingReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty,
                size: 80,
                color: Colors.white70,
              ),
              const SizedBox(height: 20),
              const Text(
                'Așteptare pentru Revizuire',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Trimiterea dumneavoastră este în revizuire.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
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
                        'Stare',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.circle, color: Colors.orange, size: 12),
                          SizedBox(width: 5),
                          Text('Aprobare în Așteptare'),
                        ],
                      ),
                      const SizedBox(height: 20), // Space for the button
                      // Placeholder for action button (e.g., "Check Status")
                      // Add your button implementation here
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
                        'Ce să faceți în continuare',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Vă vom notifica prin aplicație sau email când revizuirea este finalizată.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 10),
                      Text('• Verificați notificările periodic'),
                      Text('• Reveniți mai târziu pentru actualizări'),
                    ],
                  ),
                ),
              ),

              // --- WIDGET NOU: Contact Suport ---
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    children: [
                      const TextSpan(
                          text:
                          'Dacă contul dvs. a fost deja activat și vedeți acest ecran, vă rugăm să contactați suportul nostru la: '),
                      TextSpan(
                        text: 'support@fixcars.ro',
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Clipboard.setData(const ClipboardData(text: 'support@fixcars.ro'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Adresa de email a fost copiată.'),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
              // --- FINAL WIDGET NOU ---
            ],
          ),
        ),
      ),
    );
  }
}