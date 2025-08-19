import 'package:flutter/material.dart';

import '../services/SubmitAAARequestService.dart';

class RequestTowingPopup extends StatefulWidget {
  final String supplierId;

  const RequestTowingPopup({
    Key? key,
    required this.supplierId,
  }) : super(key: key);

  @override
  _RequestTowingPopupState createState() => _RequestTowingPopupState();
}

class _RequestTowingPopupState extends State<RequestTowingPopup> {
  final TextEditingController _situationController = TextEditingController();
  bool _isSubmitting = false;
  final SubmitAAARequestService _aaaRequestService = SubmitAAARequestService();

  @override
  void dispose() {
    _situationController.dispose();
    super.dispose();
  }

  void _showCustomToast(BuildContext context, String message, bool isSuccess) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _CustomToast(
        message: message,
        isSuccess: isSuccess,
        onDismiss: () {
          overlayEntry?.remove();
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }

  Future<void> _submitRequest() async {
    if (_situationController.text.trim().isEmpty) {
      _showCustomToast(context, 'Vă rugăm să descrieți situația', false);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _aaaRequestService.submitRequest(
        supplierId: widget.supplierId,
        reason: _situationController.text.trim(),
      );

      if (response['success']) {
        _showCustomToast(context, response['message'] ?? 'Serviciu de remorcare solicitat cu succes!', true);
        Navigator.of(context).pop();
      } else {
        _showCustomToast(context, response['error'] ?? 'Eroare necunoscută', false);
      }
    } catch (e) {
      _showCustomToast(context, 'Eroare: ${e.toString()}', false);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: _buildPopupContent(context),
      ),
    );
  }

  Widget _buildPopupContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Solicitare Serviciu Remorcare AAA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Descrieți situația',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _situationController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Descrieți ce s-a întâmplat cu vehiculul dumneavoastră...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Anulează',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _situationController.text.trim().isNotEmpty && !_isSubmitting
                    ? _submitRequest
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Solicită Acum',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomToast extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;

  const _CustomToast({
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
  });

  @override
  _CustomToastState createState() => _CustomToastState();
}

class _CustomToastState extends State<_CustomToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2, milliseconds: 700), () {
      _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}