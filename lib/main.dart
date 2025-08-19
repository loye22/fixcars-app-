import 'package:fixcars/client/screens/TractariScreen.dart';
import 'package:fixcars/client/screens/client_home_page.dart';
import 'package:fixcars/shared/screens/global_keys.dart';
import 'package:fixcars/shared/services/api_service.dart';
import 'package:fixcars/supplier/screens/supplier_home_page.dart';
import 'package:fixcars/shared/screens/intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'client/screens/ReviewScreen.dart';
import 'client/screens/SupplierProfileScreen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();

  bool isAuthenticated = false;
  try {
    final token = await apiService.getJwtToken();
    if (token != null) {
      if (await apiService.isTokenExpired()) {
        final newToken = await apiService.refreshToken();
        isAuthenticated = newToken != null;
      } else {
        isAuthenticated = true;
      }
    }
  } catch (e) {
    print('Auth check error: $e');
    isAuthenticated = false;
  }

  runApp(MyApp(isAuthenticated: isAuthenticated));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;
  const MyApp({super.key, required this.isAuthenticated});
  final Color customTextColor = const Color(0xFF808080);

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme,
    ).apply(
      bodyColor: customTextColor,
      displayColor: customTextColor,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        textTheme: baseTextTheme,
      ),
      home: isAuthenticated ? HomePageRedirector()  :   into_screen(),
    );
  }
}

class HomePageRedirector extends StatelessWidget {
  const HomePageRedirector({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiService().getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return  into_screen();
        }

        final userData = snapshot.data!;
        final userType = userData['user_type'];

        if (userType == 'client') {
          return   client_home_page();
        } else if (userType == 'supplier') {
          return   supplier_home_page();
        }

        return  into_screen();
      },
    );
  }
}


