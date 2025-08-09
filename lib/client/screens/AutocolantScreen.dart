import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Autocolant & Folie Auto Screen
class AutocolantScreen extends StatefulWidget {
  @override
  _AutocolantScreenState createState() => _AutocolantScreenState();
}

class _AutocolantScreenState extends State<AutocolantScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Autocolant & Folie Auto'),
        backgroundColor: Color(0xFF808080),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicii de Înfoliere Auto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Personalizare și protecție cu folii de calitate superioară.'),
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