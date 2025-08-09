import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Detaliing Auto Profesional Screen
class DetailingScreen extends StatefulWidget {
  @override
  _DetailingScreenState createState() => _DetailingScreenState();
}

class _DetailingScreenState extends State<DetailingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detaliing Auto Profesional'),
        backgroundColor: Color(0xFF808080),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detaliere Auto Profesională',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Curățare și lustruire de înaltă calitate pentru exterior și interior.'),
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
