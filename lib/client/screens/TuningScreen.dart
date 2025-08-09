import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Upgrade pentru Mașină Screen
class TuningScreen extends StatefulWidget {
  @override
  _TuningScreenState createState() => _TuningScreenState();
}

class _TuningScreenState extends State<TuningScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upgrade pentru Mașină'),
        backgroundColor: Color(0xFF808080),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upgrade pentru Mașină',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Îmbunătățiri de performanță și estetică pentru vehiculul tău.'),
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