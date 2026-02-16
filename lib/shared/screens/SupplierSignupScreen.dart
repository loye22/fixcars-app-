import 'package:dotted_border/dotted_border.dart';
import 'package:fixcars/shared/screens/Server_down_screen.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pinput/pinput.dart';
import '../services/ImageService.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

// --- DESIGN CONSTANTS ---
const Color kBackgroundColor = Color(0xFF000000);
const Color kSurfaceColor = Color(0xFF121212);
const Color kBorderColor = Color(0xFF2C2C2C);
const Color kErrorColor = Color(0xFFFF453A);
const Color kPrimaryAccent = Color(0xFF808080);
const String kFontFamily = 'monospace';

class SupplierSignupScreen extends StatefulWidget {
  @override
  _SupplierSignupScreenState createState() => _SupplierSignupScreenState();
}

class _SupplierSignupScreenState extends State<SupplierSignupScreen> {
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _aboutBusinessController = TextEditingController();
  final _otpController = TextEditingController();

  File? _profileImage;
  List<File> _coverPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _showOtpScreen = false;
  bool _isLoading = false;
  bool _submitted = false;
  String? _userId;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _aboutBusinessController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // --- FEEDBACK SYSTEM ---
  void _showFeedbackSheet(String message, {bool isError = true}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: kBorderColor)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Icon(isError ? CupertinoIcons.exclamationmark_shield_fill : CupertinoIcons.exclamationmark_shield_fill,
                color: isError ? kErrorColor : kPrimaryAccent, size: 50),
            const SizedBox(height: 16),
            Text(isError ? 'EROARE VALIDARE' : 'SUCCES',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: kFontFamily)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: kSurfaceColor, side: const BorderSide(color: kBorderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('ÎNCHIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UPDATED VALIDATION (OPTIONAL FIELDS INCLUDED) ---
  bool _validate() {
    if (_profileImage == null) { _showFeedbackSheet('Vă rugăm să selectați o imagine de profil.'); return false; }
    if (_businessNameController.text.isEmpty) { _showFeedbackSheet('Numele afacerii este obligatoriu.'); return false; }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) { _showFeedbackSheet('Introduceți o adresă de email validă.'); return false; }
    if (_phoneController.text.length < 10) { _showFeedbackSheet('Numărul de telefon este invalid.'); return false; }
    if (_passwordController.text.isEmpty) { _showFeedbackSheet('Parola este obligatorie.'); return false; }
    if (_passwordController.text != _confirmPasswordController.text) { _showFeedbackSheet('Parolele nu coincid.'); return false; }
    return true;
  }

  Future<void> _onSubmit() async {
    setState(() => _submitted = true);
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Handle Location with specific permission feedback
      // Position position;
      // try {
      //   position = await Geolocator.getCurrentPosition(
      //     desiredAccuracy: LocationAccuracy.high,
      //     timeLimit: const Duration(seconds: 5),
      //   );
      // } catch (e) {
      //   // Show high-end feedback for GPS failure
      //   _showFeedbackSheet(
      //     "Accesul la locație a fost refuzat. Vă rugăm să activați permisiunile GPS din setările telefonului pentru a ne permite să vă afișăm pe hartă.",
      //     isError: true,
      //   );
      //   setState(() => _isLoading = false);
      //   return;
      // }


      double latitude = 44.4268;  // Dummy lat (e.g., Bucharest)
      double longitude = 26.1025; // Dummy long (e.g., Bucharest)
      // 2. Upload Profile Image
      final imageService = ImageService();
      final profileResult = await imageService.uploadFile(_profileImage!, ApiService.baseUrl);

      if (!profileResult['success']) throw profileResult['error'];

      // 3. Handle Cover Photos (Upload if exist, use default link if empty)
      List<String> coverUrls = [];
      if (_coverPhotos.isNotEmpty) {
        for (var file in _coverPhotos) {
          final res = await imageService.uploadFile(file, ApiService.baseUrl);
          if (res['success']) coverUrls.add(res['data']['file_url']);
        }
      } else {
        // Default placeholder link provided by you
        coverUrls.add("https://www.nordgarage.ro/wp-content/uploads/2015/03/trusted-mechanic.jpg");
      }

      // 4. Fallback values for Bio and Address
      String finalBio = _aboutBusinessController.text.trim();
      if (finalBio.isEmpty) finalBio = "bio";

      String finalAddress = _addressController.text.trim();
      if (finalAddress.isEmpty) finalAddress = "address";

      // 5. Final API Call
      final signupResult = await ApiService().supplierSignup(
        fullName: _businessNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: profileResult['data']['file_url'],
        coverPhotosUrls: coverUrls,
        latitude: latitude,
        longitude: longitude,
        bio: finalBio,
        address: finalAddress,
      );

      if (signupResult['success'] || signupResult['data']?['user_id'] != null) {
        setState(() {
          _userId = signupResult['data']['user_id'];
          _showOtpScreen = true;
        });
      } else {
        throw signupResult['error'];
      }
    } catch (e) {
      _showFeedbackSheet(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
  // Future<void> _onSubmit() async {
  //   setState(() => _submitted = true);
  //   if (!_validate()) return;
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //
  //     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //
  //     final imageService = ImageService();
  //     final profileResult = await imageService.uploadFile(_profileImage!, ApiService.baseUrl);
  //
  //     if (!profileResult['success']) throw profileResult['error'];
  //
  //     // Cover photos are now optional
  //     List<String> coverUrls = [];
  //     if (_coverPhotos.isNotEmpty) {
  //       for (var file in _coverPhotos) {
  //         final res = await imageService.uploadFile(file, ApiService.baseUrl);
  //         if (res['success']) coverUrls.add(res['data']['file_url']);
  //       }
  //     }
  //
  //     final signupResult = await ApiService().supplierSignup(
  //       fullName: _businessNameController.text.trim(),
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //       phone: _phoneController.text.trim(),
  //       photoUrl: profileResult['data']['file_url'],
  //       coverPhotosUrls: coverUrls, // Can be empty list
  //       latitude: position.latitude,
  //       longitude: position.longitude,
  //       bio: _aboutBusinessController.text.trim(), // Can be empty string
  //       address: _addressController.text.trim(), // Can be empty string
  //     );
  //
  //     if (signupResult['success'] || signupResult['data']?['user_id'] != null) {
  //       setState(() { _userId = signupResult['data']['user_id']; _showOtpScreen = true; });
  //     } else {
  //       throw signupResult['error'];
  //     }
  //   } catch (e) {
  //     _showFeedbackSheet(e.toString());
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  // --- UI BUILDERS ---

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isPhone = false, int maxLines = 1, bool isOptional = false}) {
    bool hasError = _submitted && !isOptional && controller.text.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_passwordVisible,
        maxLines: maxLines,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: isOptional ? '${label.toUpperCase()} (OPȚIONAL)' : label.toUpperCase(),
          labelStyle: TextStyle(color: hasError ? kErrorColor : Colors.grey, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: hasError ? kErrorColor : kPrimaryAccent, size: 20),
          suffixIcon: isPassword ? IconButton(icon: Icon(_passwordVisible ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill, size: 18, color: Colors.grey), onPressed: () => setState(() => _passwordVisible = !_passwordVisible)) : null,
          filled: true, fillColor: kSurfaceColor,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: hasError ? kErrorColor : kBorderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryAccent, width: 1.5)),
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
          const SizedBox(height: 70),
          // const Text('CONT MECANIC', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 5, fontFamily: kFontFamily)),
          const SizedBox(height: 40),

          GestureDetector(
            onTap: () => _showImageSourceDialog(true),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  height: 110, width: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kPrimaryAccent, width: 2), color: kSurfaceColor),
                  child: _profileImage == null
                      ? const Icon(CupertinoIcons.camera_fill, color: Colors.white24, size: 40)
                      : ClipOval(child: Image.file(_profileImage!, fit: BoxFit.cover)),
                ),
                Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: kPrimaryAccent, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 20)),
              ],
            ),
          ),

          const SizedBox(height: 40),
          _buildTextField(_businessNameController, 'Nume Afacere', CupertinoIcons.briefcase_fill),
          _buildTextField(_emailController, 'Email Contact', CupertinoIcons.envelope_fill),
          _buildTextField(_phoneController, 'Telefon', CupertinoIcons.phone_fill, isPhone: true),
          _buildTextField(_passwordController, 'Parolă', CupertinoIcons.lock_fill, isPassword: true),
          _buildTextField(_confirmPasswordController, 'Confirmă Parolă', CupertinoIcons.lock_fill, isPassword: true),

          // Optional Fields
          _buildTextField(_addressController, 'Adresă Sediu', CupertinoIcons.location_solid, isOptional: true),
          _buildTextField(_aboutBusinessController, 'Descriere Servicii', CupertinoIcons.doc_text_fill, maxLines: 3, isOptional: true),

          const SizedBox(height: 10),
          const Align(alignment: Alignment.centerLeft, child: Text('FOTOGRAFII PORTOFOLIU (OPȚIONAL)', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: _coverPhotos.length + 1,
            itemBuilder: (context, index) {
              if (index == _coverPhotos.length) {
                return GestureDetector(
                  onTap: () => _showImageSourceDialog(false),
                  child: DottedBorder(color: kBorderColor, borderType: BorderType.RRect, radius: const Radius.circular(16), child: const Center(child: Icon(Icons.add_a_photo, color: kPrimaryAccent))),
                );
              }
              return Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_coverPhotos[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
                Positioned(top: 5, right: 5, child: GestureDetector(onTap: () => setState(() => _coverPhotos.removeAt(index)), child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white))))
              ]);
            },
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onSubmit,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isLoading ? const CupertinoActivityIndicator(color: Colors.white) : const Text('CREEAZĂ CONT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- UPDATED BOTTOM-UP IMAGE SOURCE DIALOG ---
  void _showImageSourceDialog(bool isProfile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: kBorderColor)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('SELECTEAZĂ SURSA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: kFontFamily)),
            const SizedBox(height: 20),
            _dialogOption(
                icon: CupertinoIcons.camera_fill,
                text: 'Cameră Foto',
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera, isProfile); }
            ),
            const SizedBox(height: 12),
            _dialogOption(
                icon: CupertinoIcons.photo_on_rectangle,
                text: 'Galerie Imagini',
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery, isProfile); }
            ),
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

  Future<void> _pickImage(ImageSource source, bool isProfile) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final imageService = ImageService();
      final compressed = await imageService.compressImage(File(pickedFile.path));
      if (compressed != null) {
        setState(() {
          if (isProfile) _profileImage = compressed;
          else if (_coverPhotos.length < 5) _coverPhotos.add(compressed);
        });
      }
    }
  }

  Widget _buildOtpBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.shield_lefthalf_fill, color: kPrimaryAccent, size: 60),
            const SizedBox(height: 24),
            const Text('VERIFICARE COD', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, fontFamily: kFontFamily)),
            const SizedBox(height: 8),
            Text('Trimis la ${_emailController.text}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            Pinput(
              length: 6, controller: _otpController,
              onCompleted: (pin) => _verifyOtp(),
              defaultPinTheme: PinTheme(width: 50, height: 55, textStyle: const TextStyle(color: Colors.white, fontSize: 20), decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor))),
            ),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _verifyOtp, style: ElevatedButton.styleFrom(backgroundColor: kPrimaryAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('VERIFICĂ' , style:  TextStyle(color: Colors.white),))),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    final result = await ApiService().validateOtp(_userId!, _otpController.text);
    setState(() => _isLoading = false);
    if (result['success']) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => login_screen(initialEmail: _emailController.text, initialPassword: _passwordController.text)), (route) => false);
    } else {
      _showFeedbackSheet(result['error'] ?? 'Cod invalid.');
    }
  }
}