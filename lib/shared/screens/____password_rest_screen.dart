// import 'package:flutter/material.dart';
//
//
// class password_rest_screen extends StatefulWidget {
//   @override
//   _password_rest_screenState createState() => _password_rest_screenState();
// }
//
// class _password_rest_screenState extends State<password_rest_screen> with SingleTickerProviderStateMixin {
//   final _emailController = TextEditingController();
//   bool _isEmailValid = false;
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
//                     Text(
//                       'ÎȚI AMINTEȘTI PAROLA?',
//                       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
//                     ),
//                     SizedBox(height: 40),
//                     Text(
//                       'Te rugăm să introduci emailul tău înregistrat mai jos pentru a schimba parola.',
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: 20),
//                     TextField(
//                       controller: _emailController,
//                       onChanged: _validateEmail,
//                       style: TextStyle(color: Colors.white),
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         labelStyle: TextStyle(color: Colors.white),
//                         filled: true,
//                         fillColor: Colors.black54,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           borderSide: BorderSide(color: Colors.white, width: 2.0),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           borderSide: BorderSide(color: Colors.white, width: 2.0),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           borderSide: BorderSide(color: Colors.white, width: 2.0),
//                         ),
//                         suffixIcon: _isEmailValid
//                             ? Icon(Icons.check, color: Colors.green)
//                             : _emailController.text.isNotEmpty
//                             ? Icon(Icons.close, color: Colors.red)
//                             : null,
//                         counterText: '',
//                       ),
//                       maxLength: 30,
//                     ),
//                     SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {},
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF4B5563),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
//                         minimumSize: Size(double.infinity, 50),
//                       ),
//                       child: Text('TRIMITE', style: TextStyle(fontSize: 18, color: Colors.white)),
//                     ),
//                     SizedBox(height: 20),
//                     TextButton(
//                       onPressed: () {},
//                       child: Text('ÎNAPOI LA LOGIN', style: TextStyle(color: Colors.white)),
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