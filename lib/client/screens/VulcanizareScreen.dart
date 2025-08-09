// Vulcanizare Auto Mobilă Screen
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VulcanizareScreen extends StatefulWidget {
  @override
  _VulcanizareScreenState createState() => _VulcanizareScreenState();
}

class _VulcanizareScreenState extends State<VulcanizareScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vulcanizare Auto Mobilă'),
        backgroundColor: Color(0xFF808080),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicii de Vulcanizare Auto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Reparații și înlocuire anvelope mobile la locația dorită.'),
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