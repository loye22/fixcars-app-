import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mesaje'),
        backgroundColor: Color(0xFF4B5563),
      ),
      body: Center(
        child: Text('Conversațiile tale vor apărea aici'),
      ),
    );
  }
}