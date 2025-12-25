import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../../shared/services/api_service.dart';

class PremiumProfileEditSheet extends StatefulWidget {
  const PremiumProfileEditSheet({super.key});

  @override
  State<PremiumProfileEditSheet> createState() => _PremiumProfileEditSheetState();
}

class _PremiumProfileEditSheetState extends State<PremiumProfileEditSheet> {
  final ProfileService _profileService = ProfileService();
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _profilePhotoUrl;
  List<String> _coverPhotos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final res = await _profileService.getProfileData();
    if (res['success']) {
      final d = res['data'];
      setState(() {
        _nameController.text = d['full_name'] ?? '';
        _phoneController.text = d['phone'] ?? '';
        _addressController.text = d['business_address'] ?? '';
        _bioController.text = d['bio'] ?? '';
        _profilePhotoUrl = d['profile_photo'];
        _coverPhotos = List<String>.from(d['cover_photos'] ?? []);
        _isLoading = false;
      });
    }
  }

  // --- Image Upload Logic ---

  Future<void> _pickImage(bool isProfile) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _isUploadingImage = true);

    final uploadRes = await _apiService.uploadFile(File(image.path));

    if (uploadRes['success']) {
      setState(() {
        final String newUrl = uploadRes['data']['file_url']; // Fixed per your logs
        if (isProfile) {
          _profilePhotoUrl = newUrl;
        } else {
          _coverPhotos.add(newUrl);
        }
        _isUploadingImage = false;
      });
      _showElegantToast("Imagine încărcată cu succes", isError: false);
    } else {
      setState(() => _isUploadingImage = false);
      _showElegantToast(uploadRes['error'] ?? "Eroare la încărcare");
    }
  }

  // --- Elegant Feedback System ---

  // void _showElegantToast(String message, {bool isError = true}) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       content: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFF2A2A2A),
  //           borderRadius: BorderRadius.circular(15),
  //           border: Border.all(color: isError ? Colors.redAccent.withOpacity(0.5) : Colors.grey.withOpacity(0.5)),
  //           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10)],
  //         ),
  //         child: Row(
  //           children: [
  //             Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
  //                 color: isError ? Colors.redAccent : Colors.grey),
  //             const SizedBox(width: 12),
  //             Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14))),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _showElegantToast(String message, {bool isError = true}) {
    // Definire Overlay
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, // Chiar sub bara de status
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: -50.0, end: 0.0), // Efect de slide-down
            curve: Curves.bounceIn,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Opacity(
                  opacity: (value + 50) / 50,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.95), // Obsidian cu blur
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isError ? Colors.redAccent.withOpacity(0.5) : Colors.grey.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: isError ? Colors.redAccent : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Inserare în ecran
    Overlay.of(context).insert(overlayEntry);

    // Eliminare automată după 3 secunde
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F), // True Obsidian
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: _isLoading
          ? const SizedBox(height: 400, child: Center(child: CircularProgressIndicator(color: Colors.grey)))
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildProfileImagePicker(),
                    const SizedBox(height: 40),
                    _buildSectionTitle("Fotografii de Copertă"),
                    _buildCoverPhotosList(),
                    const SizedBox(height: 30),
                    _buildPremiumField(_nameController, "Nume Complet", Icons.person_outline),
                    _buildPremiumField(_phoneController, "Număr de Telefon", Icons.phone_android_outlined),
                    _buildPremiumField(_addressController, "Adresa Business", Icons.location_on_outlined),
                    _buildPremiumField(_bioController, "Biografie / Descriere", Icons.auto_awesome_outlined, maxLines: 3),
                    const SizedBox(height: 30),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12, width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF1A1A1A),
              backgroundImage: _profilePhotoUrl != null ? NetworkImage(_profilePhotoUrl!) : null,
              child: _profilePhotoUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white24) : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _pickImage(true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0F0F0F), width: 3),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.black),
              ),
            ),
          ),
          if (_isUploadingImage)
            const Positioned.fill(child: Center(child: CircularProgressIndicator(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Editare Profil", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildCoverPhotosList() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._coverPhotos.map((url) => _buildCoverThumbnail(url)),
          GestureDetector(
            onTap: () => _pickImage(false),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white24, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverThumbnail(String url) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        border: Border.all(color: Colors.white10),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () => setState(() => _coverPhotos.remove(url)),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white38, size: 22),
          filled: true,
          fillColor: Colors.white.withOpacity(0.02),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.grey)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade600]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.black)
            : const Text("SALVEAZĂ MODIFICĂRILE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }

  void _save() async {
    setState(() => _isSaving = true);

    final res = await _profileService.updateProfileData(
      fullName: _nameController.text,
      profilePhoto: _profilePhotoUrl ?? '',
      phone: _phoneController.text,
      businessAddress: _addressController.text,
      bio: _bioController.text,
      coverPhotos: _coverPhotos,
    );

    setState(() => _isSaving = false);

    if (res['success']) {
      _showElegantToast("Profil actualizat cu succes", isError: false);
      Future.delayed(const Duration(milliseconds: 800), () => Navigator.pop(context, true));
    } else {
      // LOGICA DE PARSARE A ERORILOR SPECIFICE
      String errorMessage = "A apărut o eroare";

      if (res['errors'] != null && res['errors'] is Map) {
        // Luăm prima eroare din listă (ex: phone, bio, etc.)
        var firstKey = res['errors'].keys.first;
        var firstErrorList = res['errors'][firstKey];

        if (firstErrorList is List && firstErrorList.isNotEmpty) {
          errorMessage = firstErrorList[0]; // "Phone number must be exactly 10 digits."
        }
      } else if (res['message'] != null) {
        errorMessage = res['message'];
      }

      _showElegantToast(errorMessage, isError: true);
    }
  }


}