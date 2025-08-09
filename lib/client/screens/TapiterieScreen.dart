import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Tapiterie Auto Profesională Screen
class TapiterieScreen extends StatefulWidget {
  @override
  _TapiterieScreenState createState() => _TapiterieScreenState();
}

class _TapiterieScreenState extends State<TapiterieScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tapiterie Auto Profesională'),
        backgroundColor: Color(0xFF808080),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tapiterie Auto Profesională',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Renovare și înlocuire tapiterie pentru confort maxim.'),
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