import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class client_home_page extends StatefulWidget {
  const client_home_page({super.key});

  @override
  State<client_home_page> createState() => _client_home_pageState();
}

class _client_home_pageState extends State<client_home_page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("home page client"),),
    );
  }
}
