

// Mecanic Auto Screen
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MecanicScreen extends StatefulWidget {
  @override
  _MecanicScreenState createState() => _MecanicScreenState();
}

class _MecanicScreenState extends State<MecanicScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mecanic Auto'),
        backgroundColor: Color(0xFF808080),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicii de Mecanică Auto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Oferim reparații și întreținere pentru toate tipurile de vehicule.'),
            Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Înapoi'),
            ),
          ],
        ),
      ),
    );
  }
}