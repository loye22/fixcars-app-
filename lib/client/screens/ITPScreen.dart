import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ITP Screen
class ITPScreen extends StatefulWidget {
  @override
  _ITPScreenState createState() => _ITPScreenState();
}

class _ITPScreenState extends State<ITPScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ITP'),
        backgroundColor: Color(0xFF808080),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inspecție Tehnică Periodică',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Verificare tehnică obligatorie pentru siguranță rutieră.'),
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