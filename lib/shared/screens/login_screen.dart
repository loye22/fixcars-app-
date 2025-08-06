import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../client/screens/client_home_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          controller: _emailController,
                          onChanged: _validateEmail,
                          style: TextStyle(color: Colors.white),
                          maxLength: 30,
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
                          maxLength: 30,
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
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {},
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
                          onPressed: (){},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4B5563),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text('LOGIN', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Dacă nu ai cont, te rugăm să te înregistrezi acum.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
//
//
//
// class login_screen extends StatefulWidget {
//   @override
//   _login_screenState createState() => _login_screenState();
// }
//
// class _login_screenState extends State<login_screen> with SingleTickerProviderStateMixin {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isEmailValid = false;
//   bool _obscurePassword = true;
//   late AnimationController _controller;
//   late Animation<double> _animation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: Duration(seconds: 1),
//     );
//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
//     _controller.forward();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   void _validateEmail(String value) {
//     setState(() {
//       _isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('assets/intro2.png'),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: FadeTransition(
//           opacity: _animation,
//           child: Center(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Row(
//                       children: [
//                         Text(
//                           'LOGIN',
//                           style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 40),
//                     TextField(
//                       controller: _emailController,
//                       onChanged: _validateEmail,
//                       style: TextStyle(color: Colors.white),
//                       maxLength: 30,
//                       decoration: InputDecoration(
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           borderSide: BorderSide(color: Colors.white, width: 2.0),                        ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           borderSide: BorderSide(color: Colors.white, width: 2.0),                        ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           borderSide: BorderSide(color: Colors.white, width: 2.0),                        ),
//                         labelText: 'Email',
//                         labelStyle: TextStyle(color: Colors.white),
//                         filled: true,
//                         fillColor: Colors.black54,
//
//                         suffixIcon: _isEmailValid
//                             ? Icon(Icons.check, color: Colors.green)
//                             : _emailController.text.isNotEmpty
//                             ? Icon(Icons.close, color: Colors.red)
//                             : null,
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     TextField(
//                       maxLength: 30,
//                       controller: _passwordController,
//                       obscureText: _obscurePassword,
//                       style: TextStyle(color: Colors.white),
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         labelStyle: TextStyle(color: Colors.white),
//                         filled: true,
//                         fillColor: Colors.black54,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           borderSide: BorderSide(color: Colors.white, width: 2.0),                        ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           borderSide: BorderSide(color: Colors.white, width: 2.0),                        ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           borderSide: BorderSide(color: Colors.white, width: 2.0),                        ),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _obscurePassword ? Icons.visibility : Icons.visibility_off,
//                             color: Colors.white,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _obscurePassword = !_obscurePassword;
//                             });
//                           },
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     Align(
//                       alignment: Alignment.center,
//                       child: TextButton(
//                         onPressed: () {},
//                         child: Text('Ai uitat parola ?', style: TextStyle(color: Color(0xFF808080))),
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {},
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF4B5563),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
//                         minimumSize: Size(double.infinity, 50),
//                       ),
//                       child: Text('LOGIN', style: TextStyle(fontSize: 18, color: Colors.white)),
//                     ),
//                     SizedBox(height: 20),
//                     Text(
//                       'Dacă nu ai cont, te rugăm să te înregistrezi acum.',
//                       style: TextStyle(color: Colors.white , fontWeight: FontWeight.w600),
//                       textAlign: TextAlign.center,
//
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }