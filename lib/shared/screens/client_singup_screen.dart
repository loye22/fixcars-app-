import 'package:fixcars/shared/screens/Server_down_screen.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pinput/pinput.dart';
import '../services/api_service.dart';
import '../services/ImageService.dart';
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
  bool _passwordVisible = false;


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
      final imageService = ImageService();
      final compressedFile = await imageService.compressImage(File(pickedFile.path));
      if (compressedFile != null) {
        setState(() {
          _selectedImage = compressedFile;
          _validateForm();
        });
      } else {
        setState(() {
          _errorMessage = 'Eroare la compresia imaginii';
        });
      }
    }
  }

  // void _showImageSourceDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Selectați sursa imaginii'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: Icon(Icons.camera_alt),
  //             title: Text('Cameră'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _pickImage(ImageSource.camera);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.photo_library),
  //             title: Text('Galerie'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _pickImage(ImageSource.gallery);
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selectați sursa imaginii',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),

              _dialogOption(
                icon: Icons.camera_alt_rounded,
                text: 'Cameră',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              SizedBox(height: 10),

              _dialogOption(
                icon: Icons.photo_library_rounded,
                text: 'Galerie',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: Colors.black87),
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }




  void _validateForm() {
    setState(() {
      bool passwordsMatch = _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text;

      _isFormValid = _fullNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _confirmEmailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          passwordsMatch &&
          _phoneController.text.isNotEmpty &&
          _selectedImage != null;
    });
  }


  // void _validateForm() {
  //   setState(() {
  //     _isFormValid = _fullNameController.text.isNotEmpty &&
  //         _emailController.text.isNotEmpty &&
  //         _confirmEmailController.text.isNotEmpty &&
  //         _passwordController.text.isNotEmpty &&
  //         _confirmPasswordController.text.isNotEmpty &&
  //         _phoneController.text.isNotEmpty &&
  //         _selectedImage != null;
  //   });
  // }

  Future<void> _onSubmit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_isFormValid) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ups! Te rog să te asiguri că ai selectat o imagine, că ambele câmpuri de email coincid și că parolele se potrivesc.';
      });
      return;
    }

    // Upload image using ImageService
    final imageService = ImageService();
    final uploadResult = await imageService.uploadFile(_selectedImage!, ApiService.baseUrl);
    if (!uploadResult['success']) {
      setState(() {
        _isLoading = false;
        _errorMessage = uploadResult['error'];
      });
      return;
    }

    final photoUrl = uploadResult['data']['file_url'];

    print("debug");

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
        print(_errorMessage);
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
    return InternetConnectivityScreen(
      child: ServerDownWrapper(
        apiService: ApiService(),
        child: Scaffold(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 50,),
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
                          width: 100, // Changed from double.infinity to fixed width for circle
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle, // Changed from borderRadius to shape
                            border: Border.all( // Optional: add border to make circle more visible
                              color: Colors.grey,
                              width: 2.0,
                            ),
                          ),
                          child: _selectedImage == null
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/camera.png', width: 40,),
                              // Icon(
                              //   Icons.camera_alt,
                              //   color: Colors.grey,
                              //   size: 40,
                              // ),
                              Text(
                                'Încărcați o fotografie',
                                style: TextStyle(color: Colors.grey, fontSize: 10), // Smaller font
                                textAlign: TextAlign.center, // Center text
                              ),
                            ],
                          )
                              : ClipOval( // Changed from ClipRRect to ClipOval for perfect circle
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // GestureDetector(
                      //   onTap: _showImageSourceDialog,
                      //   child: Container(
                      //     height: 100,
                      //     width: double.infinity,
                      //     decoration: BoxDecoration(
                      //       color: Colors.white,
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //     child: _selectedImage == null
                      //         ? Column(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Icon(
                      //           Icons.camera_alt,
                      //           color: Colors.grey,
                      //           size: 40,
                      //         ),
                      //         Text(
                      //           'Încărcați o fotografie',
                      //           style: TextStyle(color: Colors.grey),
                      //         ),
                      //       ],
                      //     )
                      //         : ClipRRect(
                      //       borderRadius: BorderRadius.circular(8.0),
                      //       child: Image.file(
                      //         _selectedImage!,
                      //         fit: BoxFit.cover,
                      //       ),
                      //     ),
                      //   ),
                      // ),
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
                      // TextField(
                      //   controller: _passwordController,
                      //   obscureText: true,
                      //   onChanged: (_) => _validateForm(),
                      //   decoration: InputDecoration(
                      //     labelText: 'Parolă',
                      //     hintText: 'Minim 8 caractere',
                      //     hintStyle: TextStyle(color: Colors.grey),
                      //     prefixIcon: Padding(
                      //       padding: EdgeInsets.only(left: 12, right: 8),
                      //       child: Image.asset(
                      //         'assets/loc.png',
                      //         width: 20,
                      //         height: 20,
                      //       ),
                      //     ),
                      //     filled: true,
                      //     fillColor: Colors.white,
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(8.0),
                      //       borderSide: BorderSide.none,
                      //     ),
                      //   ),
                      // ),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        onChanged: (_) => _validateForm(),
                        decoration: InputDecoration(
                          labelText: 'Parolă',
                          hintText: 'Minim 8 caractere',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Image.asset(
                              'assets/loc.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      SizedBox(height: 16),
                      // TextField(
                      //   controller: _confirmPasswordController,
                      //   obscureText: true,
                      //   onChanged: (_) => _validateForm(),
                      //   decoration: InputDecoration(
                      //     labelText: 'Confirmă parola',
                      //     hintText: 'Minim 8 caractere',
                      //     hintStyle: TextStyle(color: Colors.grey),
                      //     prefixIcon: Padding(
                      //       padding: EdgeInsets.only(left: 12, right: 8),
                      //       child: Image.asset(
                      //         'assets/loc.png',
                      //         width: 20,
                      //         height: 20,
                      //       ),
                      //     ),
                      //     filled: true,
                      //     fillColor: Colors.white,
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(8.0),
                      //       borderSide: BorderSide.none,
                      //     ),
                      //   ),
                      // ),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_passwordVisible,   // SAME VARIABLE
                        onChanged: (_) => _validateForm(),
                        decoration: InputDecoration(
                          labelText: 'Confirmă parola',
                          hintText: 'Minim 8 caractere',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Image.asset(
                              'assets/loc.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible; // SAME TOGGLE
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
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
                          suffixIcon: GestureDetector(
                            onTap: () => _showPhoneInfo(context),
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3F4F6), // Very light gray (elegant background)
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.help_outline_rounded,
                                color: Color(0xFF4B5563), // Your requested color
                                size: 18,
                              ),
                            ),
                          ),
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
                      ), /// here
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
                      SizedBox(height: 50,)
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
        ),
      ),
    );
  }

  void _showPhoneInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive width: max 90% of screen, min 280
            double maxWidth = constraints.maxWidth > 400 ? 360 : constraints.maxWidth * 0.9;

            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: Color(0xFF4B5563),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'De ce avem nevoie de numărul tău de telefon?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Responsive text - wraps perfectly
                    const Text(
                      'Numărul tău de telefon este folosit doar pentru serviciile de tractare auto și asistență SOS. În rest, nu va fi partajat cu nimeni.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Close button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4B5563),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text(
                          'Am înțeles',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


