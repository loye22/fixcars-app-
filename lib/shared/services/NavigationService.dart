import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  static Future<void> navigateTo({
    required BuildContext context,
    required double latitude,
    required double longitude,
    String? locationName, // Made optional
  }) async {
    // Try Waze first (works without location name)
    final wazeUri = locationName != null
        ? Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes&q=${Uri.encodeComponent(locationName)}')
        : Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes');

    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(wazeUri);
      return;
    }

    // Fallback to Google Maps (also works without name)
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri);
      return;
    }

    // Ultimate fallback
    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (!await canLaunchUrl(fallbackUri)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Navigation Error'),
          content: const Text('No navigation app available.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}