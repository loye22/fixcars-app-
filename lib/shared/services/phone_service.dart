import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class CallService {
  static final ValueNotifier<String?> callError = ValueNotifier(null);

  static Future<void> makeCall({
    required BuildContext context,
    required String phoneNumber,
    bool isTestMode = false,
  }) async {
    callError.value = null; // Reset error

    if (isTestMode) {
      _showTestDialog(context, phoneNumber);
      return;
    }

    try {
      final cleanedNumber = _cleanPhoneNumber(phoneNumber);
      if (cleanedNumber.isEmpty) {
        throw 'Număr de telefon invalid';
      }

      final phoneUri = Uri(scheme: 'tel', path: cleanedNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Nu se poate deschide aplicația de apeluri';
      }
    } on PlatformException catch (e) {
      callError.value = 'Eroare la apel: ${e.message ?? "Necunoscută"}';
    } catch (e) {
      callError.value = 'Eroare: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  static String _cleanPhoneNumber(String number) {
    return number.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static void _showTestDialog(BuildContext context, String number) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("TEST APEL"),
        content: Text("Număr: ${_cleanPhoneNumber(number)}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}