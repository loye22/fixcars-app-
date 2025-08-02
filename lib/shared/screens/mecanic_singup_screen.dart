// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
//
// class mecanic_singup_screen extends StatefulWidget {
//   @override
//   _mecanic_singup_screenState createState() => _mecanic_singup_screenState();
// }
//
// class _mecanic_singup_screenState extends State<mecanic_singup_screen> {
//   final _fullNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _confirmEmailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _phoneController = TextEditingController();
//   bool _showErrors = false;
//   bool _isFormValid = false;
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();
//
//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _confirmEmailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }
//
//   bool _isValidEmail(String email) {
//     final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
//     return emailRegex.hasMatch(email);
//   }
//
//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await _picker.pickImage(source: source);
//     if (pickedFile != null) {
//       setState(() {
//         _selectedImage = File(pickedFile.path);
//         _validateForm();
//       });
//     }
//   }
//
//   void _showImageSourceDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Selectați sursa imaginii'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: Icon(Icons.camera_alt),
//               title: Text('Cameră'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.camera);
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.photo_library),
//               title: Text('Galerie'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.gallery);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _validateForm() {
//     setState(() {
//       _isFormValid = _fullNameController.text.isNotEmpty &&
//           _emailController.text.isNotEmpty &&
//           _isValidEmail(_emailController.text) &&
//           _confirmEmailController.text.isNotEmpty &&
//           _passwordController.text.isNotEmpty &&
//           _confirmPasswordController.text.isNotEmpty &&
//           _phoneController.text.isNotEmpty &&
//           _phoneController.text.length == 10 &&
//           _phoneController.text.startsWith('07') &&
//           _emailController.text == _confirmEmailController.text &&
//           _passwordController.text == _confirmPasswordController.text &&
//           _selectedImage != null;
//     });
//   }
//
//   void _onSubmit() {
//     setState(() {
//       _showErrors = true;
//       _validateForm();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF3F4F6),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(child: SizedBox(height: 10,)) ,
//             Text(
//               'Creează-ți contul',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
//             ),
//             SizedBox(height: 40),
//             GestureDetector(
//               onTap: _showImageSourceDialog,
//               child: Container(
//                 height: 100,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8.0),
//                 ),
//                 child: _selectedImage == null
//                     ? Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.camera_alt, color: Colors.grey, size: 40),
//                     Text(
//                       'Încărcați o fotografie',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     if (_showErrors && _selectedImage == null)
//                       Text(
//                         'Vă rugăm să încărcați o fotografie',
//                         style: TextStyle(color: Colors.red, fontSize: 12),
//                       ),
//                   ],
//                 )
//                     : ClipRRect(
//                   borderRadius: BorderRadius.circular(8.0),
//                   child: Image.file(_selectedImage!, fit: BoxFit.cover),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _fullNameController,
//               onChanged: (_) => _validateForm(),
//               decoration: InputDecoration(
//                 labelText: 'Nume complet',
//                 hintText: 'Ex: Ion Popescu',
//                 hintStyle: TextStyle(color: Colors.grey),
//                 prefixIcon: Padding(
//                   padding: EdgeInsets.only(left: 12, right: 8),
//                   child: Image.asset('assets/person.png', width: 20, height: 20),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 errorText: _showErrors && _fullNameController.text.isEmpty
//                     ? 'Vă rugăm să introduceți numele complet'
//                     : null,
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _emailController,
//               onChanged: (_) => _validateForm(),
//               decoration: InputDecoration(
//                 labelText: 'Adresă de email',
//                 hintText: 'Ex: ion.popescu@email.com',
//                 hintStyle: TextStyle(color: Colors.grey),
//                 prefixIcon: Padding(
//                   padding: EdgeInsets.only(left: 12, right: 8),
//                   child: Image.asset('assets/email.png', width: 20, height: 20),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 errorText: _showErrors
//                     ? _emailController.text.isEmpty
//                     ? 'Vă rugăm să introduceți adresa de email'
//                     : !_isValidEmail(_emailController.text)
//                     ? 'Vă rugăm să introduceți o adresă de email validă'
//                     : null
//                     : null,
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _confirmEmailController,
//               onChanged: (_) => _validateForm(),
//               decoration: InputDecoration(
//                 labelText: 'Confirmă adresa de email',
//                 hintText: 'Ex: ion.popescu@email.com',
//                 hintStyle: TextStyle(color: Colors.grey),
//                 prefixIcon: Padding(
//                   padding: EdgeInsets.only(left: 12, right: 8),
//                   child: Image.asset('assets/email.png', width: 20, height: 20),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 errorText: _showErrors
//                     ? _confirmEmailController.text.isEmpty
//                     ? 'Vă rugăm să confirmați adresa de email'
//                     : _emailController.text != _confirmEmailController.text
//                     ? 'Adresele de email nu se potrivesc'
//                     : null
//                     : null,
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               onChanged: (_) => _validateForm(),
//               decoration: InputDecoration(
//                 labelText: 'Parolă',
//                 hintText: 'Minim 8 caractere',
//                 hintStyle: TextStyle(color: Colors.grey),
//                 prefixIcon: Padding(
//                   padding: EdgeInsets.only(left: 12, right: 8),
//                   child: Image.asset('assets/loc.png', width: 20, height: 20),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 errorText: _showErrors && _passwordController.text.isEmpty
//                     ? 'Vă rugăm să introduceți parola'
//                     : null,
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _confirmPasswordController,
//               obscureText: true,
//               onChanged: (_) => _validateForm(),
//               decoration: InputDecoration(
//                 labelText: 'Confirmă parola',
//                 hintText: 'Minim 8 caractere',
//                 hintStyle: TextStyle(color: Colors.grey),
//                 prefixIcon: Padding(
//                   padding: EdgeInsets.only(left: 12, right: 8),
//                   child: Image.asset('assets/loc.png', width: 20, height: 20),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 errorText: _showErrors
//                     ? _confirmPasswordController.text.isEmpty
//                     ? 'Vă rugăm să confirmați parola'
//                     : _passwordController.text != _confirmPasswordController.text
//                     ? 'Parolele nu se potrivesc'
//                     : null
//                     : null,
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _phoneController,
//               onChanged: (_) => _validateForm(),
//               keyboardType: TextInputType.number,
//               inputFormatters: [
//                 FilteringTextInputFormatter.digitsOnly,
//                 LengthLimitingTextInputFormatter(10),
//               ],
//               decoration: InputDecoration(
//                 labelText: 'Număr de telefon',
//                 hintText: 'Ex: 0712345678',
//                 hintStyle: TextStyle(color: Colors.grey),
//                 prefixIcon: Padding(
//                   padding: EdgeInsets.only(left: 12, right: 8),
//                   child: Image.asset('assets/phone.png', width: 20, height: 20),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 errorText: _showErrors
//                     ? _phoneController.text.isEmpty
//                     ? 'Vă rugăm să introduceți numărul de telefon'
//                     : _phoneController.text.length != 10 || !_phoneController.text.startsWith('07')
//                     ? 'Numărul trebuie să înceapă cu 07 și să aibă 10 cifre'
//                     : null
//                     : null,
//               ),
//             ),
//             Expanded(child: SizedBox(height: 40)),
//             ElevatedButton(
//               onPressed: _onSubmit,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF4B5563),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
//                 minimumSize: Size(double.infinity, 50),
//               ),
//               child: Text('URMĂTORUL', style: TextStyle(fontSize: 18, color: Colors.white)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pinput/pinput.dart';

class mecanic_singup_screen extends StatefulWidget {
  @override
  _mecanic_singup_screenState createState() => _mecanic_singup_screenState();
}

class _mecanic_singup_screenState extends State<mecanic_singup_screen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _showErrors = false;
  bool _isFormValid = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _showOtpScreen = false;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _validateForm();
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selectați sursa imaginii'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Cameră'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _fullNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _isValidEmail(_emailController.text) &&
          _confirmEmailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _phoneController.text.length == 10 &&
          _phoneController.text.startsWith('07') &&
          _emailController.text == _confirmEmailController.text &&
          _passwordController.text == _confirmPasswordController.text &&
          _selectedImage != null;
    });
  }

  void _onSubmit() {
    setState(() {
      _showErrors = true;
      _validateForm();
      if (_isFormValid) {
        _showOtpScreen = true; // Switch to OTP screen
      }
    });
  }

  void _verifyOtp() {
    // Placeholder for API call (to be implemented by you)
    // Example: if (_otpController.text == '123456') { /* API call */ }
    print('Verifying OTP: ${_otpController.text}');
    // Add your API logic here using http package, e.g.:
    // final response = await http.post(Uri.parse('your_api_endpoint'), body: {
    //   'phone': _phoneController.text,
    //   'otp': _otpController.text,
    //   // Add other data as needed
    // });
    // if (response.statusCode == 200) {
    //   // Handle success
    // }
  }

  void _resendOtp() {
    // Placeholder for resend OTP logic
    print('Resending OTP to ${_phoneController.text}');
    // Add your resend API call here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _showOtpScreen
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 100,),
            Center(
              child: Text(
                'Verificați telefonul',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Am trimis un cod de verificare la',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            Center(
              child: Text(
                _phoneController.text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 40),
            Center(
              child: Pinput(
                length: 6,
                controller: _otpController,
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                onCompleted: (pin) => _verifyOtp(),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4B5563),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Verifică și continuă', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _resendOtp,
                child: Text('Nu ați primit codul? Trimiteți din nou'),
              ),
            ),
            Expanded(child: SizedBox(height: 10,)),



          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creează-ți contul',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 40),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                    Text(
                      'Încărcați o fotografie',
                      style: TextStyle(color: Colors.grey),
                    ),
                    if (_showErrors && _selectedImage == null)
                      Text(
                        'Vă rugăm să încărcați o fotografie',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              onChanged: (_) => _validateForm(),
              decoration: InputDecoration(
                labelText: 'Nume complet',
                hintText: 'Ex: Ion Popescu',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Image.asset('assets/person.png', width: 20, height: 20),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                errorText: _showErrors && _fullNameController.text.isEmpty
                    ? 'Vă rugăm să introduceți numele complet'
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              onChanged: (_) => _validateForm(),
              decoration: InputDecoration(
                labelText: 'Adresă de email',
                hintText: 'Ex: ion.popescu@email.com',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Image.asset('assets/email.png', width: 20, height: 20),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                errorText: _showErrors
                    ? _emailController.text.isEmpty
                    ? 'Vă rugăm să introduceți adresa de email'
                    : !_isValidEmail(_emailController.text)
                    ? 'Vă rugăm să introduceți o adresă de email validă'
                    : null
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmEmailController,
              onChanged: (_) => _validateForm(),
              decoration: InputDecoration(
                labelText: 'Confirmă adresa de email',
                hintText: 'Ex: ion.popescu@email.com',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Image.asset('assets/email.png', width: 20, height: 20),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                errorText: _showErrors
                    ? _confirmEmailController.text.isEmpty
                    ? 'Vă rugăm să confirmați adresa de email'
                    : _emailController.text != _confirmEmailController.text
                    ? 'Adresele de email nu se potrivesc'
                    : null
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              onChanged: (_) => _validateForm(),
              decoration: InputDecoration(
                labelText: 'Parolă',
                hintText: 'Minim 8 caractere',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Image.asset('assets/loc.png', width: 20, height: 20),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                errorText: _showErrors && _passwordController.text.isEmpty
                    ? 'Vă rugăm să introduceți parola'
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              onChanged: (_) => _validateForm(),
              decoration: InputDecoration(
                labelText: 'Confirmă parola',
                hintText: 'Minim 8 caractere',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Image.asset('assets/loc.png', width: 20, height: 20),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                errorText: _showErrors
                    ? _confirmPasswordController.text.isEmpty
                    ? 'Vă rugăm să confirmați parola'
                    : _passwordController.text != _confirmPasswordController.text
                    ? 'Parolele nu se potrivesc'
                    : null
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              onChanged: (_) => _validateForm(),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: 'Număr de telefon',
                hintText: 'Ex: 0712345678',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Image.asset('assets/phone.png', width: 20, height: 20),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                errorText: _showErrors
                    ? _phoneController.text.isEmpty
                    ? 'Vă rugăm să introduceți numărul de telefon'
                    : _phoneController.text.length != 10 || !_phoneController.text.startsWith('07')
                    ? 'Numărul trebuie să înceapă cu 07 și să aibă 10 cifre'
                    : null
                    : null,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4B5563),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('URMĂTORUL', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}