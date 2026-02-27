
import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/FeedbackService.dart';

class FeedbackButton extends StatefulWidget {
  const FeedbackButton({Key? key}) : super(key: key);

  @override
  State<FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _feedbackController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<File> _selectedImages = [];
  File? _voiceFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(StateSetter setSheetState) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && _selectedImages.length < 3) {
        setSheetState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showSnackBar('Eroare la selectarea imaginii: $e');
    }
  }

  Future<void> _pickVoice(StateSetter setSheetState) async {
    try {
      final XFile? voice = await _imagePicker.pickMedia();
      if (voice != null) {
        setSheetState(() {
          _voiceFile = File(voice.path);
        });
      }
    } catch (e) {
      _showSnackBar('Eroare la selectarea fișierului audio: $e');
    }
  }

  void _removeImage(int index, StateSetter setSheetState) {
    setSheetState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVoice(StateSetter setSheetState) {
    setSheetState(() {
      _voiceFile = null;
    });
  }

  Future<String?> _uploadFile(File file) async {
    ApiService _apiService = ApiService();
    final result = await _apiService.uploadFile2(file);
    if (result['success']) {
      final data = result['data'];
      if (data is Map<String, dynamic>) {
        return data['url'] ?? data['file_url'] ?? data['file'];
      } else if (data is String) {
        return data;
      }
    }
    return null;
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackBar('Te rugăm să scrii un mesaj');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? voiceUrl;
      String? imageUrl1, imageUrl2, imageUrl3;

      if (_voiceFile != null) {
        voiceUrl = await _uploadFile(_voiceFile!);
      }

      if (_selectedImages.isNotEmpty) {
        final urls = await Future.wait(_selectedImages.map(_uploadFile));
        if (urls.length > 0) imageUrl1 = urls[0];
        if (urls.length > 1) imageUrl2 = urls[1];
        if (urls.length > 2) imageUrl3 = urls[2];
      }

      final result = await _feedbackService.submitFeedback(
        text: _feedbackController.text.trim(),
        voiceUrl: voiceUrl,
        imageUrl1: imageUrl1,
        imageUrl2: imageUrl2,
        imageUrl3: imageUrl3,
      );

      if (result['success']) {
        Navigator.pop(context);
        _showSnackBar('Mulțumim pentru feedback! 🙏', isError: false);
        _feedbackController.clear();
        _selectedImages.clear();
        _voiceFile = null;
      } else {
        _showSnackBar('Eroare: ${result['error']}');
      }
    } catch (e) {
      _showSnackBar('A apărut o eroare.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFeedbackBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2C2C), // Requested Theme Color
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Spune-ne părerea ta',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text Input
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: TextField(
                                  controller: _feedbackController,
                                  maxLines: 5,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Scrie aici sugestiile tale...',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Image Preview List
                              if (_selectedImages.isNotEmpty) ...[
                                const Text('Imagini selectate', style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImages.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                _selectedImages[index],
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: -8,
                                              right: -8,
                                              child: GestureDetector(
                                                onTap: () => _removeImage(index, setSheetState),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Audio Preview
                              if (_voiceFile != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.mic, color: Colors.blueAccent),
                                      const SizedBox(width: 10),
                                      const Expanded(child: Text("Audio atașat", style: TextStyle(color: Colors.white))),
                                      IconButton(
                                        onPressed: () => _removeVoice(setSheetState),
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Action Buttons
                              Row(
                                children: [
                                  if (_selectedImages.length < 3)
                                    Expanded(
                                      child: _buildMediaButton(
                                        icon: Icons.add_a_photo,
                                        label: 'Adaugă poze',
                                        onTap: () => _pickImage(setSheetState),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  if (_voiceFile == null)
                                    Expanded(
                                      child: _buildMediaButton(
                                        icon: Icons.mic_none,
                                        label: 'Adaugă audio',
                                        onTap: () => _pickVoice(setSheetState),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitFeedback,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isSubmitting
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('Trimite Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildMediaButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showFeedbackBottomSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFC8CADE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.bug_report_outlined, color: Color(0xFF2A3B4F)),
            SizedBox(width: 10),
            Text('Feedback', style:  TextStyle(
              color: Color(0xFF2A3B4F),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),),
          ],
        ),
      ),
    );
  }
}