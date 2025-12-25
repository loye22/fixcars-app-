import 'package:fixcars/shared/screens/Server_down_screen.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
import 'package:fixcars/shared/screens/rest_password_screen.dart';
import 'package:fixcars/shared/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../../client/screens/client_home_page.dart';
import 'otp_verification_screen.dart'; // Import OTP verification screen
import '../../supplier/screens/supplier_home_page.dart'; // Import Supplier Home Page

class login_screen extends StatefulWidget {
  final String? initialEmail;
  final String? initialPassword;

  const login_screen({Key? key, this.initialEmail, this.initialPassword}) : super(key: key);

  @override
  _login_screenState createState() => _login_screenState();
}

class _login_screenState extends State<login_screen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEmailValid = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true; // Remember Me checkbox - enabled by default
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
    // Initialize controllers with passed values
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
      _validateEmail(widget.initialEmail!);
    }
    if (widget.initialPassword != null) {
      _passwordController.text = widget.initialPassword!;
    }
    // Load saved credentials from SharedPreferences
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('remembered_email');
      final savedPassword = prefs.getString('remembered_password');
      
      if (savedEmail != null && savedPassword != null) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _validateEmail(savedEmail);
        });
      }
    } catch (e) {
      // Handle error silently
      print('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('remembered_email', _emailController.text);
        await prefs.setString('remembered_password', _passwordController.text);
      } catch (e) {
        // Handle error silently
        print('Error saving credentials: $e');
      }
    } else {
      // Clear saved credentials if checkbox is unchecked
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('remembered_email');
        await prefs.remove('remembered_password');
      } catch (e) {
        // Handle error silently
        print('Error clearing credentials: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    });
  }


  Future<void> _login() async {
    if (!_isEmailValid || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loginData = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    try {
      final result = await ApiService().login(loginData);

      if (result['success'] == true) {
        // Save credentials if Remember Me is checked
        await _saveCredentials();
        
        final userType = result['user_type'];
        if (userType == 'client') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>   client_home_page()),
          );
        } else if (userType == 'supplier') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>   supplier_home_page()),
          );
        } else {
          setState(() {
            _errorMessage = 'Unknown user type';
          });
        }
      } else if (result['user_status'] == 'unverified' && result['user_id'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              userId: result['user_id'],
              email: _emailController.text,
            ),
          ),
        );
      } else if (result['error'] == 'token_expired') {
        final newToken = await ApiService().refreshToken();
        if (newToken != null) {
          await _login(); // Retry login after refresh
        } else {
          setState(() {
            _errorMessage = 'Session expired. Please login again.';
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Login error';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
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
      child: ServerDownWrapper(
        apiService: ApiService(),
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/intro2.png'),
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
                                  'LOGIN',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(height: 40),
                            TextField(
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')), // Blocks ALL whitespace
                              ],
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
                            SizedBox(height: 20),
                            TextField(
                              maxLength: 50,
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: Colors.black54,
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
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? true;
                                    });
                                  },
                                  activeColor: Colors.white,
                                  checkColor: Colors.black,
                                ),
                                Text(
                                  'Ține-mă minte',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                                  );
                                },
                                child: Text('Ai uitat parola ?', style: TextStyle(color: Color(0xFF808080))),
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
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4B5563),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                                minimumSize: Size(double.infinity, 50),
                              ),
                              child: Text('LOGIN', style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => signup_screen()),
                                );

                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF808080),
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                'SIGNUP',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Dacă nu ai cont, te rugăm să te înregistrezi acum.',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10,) ,

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
      ),
    );
  }
}
