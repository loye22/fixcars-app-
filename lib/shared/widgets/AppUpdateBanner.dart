import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/AppVersionService.dart';

class AppUpdateBanner extends StatefulWidget {
  const AppUpdateBanner({super.key});

  @override
  State<AppUpdateBanner> createState() => _AppUpdateBannerState();
}

class _AppUpdateBannerState extends State<AppUpdateBanner> with SingleTickerProviderStateMixin {
  final AppVersionService _versionService = AppVersionService();
  UpdateStatus _status = UpdateStatus.loading;
  String? _latestVersion;
  bool _isForceUpdate = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _checkForUpdates();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final versions = await _versionService.fetchAppVersions();

      if (versions.isEmpty) {
        setState(() => _status = UpdateStatus.hidden);
        return;
      }

      versions.sort((a, b) =>
          DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']))
      );

      final latest = versions.first;
      final needsUpdate = _compareVersions(currentVersion, latest['version']) < 0;

      if (needsUpdate) {
        setState(() {
          _status = UpdateStatus.show;
          _latestVersion = latest['version'];
          _isForceUpdate = latest['force_update'] == true;
        });
        _slideController.forward();
      } else {
        setState(() => _status = UpdateStatus.hidden);
      }
    } catch (e) {
      setState(() => _status = UpdateStatus.hidden);
    }
  }

  int _compareVersions(String v1, String v2) {
    List<int> parts1 = v1.split('.').map(int.parse).toList();
    List<int> parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < parts1.length && i < parts2.length; i++) {
      if (parts1[i] != parts2[i]) return parts1[i].compareTo(parts2[i]);
    }
    return parts1.length.compareTo(parts2.length);
  }


  void _handleUpdate() async {
    // App store links
    const String androidStoreLink = 'https://play.google.com/store/apps/details?id=com.fixcars.app&hl=en_US';
    const String iosStoreLink = 'https://apps.apple.com/ro/app/fixcars/id6754461330?l=ro';

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        // Open Google Play Store for Android
        final Uri androidUri = Uri.parse(androidStoreLink);
        if (await canLaunchUrl(androidUri)) {
          await launchUrl(androidUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $androidStoreLink';
        }
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        // Open App Store for iOS
        final Uri iosUri = Uri.parse(iosStoreLink);
        if (await canLaunchUrl(iosUri)) {
          await launchUrl(iosUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $iosStoreLink';
        }
      }
    } catch (e) {
      // Show error message if store can't be opened
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nu s-a putut deschide magazinul de aplicații'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Color _getBannerColor() {
    if (_isForceUpdate) {
      return const Color(0xFFDC2626); // Red
    }
    return const Color(0xFFF59E0B); // Amber
  }

  IconData _getIcon() {
    if (_isForceUpdate) {
      return Icons.warning_rounded;
    }
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_status == UpdateStatus.hidden || _status == UpdateStatus.loading) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getBannerColor().withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: _getBannerColor(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isForceUpdate
                              ? 'Actualizare obligatorie'  // Update Required
                              : 'Actualizare disponibilă', // Update Available
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isForceUpdate
                              ? 'Versiunea $_latestVersion este necesară pentru a continua'
                              : 'Versiunea $_latestVersion este acum disponibilă',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!_isForceUpdate)
                    OutlinedButton(
                      onPressed: _handleUpdate,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Actualizează',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (_isForceUpdate)
                    ElevatedButton(
                      onPressed: _handleUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Actualizează acum',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
  }
}

enum UpdateStatus { loading, show, hidden }