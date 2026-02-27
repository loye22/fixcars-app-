import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/SocialMediaService.dart';

class SocialMediaSection extends StatefulWidget {
  final Color primaryColor;
  final Function(String, {Color background}) showToast;

  const SocialMediaSection({
    super.key,
    required this.primaryColor,
    required this.showToast,
  });

  @override
  State<SocialMediaSection> createState() => _SocialMediaSectionState();
}

class _SocialMediaSectionState extends State<SocialMediaSection> {
  Map<String, dynamic> _socialMedia = {};
  bool _loading = true;
  bool _saving = false;

  final SocialMediaService _service = SocialMediaService();

  @override
  void initState() {
    super.initState();
    _fetchSocialMedia();
  }

  /// --------------------------
  /// FETCH SOCIAL MEDIA
  /// --------------------------
  Future<void> _fetchSocialMedia() async {
    try {
      final result = await _service.fetchSocialMedia();
      setState(() {
        _socialMedia = result['data'] ?? {};
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// --------------------------
  /// VALIDATE URL
  /// --------------------------
  String? _validateUrl(String url) {
    if (url.trim().isEmpty) return null;

    String formatted = url.trim();

    if (!formatted.startsWith('http://') &&
        !formatted.startsWith('https://')) {
      formatted = "https://$formatted";
    }

    final uri = Uri.tryParse(formatted);
    if (uri == null || !uri.hasAuthority) {
      widget.showToast(
        "Link invalid",
        background: Colors.redAccent,
      );
      return null;
    }

    return formatted;
  }

  /// --------------------------
  /// UPDATE SOCIAL MEDIA
  /// --------------------------

  Future<void> _updateSocialLink(String key, String newValue) async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      // Build full payload: include all known keys, set current values or null
      final payload = {
        "facebook_url": key == "facebook_url" ? newValue : _socialMedia["facebook_url"],
        "tiktok_url": key == "tiktok_url" ? newValue : _socialMedia["tiktok_url"],
        "instagram_url": key == "instagram_url" ? newValue : _socialMedia["instagram_url"],
        "website_url": key == "website_url" ? newValue : _socialMedia["website_url"],
        "youtube_url": key == "youtube_url" ? newValue : _socialMedia["youtube_url"],
      };

      // Make sure nulls are sent explicitly if values are missing
      payload.forEach((k, v) {
        if (v == null) payload[k] = null;
      });

      final result = await _service.updateSocialMedia(payload);

      if (result['success'] == true) {
        setState(() {
          _socialMedia = result['data'] ?? {};
        });

        widget.showToast(
          "Actualizat cu succes",
          background: widget.primaryColor,
        );
      } else {
        widget.showToast(
          result['message'] ?? "Eroare la salvare",
          background: Colors.redAccent,
        );
      }
    } catch (e) {
      widget.showToast(
        "Eroare conexiune",
        background: Colors.redAccent,
      );
    } finally {
      setState(() => _saving = false);
    }
  }
  /// --------------------------
  /// DOCUMENT VIEWER
  /// --------------------------
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
                              () => VerticalDragGestureRecognizer()..onUpdate = (_) {},
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

  /// --------------------------
  /// EDIT / ADD LINK SHEET
  /// --------------------------
  void _showEditSheet(String platform, String key, String initial, String asset) {
    final controller = TextEditingController(text: initial);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Image.asset(asset, width: 26),
                  const SizedBox(width: 12),
                  Text(
                    platform,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: controller,
                placeholder: "Introduceți linkul...",
                style: const TextStyle(color: Colors.white),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(14),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  borderRadius: BorderRadius.circular(14),
                  color: widget.primaryColor,
                  onPressed: _saving
                      ? null
                      : () {
                    final valid = _validateUrl(controller.text);
                    if (valid != null) {
                      _updateSocialLink(key, valid);
                      Navigator.pop(context);
                    }
                  },
                  child: _saving
                      ? const CupertinoActivityIndicator(color: Colors.black)
                      : const Text("Salvează",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// --------------------------
  /// OPTIONS SHEET (CONTINUOUS CLICK)
  /// --------------------------
  void _showOptionsSheet(String platform, String key, String? url, String asset) {
    final hasLink = url != null && url.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Row(
              children: [
                Image.asset(asset, width: 26),
                const SizedBox(width: 12),
                Text(platform,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 20),
            if (hasLink)
              ListTile(
                title: const Text("Deschide link", style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.open_in_new, color: widget.primaryColor),
                onTap: () {
                  Navigator.pop(context);
                  final valid = _validateUrl(url!);
                  if (valid != null) _showDocumentSheet(context, valid);
                },
              ),
            ListTile(
              title: Text(hasLink ? "Editează link" : "Adaugă link",
                  style: const TextStyle(color: Colors.white)),
              trailing: Icon(Icons.edit, color: widget.primaryColor),
              onTap: () {
                Navigator.pop(context);
                _showEditSheet(platform, key, url ?? '', asset);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// --------------------------
  /// BUILD ICON
  /// --------------------------
  Widget _buildIcon(String nume, String key, String? url, String asset) {
    final hasLink = url != null && url.isNotEmpty;
    return GestureDetector(
      onTap: () => _showOptionsSheet(nume, key, url, asset),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: hasLink ? 1 : 0.35,
        child: Column(
          children: [
            Image.asset(asset, width: 36, height: 36),
            const SizedBox(height: 6),
            Text(
              nume,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------
  /// BUILD
  /// --------------------------
  @override
  Widget build(BuildContext context) {
    final platforms = [
      {'name': 'Facebook', 'key': 'facebook_url', 'asset': 'assets/facebook.png'},
      {'name': 'TikTok', 'key': 'tiktok_url', 'asset': 'assets/tiktok.png'},
      {'name': 'Instagram', 'key': 'instagram_url', 'asset': 'assets/instagram.png'},
      {'name': 'YouTube', 'key': 'youtube_url', 'asset': 'assets/youtube.png'},
      {'name': 'Website', 'key': 'website_url', 'asset': 'assets/www.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "REȚELE SOCIALE",
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.4,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E), // same dark theme
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const Text(
                          "Acestea sunt rețelele sociale pe care utilizatorii le vor vedea pe profilul tău. "
                              "Asigură-te că furnizezi linkuri valide.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        CupertinoButton(
                          color: widget.primaryColor,
                          borderRadius: BorderRadius.circular(14),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Am înțeles",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
              child: const Icon(
                CupertinoIcons.info_circle,
                size: 18,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
        // Text(
        //   "REȚELE SOCIALE",
        //   style: TextStyle(
        //       fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.bold, color: widget.primaryColor),
        // ),
        const SizedBox(height: 18),
        if (_loading)
          const Center(child: CupertinoActivityIndicator())
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: platforms.map((p) {
              return _buildIcon(
                  p['name']!, p['key']!, _socialMedia[p['key']], p['asset']!);
            }).toList(),
          ),
      ],
    );
  }
}


// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/gestures.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// import '../services/SocialMediaService.dart';
//
// class SocialMediaSection extends StatefulWidget {
//   final Color primaryColor;
//   final Function(String, {Color background}) showToast;
//
//   const SocialMediaSection({
//     super.key,
//     required this.primaryColor,
//     required this.showToast,
//   });
//
//   @override
//   State<SocialMediaSection> createState() => _SocialMediaSectionState();
// }
//
// class _SocialMediaSectionState extends State<SocialMediaSection> {
//
//   Map<String, dynamic> _socialMedia = {};
//   bool _loading = true;
//
//   final SocialMediaService _service = SocialMediaService();
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchSocialMedia();
//   }
//
//   /// ----------------------------------------------------------
//   /// FETCH
//   /// ----------------------------------------------------------
//   Future<void> _fetchSocialMedia() async {
//     try {
//       final result = await _service.fetchSocialMedia();
//
//       if (result['success'] == true) {
//         setState(() {
//           _socialMedia = result['data'] ?? {};
//           _loading = false;
//         });
//       } else {
//         _loading = false;
//       }
//     } catch (_) {
//       _loading = false;
//     }
//   }
//
//   /// ----------------------------------------------------------
//   /// URL VALIDATION (iOS STYLE SAFE)
//   /// ----------------------------------------------------------
//   String? _validateUrl(String url) {
//     if (url.trim().isEmpty) return null;
//
//     String formatted = url.trim();
//
//     if (!formatted.startsWith('http://') &&
//         !formatted.startsWith('https://')) {
//       formatted = "https://$formatted";
//     }
//
//     final uri = Uri.tryParse(formatted);
//
//     if (uri == null || !uri.hasAuthority) {
//       widget.showToast(
//         "Link invalid",
//         background: Colors.redAccent,
//       );
//       return null;
//     }
//
//     return formatted;
//   }
//
//   /// ----------------------------------------------------------
//   /// UPDATE
//   /// ----------------------------------------------------------
//   Future<void> _updateSocialLink(
//       String key,
//       String value,
//       ) async {
//
//     final result =
//     await _service.updateSocialMedia({key: value});
//
//     if (result['success'] == true) {
//       setState(() {
//         _socialMedia = result['data'] ?? {};
//       });
//
//       widget.showToast(
//         "Actualizat cu succes",
//         background: widget.primaryColor,
//       );
//     }
//   }
//
//   /// ----------------------------------------------------------
//   /// IOS DOCUMENT VIEWER
//   /// ----------------------------------------------------------
//   void _showDocumentSheet(BuildContext context, String url) {
//
//     String finalUrl = url;
//
//     final ValueNotifier<bool> isLoading =
//     ValueNotifier(true);
//
//     if (url.toLowerCase().endsWith('.pdf') ||
//         url.toLowerCase().endsWith('.doc') ||
//         url.toLowerCase().endsWith('.docx')) {
//       finalUrl =
//       "https://docs.google.com/viewer?embedded=true&url=${Uri.encodeComponent(url)}";
//     }
//
//     final controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0xFF1E1E1E))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageFinished: (_) =>
//           isLoading.value = false,
//           onWebResourceError: (_) =>
//           isLoading.value = false,
//         ),
//       )
//       ..loadRequest(Uri.parse(finalUrl));
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//
//         return Container(
//           height:
//           MediaQuery.of(context).size.height * 0.92,
//
//           decoration: const BoxDecoration(
//             color: Color(0xFF1E1E1E),
//             borderRadius: BorderRadius.vertical(
//               top: Radius.circular(28),
//             ),
//           ),
//
//           child: Column(
//             children: [
//
//               /// Drag Handle
//               Container(
//                 width: 42,
//                 height: 5,
//                 margin:
//                 const EdgeInsets.only(top: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white24,
//                   borderRadius:
//                   BorderRadius.circular(10),
//                 ),
//               ),
//
//               const SizedBox(height: 12),
//
//               Expanded(
//                 child: ClipRRect(
//                   borderRadius:
//                   const BorderRadius.vertical(
//                       top:
//                       Radius.circular(28)),
//                   child: Stack(
//                     alignment:
//                     Alignment.center,
//                     children: [
//
//                       WebViewWidget(
//                         controller:
//                         controller,
//                         gestureRecognizers: {
//                           Factory<
//                               VerticalDragGestureRecognizer>(
//                                 () =>
//                             VerticalDragGestureRecognizer()
//                               ..onUpdate =
//                                   (_) {},
//                           ),
//                         },
//                       ),
//
//                       ValueListenableBuilder<
//                           bool>(
//                         valueListenable:
//                         isLoading,
//                         builder:
//                             (_, loading, __) {
//                           return loading
//                               ? const CupertinoActivityIndicator(
//                             radius: 16,
//                           )
//                               : const SizedBox();
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//
//
//   void _showEditSheet(
//       String platform,
//       String key,
//       String initial,
//       String asset,
//       ) {
//
//     final controller =
//     TextEditingController(text: initial);
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom:
//             MediaQuery.of(context)
//                 .viewInsets
//                 .bottom,
//           ),
//
//           child: Container(
//             padding:
//             const EdgeInsets.all(24),
//
//             decoration:
//             const BoxDecoration(
//               color: Color(0xFF1E1E1E),
//               borderRadius:
//               BorderRadius.vertical(
//                 top: Radius.circular(28),
//               ),
//             ),
//
//             child: Column(
//               mainAxisSize:
//               MainAxisSize.min,
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//               children: [
//
//                 Center(
//                   child: Container(
//                     width: 40,
//                     height: 4,
//                     margin:
//                     const EdgeInsets.only(
//                         bottom: 20),
//                     decoration:
//                     BoxDecoration(
//                       color:
//                       Colors.white24,
//                       borderRadius:
//                       BorderRadius
//                           .circular(
//                           10),
//                     ),
//                   ),
//                 ),
//
//                 Row(
//                   children: [
//                     Image.asset(
//                       asset,
//                       width: 26,
//                     ),
//                     const SizedBox(
//                         width: 12),
//                     Text(
//                       platform,
//                       style:
//                       const TextStyle(
//                         color:
//                         Colors.white,
//                         fontSize: 18,
//                         fontWeight:
//                         FontWeight
//                             .w600,
//                       ),
//                     )
//                   ],
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 CupertinoTextField(
//                   controller:
//                   controller,
//                   placeholder:
//                   "Introduceți linkul...",
//                   style:
//                   const TextStyle(
//                       color:
//                       Colors
//                           .white),
//                   padding:
//                   const EdgeInsets
//                       .all(16),
//                   decoration:
//                   BoxDecoration(
//                     color:
//                     const Color(
//                         0xFF2A2A2A),
//                     borderRadius:
//                     BorderRadius
//                         .circular(
//                         14),
//                   ),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 SizedBox(
//                   width:
//                   double.infinity,
//                   child:
//                   CupertinoButton(
//                     borderRadius:
//                     BorderRadius
//                         .circular(
//                         14),
//                     color: widget
//                         .primaryColor,
//                     child:
//                     const Text(
//                       "Salvează",
//                       style:
//                       TextStyle(
//                         color: Colors
//                             .black,
//                         fontWeight:
//                         FontWeight
//                             .w600,
//                       ),
//                     ),
//                     onPressed: () {
//
//                       final valid =
//                       _validateUrl(
//                           controller
//                               .text);
//
//                       if (valid !=
//                           null) {
//                         _updateSocialLink(
//                             key,
//                             valid);
//                         Navigator.pop(
//                             context);
//                       }
//                     },
//                   ),
//                 ),
//
//                 const SizedBox(
//                     height: 12),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   /// ----------------------------------------------------------
//   /// IOS ICON
//   /// ----------------------------------------------------------
//   Widget _buildIcon(
//       String nume,
//       String key,
//       String? url,
//       String asset,
//       ) {
//     final hasLink =
//         url != null && url.isNotEmpty;
//
//     return GestureDetector(
//       onTap: () {
//         _showOptionsSheet(
//           nume,
//           key,
//           url,
//           asset,
//         );
//       },
//
//       child: AnimatedOpacity(
//         duration:
//         const Duration(milliseconds: 200),
//         opacity: hasLink ? 1 : 0.35,
//
//         child: Column(
//           children: [
//
//             Image.asset(
//               asset,
//               width: 36,
//               height: 36,
//             ),
//
//             const SizedBox(height: 6),
//
//             Text(
//               nume,
//               style: const TextStyle(
//                 color: Colors.white70,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showOptionsSheet(
//       String platform,
//       String key,
//       String? url,
//       String asset,
//       ) {
//
//     final hasLink =
//         url != null && url.isNotEmpty;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//
//         return Container(
//           padding:
//           const EdgeInsets.all(24),
//
//           decoration:
//           const BoxDecoration(
//             color: Color(0xFF1E1E1E),
//             borderRadius:
//             BorderRadius.vertical(
//               top: Radius.circular(28),
//             ),
//           ),
//
//           child: Column(
//             mainAxisSize:
//             MainAxisSize.min,
//             children: [
//
//               Container(
//                 width: 40,
//                 height: 4,
//                 margin:
//                 const EdgeInsets.only(
//                     bottom: 20),
//                 decoration: BoxDecoration(
//                   color: Colors.white24,
//                   borderRadius:
//                   BorderRadius.circular(
//                       10),
//                 ),
//               ),
//
//               Row(
//                 children: [
//                   Image.asset(
//                     asset,
//                     width: 26,
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     platform,
//                     style:
//                     const TextStyle(
//                       color:
//                       Colors.white,
//                       fontSize: 18,
//                       fontWeight:
//                       FontWeight.w600,
//                     ),
//                   )
//                 ],
//               ),
//
//               const SizedBox(height: 20),
//
//               /// OPEN
//               if (hasLink)
//                 ListTile(
//                   title: const Text(
//                     "Deschide link",
//                     style: TextStyle(
//                         color:
//                         Colors.white),
//                   ),
//                   trailing: Icon(
//                     Icons.open_in_new,
//                     color: widget
//                         .primaryColor,
//                   ),
//                   onTap: () {
//
//                     Navigator.pop(
//                         context);
//
//                     final valid =
//                     _validateUrl(
//                         url!);
//
//                     if (valid != null) {
//                       _showDocumentSheet(
//                           context,
//                           valid);
//                     }
//                   },
//                 ),
//
//               /// EDIT / ADD
//               ListTile(
//                 title: Text(
//                   hasLink
//                       ? "Editează link"
//                       : "Adaugă link",
//                   style:
//                   const TextStyle(
//                       color:
//                       Colors.white),
//                 ),
//                 trailing: Icon(
//                   Icons.edit,
//                   color:
//                   widget.primaryColor,
//                 ),
//                 onTap: () {
//                   Navigator.pop(
//                       context);
//
//                   _showEditSheet(
//                     platform,
//                     key,
//                     url ?? '',
//                     asset,
//                   );
//                 },
//               ),
//
//               const SizedBox(height: 10),
//             ],
//           ),
//         );
//       },
//     );
//   }
//   /// ----------------------------------------------------------
//   /// BUILD
//   /// ----------------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//
//     final platforms = [
//       {'name': 'Facebook', 'key': 'facebook_url', 'asset': 'assets/facebook.png'},
//       {'name': 'TikTok', 'key': 'tiktok_url', 'asset': 'assets/tiktok.png'},
//       {'name': 'Instagram', 'key': 'instagram_url', 'asset': 'assets/instagram.png'},
//       {'name': 'YouTube', 'key': 'youtube_url', 'asset': 'assets/youtube.png'},
//       {'name': 'Website', 'key': 'website_url', 'asset': 'assets/www.png'},
//     ];
//
//     return Column(
//       crossAxisAlignment:
//       CrossAxisAlignment.start,
//       children: [
//
//         Text(
//           "REȚELE SOCIALE",
//           style: TextStyle(
//             fontSize: 12,
//             letterSpacing: 1.4,
//             fontWeight:
//             FontWeight.bold,
//             color:
//             widget.primaryColor,
//           ),
//         ),
//
//         const SizedBox(height: 18),
//
//         if (_loading)
//           const Center(
//               child:
//               CupertinoActivityIndicator())
//         else
//           Row(
//             mainAxisAlignment:
//             MainAxisAlignment
//                 .spaceEvenly,
//             children:
//             platforms.map((p) {
//               return _buildIcon(
//                 p['name']!,
//                 p['key']!,
//                 _socialMedia[p['key']],
//                 p['asset']!,
//               );
//             }).toList(),
//           ),
//       ],
//     );
//   }
// }