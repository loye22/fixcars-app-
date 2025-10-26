import 'package:dotted_border/dotted_border.dart';
import 'package:fixcars/shared/screens/Server_down_screen.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:io';
import 'package:pinput/pinput.dart';
import '../services/ImageService.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SupplierSignupScreen extends StatefulWidget {
  @override
  _SupplierSignupScreenState createState() => _SupplierSignupScreenState();
}

class _SupplierSignupScreenState extends State<SupplierSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPhoneController = TextEditingController();
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
  String? _userId;

  // Error messages for each field
  String? _businessNameError;
  String? _emailError;
  String? _confirmEmailError;
  String? _phoneError;
  String? _confirmPhoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _addressError;
  String? _aboutBusinessError;
  String? _profileImageError;
  String? _coverPhotosError;

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _phoneController.dispose();
    _confirmPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _aboutBusinessController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final imageService = ImageService();
      final compressedFile = await imageService.compressImage(File(pickedFile.path));
      if (compressedFile != null) {
        setState(() {
          _profileImage = compressedFile;
          _profileImageError = null;
        });
      } else {
        setState(() {
          _profileImageError = 'Eroare la compresia imaginii';
        });
      }
    }
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null && _coverPhotos.length < 5) {
      final imageService = ImageService();
      final compressedFile = await imageService.compressImage(File(pickedFile.path));
      if (compressedFile != null) {
        setState(() {
          _coverPhotos.add(compressedFile);
          _coverPhotosError = null;
        });
      } else {
        setState(() {
          _coverPhotosError = 'Eroare la compresia imaginii';
        });
      }
    }
  }
  // Future<void> _pickProfileImage(ImageSource source) async {
  //   final pickedFile = await _picker.pickImage(source: source);
  //   if (pickedFile != null) {
  //     setState(() {
  //       _profileImage = File(pickedFile.path);
  //       _profileImageError = null;
  //     });
  //   }
  // }
  //
  // Future<void> _pickCoverImage(ImageSource source) async {
  //   final pickedFile = await _picker.pickImage(source: source);
  //   if (pickedFile != null && _coverPhotos.length < 5) {
  //     setState(() {
  //       _coverPhotos.add(File(pickedFile.path));
  //       _coverPhotosError = null;
  //     });
  //   }
  // }

  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
    });
  }

  void _removeCoverImage(int index) {
    setState(() {
      _coverPhotos.removeAt(index);
    });
  }

  void _showImageSourceDialog(bool isProfile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Selectați sursa imaginii'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Cameră'),
              onTap: () {
                Navigator.pop(context);
                isProfile ? _pickProfileImage(ImageSource.camera) : _pickCoverImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galerie'),
              onTap: () {
                Navigator.pop(context);
                isProfile ? _pickProfileImage(ImageSource.gallery) : _pickCoverImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get location
    double latitude;
    double longitude;
    try {
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permisiunea de localizare este obligatorie.')),
        );
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la obținerea locației: $e')),
      );
      return;
    }

    // Initialize ImageService
    final imageService = ImageService();

    // Upload profile image
    String? profilePhotoUrl;
    if (_profileImage != null) {
      final profileUploadResult = await imageService.uploadFile(_profileImage!, ApiService.baseUrl);
      print("Profile Upload Result: $profileUploadResult");
      if (!profileUploadResult['success']) {
        setState(() {
          _isLoading = false;
          _profileImageError = 'Eroare la încărcarea imaginii de profil: ${profileUploadResult['error']}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcarea imaginii de profil: ${profileUploadResult['error']}')),
        );
        return;
      }
      profilePhotoUrl = profileUploadResult['data']['file_url'];
    }

    // Upload cover photos (continue on failure)
    List<String> coverPhotoUrls = [];
    List<String> failedUploads = [];
    for (var photo in _coverPhotos) {
      final uploadResult = await imageService.uploadFile(photo, ApiService.baseUrl);
      print("Cover Photo Upload Result: $uploadResult");
      if (uploadResult['success']) {
        coverPhotoUrls.add(uploadResult['data']['file_url']);
      } else {
        failedUploads.add(uploadResult['error']);
      }
    }

    if (failedUploads.isNotEmpty) {
      setState(() {
        _coverPhotosError = 'Unele fotografii nu au fost încărcate: ${failedUploads.join(", ")}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unele fotografii nu au fost încărcate. Continuăm cu imaginile încărcate.')),
      );
    }

    if (profilePhotoUrl == null) {
      setState(() {
        _isLoading = false;
        _profileImageError = 'Imaginea de profil este obligatorie';
      });
      return;
    }

    // Perform signup
    final signupResult = await ApiService().supplierSignup(
      fullName: _businessNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
      photoUrl: profilePhotoUrl,
      coverPhotosUrls: coverPhotoUrls,
      latitude: latitude,
      longitude: longitude,
      bio: _aboutBusinessController.text.trim(),
      address: _addressController.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(signupResult['error'] ?? 'Eroare la înregistrare')),
      );
    }
  }
  // Future<void> _onSubmit() async {
  //   if (!_validateForm()) {
  //     return;
  //   }
  //
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   // Get current location - REQUIRED
  //   double latitude;
  //   double longitude;
  //
  //   try {
  //     bool hasPermission = await _checkLocationPermission();
  //     if (!hasPermission) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Permisiunea de localizare este obligatorie pentru înregistrare.')),
  //       );
  //       return;
  //     }
  //
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );
  //     latitude = position.latitude;
  //     longitude = position.longitude;
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Eroare la obținerea locației: $e. Vă rugăm să încercați din nou.')),
  //     );
  //     return;
  //   }
  //
  //   print("========================DEBUG=============================");
  //
  //   // Upload profile image
  //   String? profilePhotoUrl;
  //   if (_profileImage != null) {
  //     final profileUploadResult = await ApiService().uploadFile(_profileImage!);
  //     print("Profile Upload Result: $profileUploadResult");
  //     if (!profileUploadResult['success']) {
  //       setState(() {
  //         _isLoading = false;
  //         _profileImageError = 'Eroare la încărcarea imaginii de profil: ${profileUploadResult['error']}';
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Eroare la încărcarea imaginii de profil: ${profileUploadResult['error']}')),
  //       );
  //       return;
  //     }
  //     profilePhotoUrl = profileUploadResult['data']['file_url'];
  //   }
  //
  //   // Upload cover photos (continue even if some fail)
  //   List<String> coverPhotoUrls = [];
  //   List<String> failedUploads = [];
  //   for (var photo in _coverPhotos) {
  //     final uploadResult = await ApiService().uploadFile(photo);
  //     print("Cover Photo Upload Result: $uploadResult");
  //     if (uploadResult['success']) {
  //       coverPhotoUrls.add(uploadResult['data']['file_url']);
  //     } else {
  //       failedUploads.add(uploadResult['error']);
  //     }
  //   }
  //
  //   // If some cover photos failed, inform the user but proceed
  //   if (failedUploads.isNotEmpty) {
  //     setState(() {
  //       _coverPhotosError = 'Unele fotografii nu au fost încărcate: ${failedUploads.join(", ")}';
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Unele fotografii nu au fost încărcate. Continuăm cu imaginile încărcate.')),
  //     );
  //   }
  //
  //   // Proceed with signup even if no cover photos were uploaded successfully
  //   if (profilePhotoUrl == null) {
  //     setState(() {
  //       _isLoading = false;
  //       _profileImageError = 'Imaginea de profil este obligatorie';
  //     });
  //     return;
  //   }
  //
  //   // Perform supplier signup with trimmed text fields
  //   final signupResult = await ApiService().supplierSignup(
  //     fullName: _businessNameController.text.trim(),
  //     email: _emailController.text.trim(),
  //     password: _passwordController.text.trim(),
  //     phone: _phoneController.text.trim(),
  //     photoUrl: profilePhotoUrl,
  //     coverPhotosUrls: coverPhotoUrls,
  //     latitude: latitude,
  //     longitude: longitude,
  //     bio: _aboutBusinessController.text.trim(),
  //     address: _addressController.text.trim(),
  //   );
  //
  //   setState(() {
  //     _isLoading = false;
  //   });
  //
  //   if (signupResult['success'] || signupResult['data']?['user_id'] != null) {
  //     setState(() {
  //       _userId = signupResult['data']['user_id'];
  //       _showOtpScreen = true;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(signupResult['data']['message'] ?? 'Vă rugăm să verificați OTP-ul.')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(signupResult['error'] ?? 'Eroare la înregistrare')),
  //     );
  //   }
  // }



  bool _validateForm() {
    bool isValid = true;

    setState(() {
      // Reset all error messages
      _businessNameError = null;
      _emailError = null;
      _confirmEmailError = null;
      _phoneError = null;
      _confirmPhoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _addressError = null;
      _aboutBusinessError = null;
      _profileImageError = null;
      _coverPhotosError = null;

      // Validate each field (check trimmed values)
      if (_businessNameController.text.trim().isEmpty) {
        _businessNameError = 'Numele afacerii este obligatoriu';
        isValid = false;
      }

      if (_emailController.text.trim().isEmpty) {
        _emailError = 'Emailul este obligatoriu';
        isValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
        _emailError = 'Introduceți un email valid';
        isValid = false;
      }

      if (_confirmEmailController.text.trim().isEmpty) {
        _confirmEmailError = 'Confirmarea emailului este obligatorie';
        isValid = false;
      } else if (_confirmEmailController.text.trim() != _emailController.text.trim()) {
        _confirmEmailError = 'Emailurile nu coincid';
        isValid = false;
      }

      if (_phoneController.text.trim().isEmpty) {
        _phoneError = 'Numărul de telefon este obligatoriu';
        isValid = false;
      } else if (_phoneController.text.trim().length != 10) {
        _phoneError = 'Numărul de telefon trebuie să aibă 10 cifre';
        isValid = false;
      }

      if (_confirmPhoneController.text.trim().isEmpty) {
        _confirmPhoneError = 'Confirmarea numărului de telefon este obligatorie';
        isValid = false;
      } else if (_confirmPhoneController.text.trim() != _phoneController.text.trim()) {
        _confirmPhoneError = 'Numerele de telefon nu coincid';
        isValid = false;
      }

      if (_passwordController.text.trim().isEmpty) {
        _passwordError = 'Parola este obligatorie';
        isValid = false;
      } else if (_passwordController.text.trim().length < 8) {
        _passwordError = 'Parola trebuie să aibă minim 8 caractere';
        isValid = false;
      }

      if (_confirmPasswordController.text.trim().isEmpty) {
        _confirmPasswordError = 'Confirmarea parolei este obligatorie';
        isValid = false;
      } else if (_confirmPasswordController.text.trim() != _passwordController.text.trim()) {
        _confirmPasswordError = 'Parolele nu coincid';
        isValid = false;
      }

      if (_addressController.text.trim().isEmpty) {
        _addressError = 'Adresa este obligatorie';
        isValid = false;
      }

      if (_aboutBusinessController.text.trim().isEmpty) {
        _aboutBusinessError = 'Descrierea afacerii este obligatorie';
        isValid = false;
      }

      if (_profileImage == null) {
        _profileImageError = 'Imaginea de profil este obligatorie';
        isValid = false;
      }

      if (_coverPhotos.isEmpty) {
        _coverPhotosError = 'Cel puțin o fotografie de copertă este obligatorie';
        isValid = false;
      }
    });

    return isValid;
  }

  Future<bool> _checkLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serviciile de localizare sunt dezactivate.')),
      );
      return false;
    }

    // Check location permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permisiunile de localizare au fost refuzate.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permisiunile de localizare sunt permanent refuzate. Vă rugăm să le activați manual din setări.')),
      );
      return false;
    }

    return true;
  }


  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Eroare la verificarea OTP-ului')),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Eroare la retrimiterea OTP-ului')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InternetConnectivityScreen(
      child: ServerDownWrapper(
        apiService: ApiService(),
        child: Scaffold(
          backgroundColor: Color(0xFFF9FAFB),
          body: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: _showOtpScreen
                    ? _buildOtpScreen()
                    : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40),
                        Text(
                          'Înregistrare Furnizor',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 30),

                        // Profile Image
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _showImageSourceDialog(true),
                                child:Container(
                                  width: 100,
                                  height: 100,
                                  child: DottedBorder(
                                    borderType: BorderType.Circle,
                                    color: Colors.grey,
                                    strokeWidth: 2.0,
                                    dashPattern: const [5, 3], // [dash length, gap length]
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF3F4F6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: _profileImage == null
                                          ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Center(child: Image.asset('assets/person.png', width: 30)),
                                        ],
                                      )
                                          : ClipOval(
                                        child: Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_profileImageError != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    _profileImageError!,
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Informații de afaceri section
                        Text(
                          'Informații de afaceri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _businessNameController,
                          label: 'Numele complet al afacerii',
                          hint: 'Ex: Restaurant Bella',
                          iconPath: 'assets/business.png',
                          errorText: _businessNameError,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Adresa de email',
                          hint: 'Ex: contact@restaurantbella.ro',
                          iconPath: 'assets/email.png',
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmEmailController,
                          label: 'Confirmare email',
                          hint: 'Ex: contact@restaurantbella.ro',
                          iconPath: 'assets/email.png',
                          keyboardType: TextInputType.emailAddress,
                          errorText: _confirmEmailError,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Număr de telefon',
                          hint: 'Ex: 0712345678',
                          iconPath: 'assets/phone.png',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          errorText: _phoneError,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPhoneController,
                          label: 'Confirmare număr de telefon',
                          hint: 'Ex: 0712345678',
                          iconPath: 'assets/phone.png',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          errorText: _confirmPhoneError,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Parolă',
                          hint: 'Minim 8 caractere',
                          iconPath: 'assets/loc.png',
                          obscureText: true,
                          errorText: _passwordError,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmare parolă',
                          hint: 'Minim 8 caractere',
                          iconPath: 'assets/loc.png',
                          obscureText: true,
                          errorText: _confirmPasswordError,
                        ),

                        SizedBox(height: 30),

                        // Locație section
                        Text(
                          'Locație',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Adresa afacerii',
                          hint: 'Ex: Strada Principală nr. 10, București',
                          iconPath: 'assets/locationd2.png',
                          errorText: _addressError,
                        ),

                        SizedBox(height: 30),

                        // Despre afacerea ta section
                        Text(
                          'Despre afacerea ta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _aboutBusinessController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Spune-ne despre afacerea ta...',
                                hintText: 'Descrieți serviciile oferite...',
                                hintStyle: TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            if (_aboutBusinessError != null)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  _aboutBusinessError!,
                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 30),

                        // Fotografii de copertă section
                        Text(
                          '1. Fotografii de copertă',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Poți alege până la 5 fotografii pentru copertă.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 16),

                        // Cover photos grid
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: _coverPhotos.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _coverPhotos.length) {
                                  return _coverPhotos.length < 5
                                      ? GestureDetector(
                                    onTap: () => _showImageSourceDialog(false),
                                    child: Container(
                                      child: DottedBorder(
                                        borderType: BorderType.RRect,
                                        radius: const Radius.circular(8.0),
                                        color: Colors.grey,
                                        strokeWidth: 2.0,
                                        dashPattern: const [5, 3], // [dash length, gap length]
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.asset('assets/img.png' , width:  30 ,),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Adaugă fotografie',
                                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                      : SizedBox.shrink();
                                }

                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.file(
                                        _coverPhotos[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _removeCoverImage(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.close, size: 20, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            if (_coverPhotosError != null)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  _coverPhotosError!,
                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 30),

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
                            'Finalizare înregistrare',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Center(
                  child:LoadingAnimationWidget.threeArchedCircle(color: Color(0xFF4B5563), size: 40),

                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpScreen() {
    return Column(
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
        Expanded(child: SizedBox(height: 10)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String iconPath,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Image.asset(
                iconPath,
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
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}