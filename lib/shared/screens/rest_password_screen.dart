import 'package:fixcars/shared/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';

import '../services/PasswordResetService.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _isEmailValid = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    });
  }

  Future<void> _resetPassword() async {
    if (!_isEmailValid || _emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vă rugăm să introduceți un email valid';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordResetService().requestPasswordReset(_emailController.text);

      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Link-ul de resetare a parolei a fost trimis pe email.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        await Future.delayed(Duration(seconds: 2));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => login_screen()),
              (Route<dynamic> route) => false, // Removes all previous routes
        );

      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Eroare la cererea de resetare a parolei';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Eroare de rețea: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InternetConnectivityScreen(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/rest.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              FadeTransition(
                opacity: _animation,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                'RESETEAZĂ PAROLA',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 40),
                          TextField(
                            controller: _emailController,
                            onChanged: _validateEmail,
                            style: TextStyle(color: Colors.white),
                            maxLength: 50,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(color: Colors.white, width: 2.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(color: Colors.white, width: 2.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(color: Colors.white, width: 2.0),
                              ),
                              labelText: 'Email',
                              labelStyle: TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: Colors.black54,
                              suffixIcon: _isEmailValid
                                  ? Icon(Icons.check, color: Colors.green)
                                  : _emailController.text.isNotEmpty
                                  ? Icon(Icons.close, color: Colors.red)
                                  : null,
                            ),
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4B5563),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text(
                              'TRIMITE', // Placeholder for button label, to be replaced by user
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Vă vom trimite un link pentru a reseta parola.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          if (_isLoading)
                            LoadingAnimationWidget.threeArchedCircle(color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}