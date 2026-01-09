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
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Show high-end feedback for GPS failure
        _showFeedbackSheet(
          "Accesul la locație a fost refuzat. Vă rugăm să activați permisiunile GPS din setările telefonului pentru a ne permite să vă afișăm pe hartă.",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

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
        latitude: position.latitude,
        longitude: position.longitude,
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
// import 'package:dotted_border/dotted_border.dart';
// import 'package:fixcars/shared/screens/Server_down_screen.dart';
// import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'dart:io';
// import 'package:pinput/pinput.dart';
// import '../services/ImageService.dart';
// import '../services/api_service.dart';
// import 'login_screen.dart';
//
// class SupplierSignupScreen extends StatefulWidget {
//   @override
//   _SupplierSignupScreenState createState() => _SupplierSignupScreenState();
// }
//
// class _SupplierSignupScreenState extends State<SupplierSignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _businessNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _confirmEmailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _confirmPhoneController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _aboutBusinessController = TextEditingController();
//   final _otpController = TextEditingController();
//
//   File? _profileImage;
//   List<File> _coverPhotos = [];
//   final ImagePicker _picker = ImagePicker();
//   bool _showOtpScreen = false;
//   bool _isLoading = false;
//   String? _userId;
//
//   // Error messages for each field
//   String? _businessNameError;
//   String? _emailError;
//   String? _confirmEmailError;
//   String? _phoneError;
//   String? _confirmPhoneError;
//   String? _passwordError;
//   String? _confirmPasswordError;
//   String? _addressError;
//   String? _aboutBusinessError;
//   String? _profileImageError;
//   String? _coverPhotosError;
//
//   @override
//   void dispose() {
//     _businessNameController.dispose();
//     _emailController.dispose();
//     _confirmEmailController.dispose();
//     _phoneController.dispose();
//     _confirmPhoneController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _addressController.dispose();
//     _aboutBusinessController.dispose();
//     _otpController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickProfileImage(ImageSource source) async {
//     final pickedFile = await _picker.pickImage(source: source);
//     if (pickedFile != null) {
//       final imageService = ImageService();
//       final compressedFile = await imageService.compressImage(
//         File(pickedFile.path),
//       );
//       if (compressedFile != null) {
//         setState(() {
//           _profileImage = compressedFile;
//           _profileImageError = null;
//         });
//       } else {
//         setState(() {
//           _profileImageError = 'Eroare la compresia imaginii';
//         });
//       }
//     }
//   }
//
//   Future<void> _pickCoverImage(ImageSource source) async {
//     final pickedFile = await _picker.pickImage(source: source);
//     if (pickedFile != null && _coverPhotos.length < 5) {
//       final imageService = ImageService();
//       final compressedFile = await imageService.compressImage(
//         File(pickedFile.path),
//       );
//       if (compressedFile != null) {
//         setState(() {
//           _coverPhotos.add(compressedFile);
//           _coverPhotosError = null;
//         });
//       } else {
//         setState(() {
//           _coverPhotosError = 'Eroare la compresia imaginii';
//         });
//       }
//     }
//   }
//
//   // Future<void> _pickProfileImage(ImageSource source) async {
//   //   final pickedFile = await _picker.pickImage(source: source);
//   //   if (pickedFile != null) {
//   //     setState(() {
//   //       _profileImage = File(pickedFile.path);
//   //       _profileImageError = null;
//   //     });
//   //   }
//   // }
//   //
//   // Future<void> _pickCoverImage(ImageSource source) async {
//   //   final pickedFile = await _picker.pickImage(source: source);
//   //   if (pickedFile != null && _coverPhotos.length < 5) {
//   //     setState(() {
//   //       _coverPhotos.add(File(pickedFile.path));
//   //       _coverPhotosError = null;
//   //     });
//   //   }
//   // }
//
//   void _removeProfileImage() {
//     setState(() {
//       _profileImage = null;
//     });
//   }
//
//   void _removeCoverImage(int index) {
//     setState(() {
//       _coverPhotos.removeAt(index);
//     });
//   }
//
//   void _showImageSourceDialog(bool isProfile) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         insetPadding: EdgeInsets.symmetric(horizontal: 24),
//         child: Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 15,
//                 offset: Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Selectați sursa imaginii',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               _dialogOption(
//                 icon: Icons.camera_alt_rounded,
//                 text: 'Cameră',
//                 onTap: () {
//                   Navigator.pop(context);
//                   isProfile
//                       ? _pickProfileImage(ImageSource.camera)
//                       : _pickCoverImage(ImageSource.camera);
//                 },
//               ),
//
//               SizedBox(height: 10),
//
//               _dialogOption(
//                 icon: Icons.photo_library_rounded,
//                 text: 'Galerie',
//                 onTap: () {
//                   Navigator.pop(context);
//                   isProfile
//                       ? _pickProfileImage(ImageSource.gallery)
//                       : _pickCoverImage(ImageSource.gallery);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _dialogOption({
//     required IconData icon,
//     required String text,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(14),
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           color: Colors.grey.shade100,
//         ),
//         child: Row(
//           children: [
//             Icon(icon, size: 26, color: Colors.black87),
//             SizedBox(width: 12),
//             Text(
//               text,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//
//   Future<void> _onSubmit() async {
//     if (!_validateForm()) {
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     // Get location
//     double latitude;
//     double longitude;
//     try {
//       bool hasPermission = await _checkLocationPermission();
//       if (!hasPermission) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Permisiunea de localizare este obligatorie.'),
//           ),
//         );
//         return;
//       }
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       latitude = position.latitude;
//       longitude = position.longitude;
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Eroare la obținerea locației: $e')),
//       );
//       return;
//     }
//
//     // Initialize ImageService
//     final imageService = ImageService();
//
//     // Upload profile image
//     String? profilePhotoUrl;
//     if (_profileImage != null) {
//       final profileUploadResult = await imageService.uploadFile(
//         _profileImage!,
//         ApiService.baseUrl,
//       );
//       print("Profile Upload Result: $profileUploadResult");
//       if (!profileUploadResult['success']) {
//         setState(() {
//           _isLoading = false;
//           _profileImageError =
//               'Eroare la încărcarea imaginii de profil: ${profileUploadResult['error']}';
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Eroare la încărcarea imaginii de profil: ${profileUploadResult['error']}',
//             ),
//           ),
//         );
//         return;
//       }
//       profilePhotoUrl = profileUploadResult['data']['file_url'];
//     }
//
//     // Upload cover photos (continue on failure)
//     List<String> coverPhotoUrls = [];
//     List<String> failedUploads = [];
//     for (var photo in _coverPhotos) {
//       final uploadResult = await imageService.uploadFile(
//         photo,
//         ApiService.baseUrl,
//       );
//       print("Cover Photo Upload Result: $uploadResult");
//       if (uploadResult['success']) {
//         coverPhotoUrls.add(uploadResult['data']['file_url']);
//       } else {
//         failedUploads.add(uploadResult['error']);
//       }
//     }
//
//     if (failedUploads.isNotEmpty) {
//       setState(() {
//         _coverPhotosError =
//             'Unele fotografii nu au fost încărcate: ${failedUploads.join(", ")}';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Unele fotografii nu au fost încărcate. Continuăm cu imaginile încărcate.',
//           ),
//         ),
//       );
//     }
//
//     if (profilePhotoUrl == null) {
//       setState(() {
//         _isLoading = false;
//         _profileImageError = 'Imaginea de profil este obligatorie';
//       });
//       return;
//     }
//
//     // Perform signup
//     final signupResult = await ApiService().supplierSignup(
//       fullName: _businessNameController.text.trim(),
//       email: _emailController.text.trim(),
//       password: _passwordController.text.trim(),
//       phone: _phoneController.text.trim(),
//       photoUrl: profilePhotoUrl,
//       coverPhotosUrls: coverPhotoUrls,
//       latitude: latitude,
//       longitude: longitude,
//       bio: _aboutBusinessController.text.trim(),
//       address: _addressController.text.trim(),
//     );
//
//     setState(() {
//       _isLoading = false;
//     });
//
//     if (signupResult['success'] || signupResult['data']?['user_id'] != null) {
//       setState(() {
//         _userId = signupResult['data']['user_id'];
//         _showOtpScreen = true;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             signupResult['data']['message'] ?? 'Vă rugăm să verificați OTP-ul.',
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(signupResult['error'] ?? 'Eroare la înregistrare'),
//         ),
//       );
//     }
//   }
//
//
//
//   bool _validateForm() {
//     bool isValid = true;
//
//     setState(() {
//       // Reset all error messages
//       _businessNameError = null;
//       _emailError = null;
//       _confirmEmailError = null;
//       _phoneError = null;
//       _confirmPhoneError = null;
//       _passwordError = null;
//       _confirmPasswordError = null;
//       _addressError = null;
//       _aboutBusinessError = null;
//       _profileImageError = null;
//       _coverPhotosError = null;
//
//       // Validate each field (check trimmed values)
//       if (_businessNameController.text.trim().isEmpty) {
//         _businessNameError = 'Numele afacerii este obligatoriu';
//         isValid = false;
//       }
//
//       if (_emailController.text.trim().isEmpty) {
//         _emailError = 'Emailul este obligatoriu';
//         isValid = false;
//       } else if (!RegExp(
//         r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//       ).hasMatch(_emailController.text.trim())) {
//         _emailError = 'Introduceți un email valid';
//         isValid = false;
//       }
//
//       if (_confirmEmailController.text.trim().isEmpty) {
//         _confirmEmailError = 'Confirmarea emailului este obligatorie';
//         isValid = false;
//       } else if (_confirmEmailController.text.trim() !=
//           _emailController.text.trim()) {
//         _confirmEmailError = 'Emailurile nu coincid';
//         isValid = false;
//       }
//
//       if (_phoneController.text.trim().isEmpty) {
//         _phoneError = 'Numărul de telefon este obligatoriu';
//         isValid = false;
//       } else if (_phoneController.text.trim().length != 10) {
//         _phoneError = 'Numărul de telefon trebuie să aibă 10 cifre';
//         isValid = false;
//       }
//
//       if (_confirmPhoneController.text.trim().isEmpty) {
//         _confirmPhoneError =
//             'Confirmarea numărului de telefon este obligatorie';
//         isValid = false;
//       } else if (_confirmPhoneController.text.trim() !=
//           _phoneController.text.trim()) {
//         _confirmPhoneError = 'Numerele de telefon nu coincid';
//         isValid = false;
//       }
//
//       if (_passwordController.text.trim().isEmpty) {
//         _passwordError = 'Parola este obligatorie';
//         isValid = false;
//       } else if (_passwordController.text.trim().length < 8) {
//         _passwordError = 'Parola trebuie să aibă minim 8 caractere';
//         isValid = false;
//       }
//
//       if (_confirmPasswordController.text.trim().isEmpty) {
//         _confirmPasswordError = 'Confirmarea parolei este obligatorie';
//         isValid = false;
//       } else if (_confirmPasswordController.text.trim() !=
//           _passwordController.text.trim()) {
//         _confirmPasswordError = 'Parolele nu coincid';
//         isValid = false;
//       }
//
//       if (_addressController.text.trim().isEmpty) {
//         _addressError = 'Adresa este obligatorie';
//         isValid = false;
//       }
//
//       if (_aboutBusinessController.text.trim().isEmpty) {
//         _aboutBusinessError = 'Descrierea afacerii este obligatorie';
//         isValid = false;
//       }
//
//       if (_profileImage == null) {
//         _profileImageError = 'Imaginea de profil este obligatorie';
//         isValid = false;
//       }
//
//       if (_coverPhotos.isEmpty) {
//         _coverPhotosError =
//             'Cel puțin o fotografie de copertă este obligatorie';
//         isValid = false;
//       }
//     });
//
//     return isValid;
//   }
//
//   Future<bool> _checkLocationPermission() async {
//     // Check if location services are enabled
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Serviciile de localizare sunt dezactivate.')),
//       );
//       return false;
//     }
//
//     // Check location permission status
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Permisiunile de localizare au fost refuzate.'),
//           ),
//         );
//         return false;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Permisiunile de localizare sunt permanent refuzate. Vă rugăm să le activați manual din setări.',
//           ),
//         ),
//       );
//       return false;
//     }
//
//     return true;
//   }
//
//   Future<void> _verifyOtp() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     final result = await ApiService().validateOtp(
//       _userId!,
//       _otpController.text,
//     );
//
//     setState(() {
//       _isLoading = false;
//     });
//
//     if (result['success']) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(result['data']['message'])));
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder:
//               (context) => login_screen(
//                 initialEmail: _emailController.text,
//                 initialPassword: _passwordController.text,
//               ),
//         ),
//         (Route<dynamic> route) => false,
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result['error'] ?? 'Eroare la verificarea OTP-ului'),
//         ),
//       );
//     }
//   }
//
//   Future<void> _resendOtp() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     final result = await ApiService().resendOtp(_userId!);
//
//     setState(() {
//       _isLoading = false;
//     });
//
//     if (result['success']) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(result['data']['message'])));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result['error'] ?? 'Eroare la retrimiterea OTP-ului'),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return InternetConnectivityScreen(
//       child: ServerDownWrapper(
//         apiService: ApiService(),
//         child: Scaffold(
//           backgroundColor: Color(0xFFF9FAFB),
//           body: Stack(
//             children: [
//               Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child:
//                     _showOtpScreen
//                         ? _buildOtpScreen()
//                         : SingleChildScrollView(
//                           child: Form(
//                             key: _formKey,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 SizedBox(height: 40),
//                                 Text(
//                                   'Înregistrare Furnizor',
//                                   style: TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 SizedBox(height: 30),
//
//                                 // Profile Image
//                                 Center(
//                                   child: Column(
//                                     children: [
//                                       GestureDetector(
//                                         onTap:
//                                             () => _showImageSourceDialog(true),
//                                         child: Container(
//                                           width: 100,
//                                           height: 100,
//                                           child: DottedBorder(
//                                             borderType: BorderType.Circle,
//                                             color: Colors.grey,
//                                             strokeWidth: 2.0,
//                                             dashPattern: const [5, 3],
//                                             // [dash length, gap length]
//                                             child: Container(
//                                               decoration: const BoxDecoration(
//                                                 color: Color(0xFFF3F4F6),
//                                                 shape: BoxShape.circle,
//                                               ),
//                                               child:
//                                                   _profileImage == null
//                                                       ? Column(
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .center,
//                                                         children: [
//                                                           Center(
//                                                             child: Image.asset(
//                                                               'assets/person.png',
//                                                               width: 30,
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       )
//                                                       : ClipOval(
//                                                         child: Image.file(
//                                                           _profileImage!,
//                                                           fit: BoxFit.cover,
//                                                           width: 100,
//                                                           height: 100,
//                                                         ),
//                                                       ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       if (_profileImageError != null)
//                                         Padding(
//                                           padding: EdgeInsets.only(top: 4),
//                                           child: Text(
//                                             _profileImageError!,
//                                             style: TextStyle(
//                                               color: Colors.red,
//                                               fontSize: 12,
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(height: 20),
//
//                                 // Informații de afaceri section
//                                 Text(
//                                   'Informații de afaceri',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildTextField(
//                                   controller: _businessNameController,
//                                   label: 'Numele complet al afacerii',
//                                   hint: 'Ex: Restaurant Bella',
//                                   iconPath: 'assets/business.png',
//                                   errorText: _businessNameError,
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildTextField(
//                                   controller: _emailController,
//                                   label: 'Adresa de email',
//                                   hint: 'Ex: contact@restaurantbella.ro',
//                                   iconPath: 'assets/email.png',
//                                   keyboardType: TextInputType.emailAddress,
//                                   errorText: _emailError,
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildTextField(
//                                   controller: _confirmEmailController,
//                                   label: 'Confirmare email',
//                                   hint: 'Ex: contact@restaurantbella.ro',
//                                   iconPath: 'assets/email.png',
//                                   keyboardType: TextInputType.emailAddress,
//                                   errorText: _confirmEmailError,
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildTextField(
//                                   suffixIcon: GestureDetector(
//                                     onTap:
//                                         () => _showPhonePromotionInfo(context),
//                                     // <-- changed here
//                                     child: Container(
//                                       margin: const EdgeInsets.all(10),
//                                       decoration: const BoxDecoration(
//                                         color: Color(0xFFF3F4F6),
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: const Icon(
//                                         Icons.help_outline_rounded,
//                                         color: Color(0xFF4B5563),
//                                         size: 18,
//                                       ),
//                                     ),
//                                   ),
//                                   controller: _phoneController,
//                                   label: 'Număr de telefon',
//                                   hint: 'Ex: 0712345678',
//                                   iconPath: 'assets/phone.png',
//                                   keyboardType: TextInputType.phone,
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.digitsOnly,
//                                     LengthLimitingTextInputFormatter(10),
//                                   ],
//                                   errorText: _phoneError,
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildTextField(
//                                   controller: _confirmPhoneController,
//                                   label: 'Confirmare număr de telefon',
//                                   hint: 'Ex: 0712345678',
//                                   iconPath: 'assets/phone.png',
//                                   keyboardType: TextInputType.phone,
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.digitsOnly,
//                                     LengthLimitingTextInputFormatter(10),
//                                   ],
//                                   errorText: _confirmPhoneError,
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildTextField(
//                                   controller: _passwordController,
//                                   label: 'Parolă',
//                                   hint: 'Minim 8 caractere',
//                                   iconPath: 'assets/loc.png',
//                                   obscureText: true,
//                                   errorText: _passwordError,
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildTextField(
//                                   controller: _confirmPasswordController,
//                                   label: 'Confirmare parolă',
//                                   hint: 'Minim 8 caractere',
//                                   iconPath: 'assets/loc.png',
//                                   obscureText: true,
//                                   errorText: _confirmPasswordError,
//                                 ),
//
//                                 SizedBox(height: 30),
//
//                                 // Locație section
//                                 Text(
//                                   'Locație',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildTextField(
//                                   controller: _addressController,
//                                   label: 'Adresa afacerii',
//                                   hint:
//                                       'Ex: Strada Principală nr. 10, București',
//                                   iconPath: 'assets/locationd2.png',
//                                   errorText: _addressError,
//                                 ),
//
//                                 SizedBox(height: 30),
//
//                                 // Despre afacerea ta section
//                                 Text(
//                                   'Despre afacerea ta',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 SizedBox(height: 16),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     TextField(
//                                       controller: _aboutBusinessController,
//                                       maxLines: 4,
//                                       decoration: InputDecoration(
//                                         labelText:
//                                             'Spune-ne despre afacerea ta...',
//                                         hintText:
//                                             'Descrieți serviciile oferite...',
//                                         hintStyle: TextStyle(
//                                           color: Colors.grey,
//                                         ),
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             8.0,
//                                           ),
//                                           borderSide: BorderSide.none,
//                                         ),
//                                       ),
//                                     ),
//                                     if (_aboutBusinessError != null)
//                                       Padding(
//                                         padding: EdgeInsets.only(top: 4),
//                                         child: Text(
//                                           _aboutBusinessError!,
//                                           style: TextStyle(
//                                             color: Colors.red,
//                                             fontSize: 12,
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//
//                                 SizedBox(height: 30),
//
//                                 // Fotografii de copertă section
//                                 Text(
//                                   '1. Fotografii de copertă',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 SizedBox(height: 8),
//                                 Text(
//                                   'Poți alege până la 5 fotografii pentru copertă.',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                                 SizedBox(height: 16),
//
//                                 // Cover photos grid
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     GridView.builder(
//                                       shrinkWrap: true,
//                                       physics: NeverScrollableScrollPhysics(),
//                                       gridDelegate:
//                                           SliverGridDelegateWithFixedCrossAxisCount(
//                                             crossAxisCount: 3,
//                                             crossAxisSpacing: 8,
//                                             mainAxisSpacing: 8,
//                                             childAspectRatio: 1,
//                                           ),
//                                       itemCount: _coverPhotos.length + 1,
//                                       itemBuilder: (context, index) {
//                                         if (index == _coverPhotos.length) {
//                                           return _coverPhotos.length < 5
//                                               ? GestureDetector(
//                                                 onTap:
//                                                     () =>
//                                                         _showImageSourceDialog(
//                                                           false,
//                                                         ),
//                                                 child: Container(
//                                                   child: DottedBorder(
//                                                     borderType:
//                                                         BorderType.RRect,
//                                                     radius:
//                                                         const Radius.circular(
//                                                           8.0,
//                                                         ),
//                                                     color: Colors.grey,
//                                                     strokeWidth: 2.0,
//                                                     dashPattern: const [5, 3],
//                                                     // [dash length, gap length]
//                                                     child: Container(
//                                                       decoration: BoxDecoration(
//                                                         color: Colors.white,
//                                                         borderRadius:
//                                                             BorderRadius.circular(
//                                                               8.0,
//                                                             ),
//                                                       ),
//                                                       child: Center(
//                                                         child: Column(
//                                                           mainAxisAlignment:
//                                                               MainAxisAlignment
//                                                                   .center,
//                                                           children: [
//                                                             Image.asset(
//                                                               'assets/img.png',
//                                                               width: 30,
//                                                             ),
//                                                             SizedBox(height: 4),
//                                                             Text(
//                                                               'Adaugă fotografie',
//                                                               style: TextStyle(
//                                                                 fontSize: 10,
//                                                                 color:
//                                                                     Colors.grey,
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               )
//                                               : SizedBox.shrink();
//                                         }
//
//                                         return Stack(
//                                           children: [
//                                             ClipRRect(
//                                               borderRadius:
//                                                   BorderRadius.circular(8.0),
//                                               child: Image.file(
//                                                 _coverPhotos[index],
//                                                 fit: BoxFit.cover,
//                                                 width: double.infinity,
//                                                 height: double.infinity,
//                                               ),
//                                             ),
//                                             Positioned(
//                                               top: 0,
//                                               right: 0,
//                                               child: GestureDetector(
//                                                 onTap:
//                                                     () => _removeCoverImage(
//                                                       index,
//                                                     ),
//                                                 child: Container(
//                                                   decoration: BoxDecoration(
//                                                     color: Colors.black54,
//                                                     shape: BoxShape.circle,
//                                                   ),
//                                                   child: Icon(
//                                                     Icons.close,
//                                                     size: 20,
//                                                     color: Colors.white,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         );
//                                       },
//                                     ),
//                                     if (_coverPhotosError != null)
//                                       Padding(
//                                         padding: EdgeInsets.only(top: 4),
//                                         child: Text(
//                                           _coverPhotosError!,
//                                           style: TextStyle(
//                                             color: Colors.red,
//                                             fontSize: 12,
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//
//                                 SizedBox(height: 30),
//
//                                 ElevatedButton(
//                                   onPressed: _isLoading ? null : _onSubmit,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Color(0xFF4B5563),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8.0),
//                                     ),
//                                     minimumSize: Size(double.infinity, 50),
//                                   ),
//                                   child: Text(
//                                     'Finalizare înregistrare',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(height: 150),
//                               ],
//                             ),
//                           ),
//                         ),
//               ),
//               if (_isLoading)
//                 Center(
//                   child: LoadingAnimationWidget.threeArchedCircle(
//                     color: Color(0xFF4B5563),
//                     size: 40,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOtpScreen() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         SizedBox(height: 100),
//         Center(
//           child: Text(
//             'Verificați telefonul',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//         SizedBox(height: 20),
//         Center(
//           child: Text(
//             'Am trimis un cod de verificare la',
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//         Center(
//           child: Text(
//             _emailController.text,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//         ),
//         SizedBox(height: 40),
//         Center(
//           child: Pinput(
//             length: 6,
//             controller: _otpController,
//             defaultPinTheme: PinTheme(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey),
//               ),
//             ),
//           ),
//         ),
//         SizedBox(height: 40),
//         ElevatedButton(
//           onPressed: _isLoading ? null : _verifyOtp,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Color(0xFF4B5563),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8.0),
//             ),
//             minimumSize: Size(double.infinity, 50),
//           ),
//           child: Text(
//             'Verifică și continuă',
//             style: TextStyle(fontSize: 18, color: Colors.white),
//           ),
//         ),
//         SizedBox(height: 10),
//         Center(
//           child: TextButton(
//             onPressed: _isLoading ? null : _resendOtp,
//             child: Text('Nu ați primit codul? Trimiteți din nou'),
//           ),
//         ),
//         Expanded(child: SizedBox(height: 10)),
//       ],
//     );
//   }
//
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required String iconPath,
//     bool obscureText = false,
//     Widget? suffixIcon = null,
//     TextInputType keyboardType = TextInputType.text,
//     List<TextInputFormatter>? inputFormatters,
//     String? errorText,
//   }) {
//     // 1. Declare and initialize the mutable state outside the builder.
//     // We use a list/array here because variables declared outside of the
//     // builder are effectively 'final' and cannot be reassigned (like 'bool isCurrentlyObscured = obscureText;').
//     // A single-element list allows us to mutate its content.
//     final List<bool> _isCurrentlyObscured = [obscureText];
//
//     // If it's a password field, wrap the column in StatefulBuilder to manage the toggle icon state.
//     if (obscureText) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextField(
//                 controller: controller,
//                 // 2. Read the persistent state from the list.
//                 obscureText: _isCurrentlyObscured[0],
//                 keyboardType: keyboardType,
//                 inputFormatters: inputFormatters,
//                 decoration: InputDecoration(
//                   // Add the show/hide password icon
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       // 3. Choose icon based on the persistent state
//                       _isCurrentlyObscured[0]
//                           ? Icons.visibility_off
//                           : Icons.visibility,
//                       color: Colors.grey,
//                     ),
//                     onPressed: () {
//                       // 4. Toggle the persistent state and trigger rebuild
//                       setState(() {
//                         _isCurrentlyObscured[0] = !_isCurrentlyObscured[0];
//                       });
//                     },
//                   ),
//                   labelText: label,
//                   hintText: hint,
//                   hintStyle: TextStyle(color: Colors.grey),
//                   prefixIcon: Padding(
//                     padding: EdgeInsets.only(left: 12, right: 8),
//                     child: Image.asset(iconPath, width: 20, height: 20),
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8.0),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//               ),
//               if (errorText != null)
//                 Padding(
//                   padding: EdgeInsets.only(top: 4),
//                   child: Text(
//                     errorText,
//                     style: TextStyle(color: Colors.red, fontSize: 12),
//                   ),
//                 ),
//             ],
//           );
//         },
//       );
//     }
//
//     // Original structure for non-password fields (obscureText is false)
//     // This part is unchanged and avoids the StatefulBuilder overhead.
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextField(
//           controller: controller,
//           obscureText: obscureText,
//           keyboardType: keyboardType,
//           inputFormatters: inputFormatters,
//           decoration: InputDecoration(
//             suffixIcon: suffixIcon,
//             labelText: label,
//             hintText: hint,
//             hintStyle: TextStyle(color: Colors.grey),
//             prefixIcon: Padding(
//               padding: EdgeInsets.only(left: 12, right: 8),
//               child: Image.asset(iconPath, width: 20, height: 20),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8.0),
//               borderSide: BorderSide.none,
//             ),
//           ),
//         ),
//         if (errorText != null)
//           Padding(
//             padding: EdgeInsets.only(top: 4),
//             child: Text(
//               errorText,
//               style: TextStyle(color: Colors.red, fontSize: 12),
//             ),
//           ),
//       ],
//     );
//   }
//
//
//   // Widget _buildTextField({
//   //   required TextEditingController controller,
//   //   required String label,
//   //   required String hint,
//   //   required String iconPath,
//   //   bool obscureText = false,
//   //   Widget? suffixIcon = null,
//   //   TextInputType keyboardType = TextInputType.text,
//   //   List<TextInputFormatter>? inputFormatters,
//   //   String? errorText,
//   // }) {
//   //   return Column(
//   //     crossAxisAlignment: CrossAxisAlignment.start,
//   //     children: [
//   //       TextField(
//   //         controller: controller,
//   //         obscureText: obscureText,
//   //         keyboardType: keyboardType,
//   //         inputFormatters: inputFormatters,
//   //         decoration: InputDecoration(
//   //           // SAME elegant icon with your color
//   //           suffixIcon: suffixIcon,
//   //           labelText: label,
//   //           hintText: hint,
//   //           hintStyle: TextStyle(color: Colors.grey),
//   //           prefixIcon: Padding(
//   //             padding: EdgeInsets.only(left: 12, right: 8),
//   //             child: Image.asset(iconPath, width: 20, height: 20),
//   //           ),
//   //           filled: true,
//   //           fillColor: Colors.white,
//   //           border: OutlineInputBorder(
//   //             borderRadius: BorderRadius.circular(8.0),
//   //             borderSide: BorderSide.none,
//   //           ),
//   //         ),
//   //       ),
//   //       if (errorText != null)
//   //         Padding(
//   //           padding: EdgeInsets.only(top: 4),
//   //           child: Text(
//   //             errorText,
//   //             style: TextStyle(color: Colors.red, fontSize: 12),
//   //           ),
//   //         ),
//   //     ],
//   //   );
//   // }
//
//   void _showPhonePromotionInfo(BuildContext context) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => Dialog(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 double maxWidth =
//                     constraints.maxWidth > 400
//                         ? 360
//                         : constraints.maxWidth * 0.9;
//
//                 return ConstrainedBox(
//                   constraints: BoxConstraints(maxWidth: maxWidth),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Title with icon
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(6),
//                               decoration: const BoxDecoration(
//                                 color: Color(0xFFF3F4F6),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(
//                                 Icons.help_outline_rounded,
//                                 color: Color(0xFF4B5563),
//                                 size: 20,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             const Expanded(
//                               child: Text(
//                                 'De ce avem nevoie de numărul tău de telefon?',
//                                 style: TextStyle(
//                                   fontSize: 17,
//                                   fontWeight: FontWeight.bold,
//                                   color: Color(0xFF1F2937),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//
//                         // NEW message – perfectly wrapped
//                         const Text(
//                           'Numărul tău de telefon va fi folosit pentru a-ți promova afacerea, permițând mai multor clienți să te contacteze direct.',
//                           style: TextStyle(
//                             fontSize: 15,
//                             color: Color(0xFF4B5563),
//                             height: 1.5,
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//
//                         // Close button
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () => Navigator.of(context).pop(),
//                             style: TextButton.styleFrom(
//                               foregroundColor: const Color(0xFF4B5563),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 10,
//                               ),
//                             ),
//                             child: const Text(
//                               'Am înțeles',
//                               style: TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//     );
//   }
// }
