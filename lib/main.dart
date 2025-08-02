 import 'package:fixcars/shared/screens/intro_screen.dart';
import 'package:fixcars/shared/screens/login_screen.dart';
import 'package:fixcars/shared/screens/mecanic_singup_screen.dart';
import 'package:fixcars/shared/screens/password_rest_screen.dart';
import 'package:fixcars/shared/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  final Color customTextColor = const Color(0xFF808080); // Hex: #808080

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme,
    ).apply(
      bodyColor: customTextColor,
      displayColor: customTextColor,
    );


    return MaterialApp(
      theme: ThemeData(
        textTheme: baseTextTheme,
      ),      home: mecanic_singup_screen(),
    );
  }
}
