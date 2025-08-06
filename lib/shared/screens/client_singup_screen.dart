import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pinput/pinput.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class client_singup_screen extends StatefulWidget {
  @override
  _client_singup_screenState createState() => _client_singup_screenState();
}

class _client_singup_screenState extends State<client_singup_screen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isFormValid = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _showOtpScreen = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;

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
          _confirmEmailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _selectedImage != null;
    });
  }

  Future<void> _onSubmit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_isFormValid) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Vă rugăm să completați toate câmpurile și să încărcați o imagine.';
      });
      return;
    }

    // Upload image
    final uploadResult = await ApiService().uploadFile(_selectedImage!);
    if (!uploadResult['success']) {
      setState(() {
        _isLoading = false;
        _errorMessage = uploadResult['error'];
      });
      return;
    }

    final photoUrl = uploadResult['data']['file_url'];

    // Perform signup
    final signupResult = await ApiService().clientSignup(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
      photoUrl: photoUrl,
    );

    setState(() {
      _isLoading = false;
    });

    if (signupResult['success'] || signupResult['data']?['user_id'] != null) {
      setState(() {
        _userId = signupResult['data']['user_id'];
        _showOtpScreen = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(signupResult['data']['message'] ?? 'Vă rugăm să verificați OTP-ul.')),
      );
    } else {
      setState(() {
        _errorMessage = signupResult['error'];
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService().validateOtp(_userId!, _otpController.text);

    setState(() {
      _isLoading = false;
    });


    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['data']['message'])),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => login_screen(
            initialEmail: _emailController.text,
            initialPassword: _passwordController.text,
          ),
        ),
            (Route<dynamic> route) => false,
      );
    }


    else {
      setState(() {
        _errorMessage = result['error'];
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService().resendOtp(_userId!);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['data']['message'])),
      );
    } else {
      setState(() {
        _errorMessage = result['error'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: _showOtpScreen
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    'Verificați telefonul',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
                    _emailController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4B5563),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Verifică și continuă',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: Text('Nu ați primit codul? Trimiteți din nou'),
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
                Expanded(child: SizedBox(height: 10)),
              ],
            )
                : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creează-ți contul',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
                          Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                            size: 40,
                          ),
                          Text(
                            'Încărcați o fotografie',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
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
                        child: Image.asset(
                          'assets/person.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
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
                        child: Image.asset(
                          'assets/email.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
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
                        child: Image.asset(
                          'assets/email.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
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
                        child: Image.asset(
                          'assets/loc.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
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
                        child: Image.asset(
                          'assets/loc.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
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
                        child: Image.asset(
                          'assets/phone.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
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
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4B5563),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      'URMĂTORUL',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}


