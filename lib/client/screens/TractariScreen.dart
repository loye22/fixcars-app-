

// Tractări Auto cu Platformă Screen
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TractariScreen extends StatefulWidget {
  @override
  _TractariScreenState createState() => _TractariScreenState();
}

class _TractariScreenState extends State<TractariScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tractări Auto cu Platformă'),
        backgroundColor: Color(0xFF808080),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicii de Tractare Auto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Tractare sigură și rapidă cu platformă pentru orice vehicul.'),
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