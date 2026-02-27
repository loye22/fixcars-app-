import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SupplierSocialMediaSection extends StatelessWidget {
  final Map<String, dynamic> socialMedia;
  final Color primaryColor;

  const SupplierSocialMediaSection({
    super.key,
    required this.socialMedia,
    required this.primaryColor,
  });

  String? _normalizeUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  void _showDocumentSheet(BuildContext context, String url) {
    String finalUrl = url;
    final ValueNotifier<bool> isLoading = ValueNotifier(true);

    if (url.toLowerCase().endsWith('.pdf') ||
        url.toLowerCase().endsWith('.doc') ||
        url.toLowerCase().endsWith('.docx')) {
      finalUrl =
          "https://docs.google.com/viewer?embedded=true&url=${Uri.encodeComponent(url)}";
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E1E1E))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => isLoading.value = false,
          onWebResourceError: (_) => isLoading.value = false,
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    WebViewWidget(
                      controller: controller,
                      gestureRecognizers: {
                        Factory<VerticalDragGestureRecognizer>(
                          () => VerticalDragGestureRecognizer()
                            ..onUpdate = (_) {},
                        ),
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: isLoading,
                      builder: (_, loading, __) {
                        return loading
                            ? const CupertinoActivityIndicator(radius: 16)
                            : const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(
      BuildContext context, String label, String url, String asset) {
    return GestureDetector(
      onTap: () {
        final normalized = _normalizeUrl(url);
        if (normalized == null) return;
        _showDocumentSheet(context, normalized);
      },
      child: Column(
        children: [
          Image.asset(asset, width: 36, height: 36),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platforms = [
      {'name': 'Facebook', 'key': 'facebook_url', 'asset': 'assets/facebook.png'},
      {'name': 'TikTok', 'key': 'tiktok_url', 'asset': 'assets/tiktok.png'},
      {'name': 'Instagram', 'key': 'instagram_url', 'asset': 'assets/instagram.png'},
      {'name': 'YouTube', 'key': 'youtube_url', 'asset': 'assets/youtube.png'},
      {'name': 'Website', 'key': 'website_url', 'asset': 'assets/www.png'},
    ];

    final availablePlatforms = platforms.where((p) {
      final key = p['key'] as String;
      final value = socialMedia[key];
      return value != null && value.toString().trim().isNotEmpty;
    }).toList();

    if (availablePlatforms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "REȚELE SOCIALE",
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: availablePlatforms.map((p) {
            final key = p['key'] as String;
            final value = socialMedia[key]?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(right: 20),
              child: _buildIcon(
                context,
                p['name'] as String,
                value,
                p['asset'] as String,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

