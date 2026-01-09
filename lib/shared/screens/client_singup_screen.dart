import 'package:fixcars/shared/screens/Server_down_screen.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pinput/pinput.dart';
import '../services/api_service.dart';
import '../services/ImageService.dart';
import 'login_screen.dart';

// --- DESIGN CONSTANTS ---
const Color kBackgroundColor = Color(0xFF000000);
const Color kSurfaceColor = Color(0xFF121212);
const Color kBorderColor = Color(0xFF2C2C2C);
const Color kErrorColor = Color(0xFFFF453A); // iOS System Red
// const Color kPrimaryAccent = Color(0xFF00B4D8); // Elegant Cyan
const Color kPrimaryAccent = Color(0xFF808080); // Elegant Cyan
const String kFontFamily = 'monospace';

class client_singup_screen extends StatefulWidget {
  @override
  _client_singup_screenState createState() => _client_singup_screenState();
}

class _client_singup_screenState extends State<client_singup_screen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _submitted = false;
  bool _isFormValid = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _showOtpScreen = false;
  bool _isLoading = false;
  String? _userId;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      bool passwordsMatch = _passwordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text;

      _isFormValid = _fullNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          passwordsMatch &&
          _selectedImage != null;
    });
  }

  // --- ELEGANT BOTTOM FEEDBACK SHEET ---
  void _showFeedbackSheet(String message, {bool isError = true}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: kBorderColor, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.5))),
            const SizedBox(height: 25),
            Icon(
              isError ? CupertinoIcons.exclamationmark_circle_fill : CupertinoIcons.exclamationmark_circle_fill,
              color: isError ? kErrorColor : Colors.greenAccent,
              size: 50,
            ),
            const SizedBox(height: 16),
            const Text(
              'NOTIFICARE SISTEM',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13, fontFamily: kFontFamily),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? Colors.white.withOpacity(0.05) : kPrimaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isError ? kBorderColor : Colors.transparent)),
                ),
                child: Text('ÎNCHIDE', style: TextStyle(color: isError ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    setState(() => _submitted = true);
    _validateForm();

    if (!_isFormValid) {
      if (_selectedImage == null) {
        _showFeedbackSheet('Vă rugăm să adăugați o poză de profil pentru identificare.');
      } else if (_fullNameController.text.isEmpty || _emailController.text.isEmpty) {
        _showFeedbackSheet('Câmpurile Nume și Email sunt obligatorii.');
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _showFeedbackSheet('Parolele introduse nu sunt identice.');
      } else {
        _showFeedbackSheet('Vă rugăm să completați toate datele marcate cu roșu.');
      }
      return;
    }

    setState(() => _isLoading = true);

    final imageService = ImageService();
    final uploadResult = await imageService.uploadFile(_selectedImage!, ApiService.baseUrl);

    if (!uploadResult['success']) {
      setState(() => _isLoading = false);
      _showFeedbackSheet(uploadResult['error'] ?? 'Eroare la serverul de imagini.');
      return;
    }

    final signupResult = await ApiService().clientSignup(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
      photoUrl: uploadResult['data']['file_url'],
    );

    setState(() => _isLoading = false);

    if (signupResult['success'] || signupResult['data']?['user_id'] != null) {
      setState(() { _userId = signupResult['data']['user_id']; _showOtpScreen = true; });
    } else {
      _showFeedbackSheet(signupResult['error'] ?? 'Contul nu a putut fi creat.');
    }
  }

  // --- UI ELEMENTS ---

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isPhone = false}) {
    bool hasError = _submitted && controller.text.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        onChanged: (_) => _validateForm(),
        obscureText: isPassword && !_passwordVisible,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: TextStyle(color: hasError ? kErrorColor : Colors.grey, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: hasError ? kErrorColor : kPrimaryAccent, size: 20),
          suffixIcon: isPassword
              ? IconButton(
              icon: Icon(_passwordVisible ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill, color: Colors.grey, size: 18),
              onPressed: () => setState(() => _passwordVisible = !_passwordVisible))
              : null,
          filled: true,
          fillColor: kSurfaceColor,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: hasError ? kErrorColor.withOpacity(0.5) : kBorderColor)
          ),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: hasError ? kErrorColor : kPrimaryAccent, width: 1.5)
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InternetConnectivityScreen(
      child: ServerDownWrapper(
        apiService: ApiService(),
        child: Scaffold(
          backgroundColor: kBackgroundColor,
          body: _showOtpScreen ? _buildOtpBody() : _buildSignupBody(),
        ),
      ),
    );
  }

  Widget _buildSignupBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 80),
          const Text('CREEAZĂ CONT',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4, fontFamily: kFontFamily)),
          const SizedBox(height: 40),
          _buildImagePicker(),
          const SizedBox(height: 40),
          _buildTextField(_fullNameController, 'Nume Complet', CupertinoIcons.person_crop_circle),
          _buildTextField(_emailController, 'Adresă Email', CupertinoIcons.envelope),
          _buildTextField(_phoneController, 'Telefon', CupertinoIcons.phone_fill, isPhone: true),
          _buildTextField(_passwordController, 'Parolă', CupertinoIcons.lock_shield_fill, isPassword: true),
          _buildTextField(_confirmPasswordController, 'Confirmă Parolă', CupertinoIcons.lock_shield_fill, isPassword: true),
          const SizedBox(height: 30),
          _buildSubmitButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    bool hasError = _submitted && _selectedImage == null;
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            height: 110, width: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kSurfaceColor,
              border: Border.all(color: hasError ? kErrorColor : kPrimaryAccent, width: 2),
              boxShadow: [BoxShadow(color: (hasError ? kErrorColor : kPrimaryAccent).withOpacity(0.2), blurRadius: 20)],
            ),
            child: _selectedImage == null
                ? Icon(CupertinoIcons.person_alt_circle, color: hasError ? kErrorColor.withOpacity(0.5) : Colors.white24, size: 60)
                : ClipOval(child: Image.file(_selectedImage!, fit: BoxFit.cover)),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: hasError ? kErrorColor : kPrimaryAccent, shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 18),
          )
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryAccent,
          disabledBackgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : const Text('CONTINUĂ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white, fontSize: 16)),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _dialogOption(icon: CupertinoIcons.camera_fill, text: 'Cameră', onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            const SizedBox(height: 12),
            _dialogOption(icon: CupertinoIcons.photo_on_rectangle, text: 'Galerie', onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _dialogOption({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor), color: Colors.white.withOpacity(0.03)),
        child: Row(children: [Icon(icon, color: kPrimaryAccent), const SizedBox(width: 16), Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))]),
      ),
    );
  }

  Widget _buildOtpBody() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.lock_shield_fill, color: kPrimaryAccent, size: 70),
          const SizedBox(height: 32),
          const Text('VERIFICARE OTP', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, fontFamily: kFontFamily)),
          const SizedBox(height: 16),
          Text('Codul a fost trimis la\n${_emailController.text}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.5)),
          const SizedBox(height: 40),
          Pinput(
            length: 6,
            controller: _otpController,
            onCompleted: (_) => _verifyOtp(),
            defaultPinTheme: PinTheme(
              width: 50, height: 56,
              textStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
            ),
          ),
          const SizedBox(height: 40),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Future<void> _verifyOtp() async {
    setState(() { _isLoading = true; });
    final result = await ApiService().validateOtp(_userId!, _otpController.text);
    setState(() => _isLoading = false);
    if (result['success']) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => login_screen(initialEmail: _emailController.text, initialPassword: _passwordController.text)), (route) => false);
    } else {
      _showFeedbackSheet(result['error'] ?? 'Codul OTP introdus este incorect.');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final imageService = ImageService();
      final compressedFile = await imageService.compressImage(File(pickedFile.path));
      if (compressedFile != null) {
        setState(() { _selectedImage = compressedFile; _validateForm(); });
      }
    }
  }
}

