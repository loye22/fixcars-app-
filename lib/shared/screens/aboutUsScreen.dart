import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../supplier/services/ReferralService.dart';
import '../services/DeleteAccountService.dart';
import '../services/api_service.dart';
import '../widgets/ShareAppButton.dart';
import '../widgets/SocialMediaSection.dart';
import 'start_screen.dart';

class AboutUsScreen extends StatefulWidget {
  @override
  _AboutUsScreenState createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  // --- LOGIC PRESERVED FROM ORIGINAL ---
  final TextEditingController _referralController = TextEditingController();
  bool _showReferralField = true;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();
  bool _isSubmitting = false;

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  String _deviceInfo = 'Loading...';
  bool _isLoadingInfo = true;

  final Color primaryGray = const Color(0xFFC8CADE); // YOUR REQUESTED COLOR

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _initDeviceInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() { _packageInfo = info; });
    } catch (e) {
      print('Failed to get package info: $e');
    }
  }

  Future<void> _initDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceInfoText = '';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceInfoText = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceInfoText = 'iOS ${iosInfo.systemVersion}';
      } else {
        deviceInfoText = Platform.operatingSystem;
      }
      setState(() {
        _deviceInfo = deviceInfoText;
        _isLoadingInfo = false;
      });
    } catch (e) {
      setState(() { _deviceInfo = 'Error loading device info'; _isLoadingInfo = false; });
    }
  }

  void _showPDF(String pdfPath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(pdfPath: pdfPath, title: title),
      ),
    );
  }

  Future<void> _logout() async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: const Text('Deconectare', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Ești sigur că vrei să te deconectezi?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anulează', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Deconectează', style: TextStyle(color: primaryGray, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await ApiService().clearAllData();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => start_screen()),
              (Route<dynamic> route) => false,
        );
      } catch (e) {
        _showToast('Eroare: $e', background: Colors.redAccent);
      }
    }
  }

  Future<void> _submitReferral() async {
    final email = _referralController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showToast('Email invalid.', background: Colors.orangeAccent);
      return;
    }
    setState(() { _isSubmitting = true; _showReferralField = false; });
    try {
      final result = await ReferralService().referByEmail(email);
      if (result['success'] == true) {
        _showToast(result['message'] ?? 'Succes!', background: primaryGray);
        _referralController.clear();
      } else {
        _showToast(result['error'] ?? 'Eroare', background: Colors.redAccent);
        setState(() => _showReferralField = true);
      }
    } catch (e) {
      _showToast('Eroare rețea', background: Colors.redAccent);
      setState(() => _showReferralField = true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showToast(String message, {Color background = Colors.grey}) {
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  // --- UI WITH NEW GRAY THEME ---
  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          title: Text(
            'DESPRE NOI',
            style: TextStyle(
              color: primaryGray,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                       // shape: BoxShape.circle,
                        color: const Color(0xFF2C2C2C),
                        border: Border.all(color: primaryGray.withOpacity(0.2)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Image.asset('assets/logos/introo.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 20),
                  //  const Text('FixCar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text(
                      'Servicii auto eficiente pentru o călătorie mai lină',
                      style: TextStyle(fontSize: 13, color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Text('DOCUMENTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGray, letterSpacing: 1.5)),
              const SizedBox(height: 16),

              _buildActionCard(
                icon: Icons.description_outlined,
                title: 'Termeni și Condiții',
                onTap: () => _showPDF('assets/docs/terms_and_conditions_ro.pdf', 'Termeni și Condiții'),
              ),
              _buildActionCard(
                icon: Icons.privacy_tip_outlined,
                title: 'Confidențialitate',
                onTap: () => _showPDF('assets/docs/privacy_policy_ro.pdf', 'Politica de Confidențialitate'),
              ),
              _buildActionCard(
                icon: Icons.people_outline,
                title: 'Ghidul Comunității',
                onTap: () => _showPDF('assets/docs/fixcars_community_guidelines_ro.pdf', 'Ghidul Comunității'),
              ),

              Center(
                child: ShareAppButton(),
              ),



              const SizedBox(height: 32),
              SocialMediaSection(
                primaryColor: primaryGray,
                showToast: _showToast,
              ),

              const SizedBox(height: 32),
              Text('CONT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGray, letterSpacing: 1.5)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryGray.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('LOGOUT', style: TextStyle(color: primaryGray, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: _showDeleteDialog,
                      child: const Text('ȘTERGE CONTUL', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ),

              if (_showReferralField) ...[
                const SizedBox(height: 40),
                Row(
                  children: [
                    Text('RECOMANDARE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGray, letterSpacing: 1.5)),
                    InfoIcon(accentColor: primaryGray),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _referralController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(hintText: 'Email angajat', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
                        ),
                      ),
                      _isSubmitting
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryGray))
                          : TextButton(onPressed: _submitReferral, child: Text('TRIMITE', style: TextStyle(color: primaryGray, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Versiune', '${_packageInfo.version}+${_packageInfo.buildNumber}'),
                    _buildInfoRow('Platformă', _isLoadingInfo ? '...' : _deviceInfo),
                    _buildInfoRow('Legal', 'Charlotte IT Services SRL'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryGray, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
            const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white24, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Șterge contul', style: TextStyle(color: Colors.white)),
        content: const Text('Această acțiune va programa ștergerea contului tău în 2 săptămâni.', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulează', style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DeleteAccountService().deleteAccount();
                await ApiService().clearAllData();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => start_screen()), (r) => false);
              } catch (e) { _showToast('Eroare: $e', background: Colors.redAccent); }
            },
            child: const Text('Confirmă', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String title;
  const PDFViewerScreen({Key? key, required this.pdfPath, required this.title}) : super(key: key);
  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      final ByteData data = await rootBundle.load(widget.pdfPath);
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/temp.pdf';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      setState(() { localPath = tempPath; isLoading = false; });
    } catch (e) { setState(() { isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(title: Text(widget.title), backgroundColor: const Color(0xFF2C2C2C), foregroundColor: Colors.white),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : PDFView(filePath: localPath!),
    );
  }
}

class InfoIcon extends StatelessWidget {
  final Color accentColor;
  const InfoIcon({super.key, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, size: 14, color: accentColor),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Informație Referral', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Doar pentru angajații FixCar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: accentColor))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'package:flutter/services.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import '../../supplier/services/ReferralService.dart';
// import '../services/DeleteAccountService.dart';
// import '../services/api_service.dart';
// import 'start_screen.dart';
//
// class AboutUsScreen extends StatefulWidget {
//   @override
//   _AboutUsScreenState createState() => _AboutUsScreenState();
// }
//
// class _AboutUsScreenState extends State<AboutUsScreen> {
//   // --- LOGIC PRESERVED ---
//   final TextEditingController _referralController = TextEditingController();
//   bool _showReferralField = true;
//   final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
//   GlobalKey<ScaffoldMessengerState>();
//   bool _isSubmitting = false;
//
//   PackageInfo _packageInfo = PackageInfo(
//     appName: 'Unknown',
//     packageName: 'Unknown',
//     version: 'Unknown',
//     buildNumber: 'Unknown',
//     buildSignature: 'Unknown',
//     installerStore: 'Unknown',
//   );
//
//   String _deviceInfo = 'Loading...';
//   bool _isLoadingInfo = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _initPackageInfo();
//     _initDeviceInfo();
//   }
//
//   Future<void> _initPackageInfo() async {
//     try {
//       final info = await PackageInfo.fromPlatform();
//       setState(() {
//         _packageInfo = info;
//       });
//     } catch (e) {
//       print('Failed to get package info: $e');
//     }
//   }
//
//   Future<void> _initDeviceInfo() async {
//     try {
//       final deviceInfoPlugin = DeviceInfoPlugin();
//       String deviceInfoText = '';
//
//       if (Platform.isAndroid) {
//         final androidInfo = await deviceInfoPlugin.androidInfo;
//         deviceInfoText = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
//       } else if (Platform.isIOS) {
//         final iosInfo = await deviceInfoPlugin.iosInfo;
//         deviceInfoText = 'iOS ${iosInfo.systemVersion}';
//       } else if (Platform.isWindows) {
//         final windowsInfo = await deviceInfoPlugin.windowsInfo;
//         deviceInfoText = 'Windows ${windowsInfo.computerName}';
//       } else if (Platform.isMacOS) {
//         final macInfo = await deviceInfoPlugin.macOsInfo;
//         deviceInfoText = 'macOS ${macInfo.kernelVersion}';
//       } else if (Platform.isLinux) {
//         final linuxInfo = await deviceInfoPlugin.linuxInfo;
//         deviceInfoText = 'Linux ${linuxInfo.id}';
//       }
//
//       setState(() {
//         _deviceInfo = deviceInfoText;
//         _isLoadingInfo = false;
//       });
//     } catch (e) {
//       setState(() {
//         _deviceInfo = 'Error loading device info';
//         _isLoadingInfo = false;
//       });
//     }
//   }
//
//   void _showPDF(String pdfPath, String title) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PDFViewerScreen(
//           pdfPath: pdfPath,
//           title: title,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _logout() async {
//     bool? shouldLogout = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Color(0xFF2C2C2C),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
//           title: Text('Deconectare',
//               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//           content: Text('Ești sigur că vrei să te deconectezi?',
//               style: TextStyle(color: Colors.white70)),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: Text('Anulează', style: TextStyle(color: Colors.white38)),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: Text('Deconectează', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (shouldLogout == true) {
//       try {
//         await ApiService().clearAllData();
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => start_screen()),
//               (Route<dynamic> route) => false,
//         );
//       } catch (e) {
//         _showToast('Eroare la deconectare: $e', background: Colors.redAccent);
//       }
//     }
//   }
//
//   Future<void> _submitReferral() async {
//
//     final email = _referralController.text.trim();
//     if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
//       _showToast('Te rugăm să introduci o adresă de email validă.', background: Colors.orangeAccent);
//       return;
//     }
//
//     setState(() {
//       _isSubmitting = true;
//       _showReferralField = false;
//     });
//
//     try {
//       final result = await ReferralService().referByEmail(email);
//       print("result==================================");
//
//
//       if (result['success'] == true) {
//         _showToast(result['message'] ?? 'Referral înregistrat cu succes!', background: Color(0xFF69F0AE));
//         _referralController.clear();
//       } else {
//         _showToast(result['error'] ?? 'Eroare necunoscută', background: Colors.redAccent);
//         setState(() => _showReferralField = true);
//       }
//     } catch (e) {
//       _showToast('Eroare de rețea: $e', background: Colors.redAccent);
//       setState(() => _showReferralField = true);
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }
//
//   void _showToast(String message, {Color background = Colors.grey}) {
//     _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
//     _scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(
//         content: Text(message, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
//         backgroundColor: background,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: EdgeInsets.all(16),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _referralController.dispose();
//     super.dispose();
//   }
//
//   // --- UPDATED DESIGN ---
//   @override
//   Widget build(BuildContext context) {
//     return ScaffoldMessenger(
//       key: _scaffoldMessengerKey,
//       child: Scaffold(
//         backgroundColor: Color(0xFF1E1E1E), // Premium Dark Background
//         appBar: AppBar(
//           title: Text(
//             'DESPRE NOI',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 2.0,
//               fontSize: 18,
//             ),
//           ),
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           centerTitle: true,
//         ),
//         body: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header Section
//               Center(
//                 child: Column(
//                   children: [
//                     Container(
//                       height: 100,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Color(0xFF2C2C2C),
//                         border: Border.all(color: Colors.white.withOpacity(0.05)),
//                       ),
//                       padding: EdgeInsets.all(20),
//                       child: Image.asset('assets/logos/introo.png', fit: BoxFit.contain),
//                     ),
//                     SizedBox(height: 20),
//                     Text(
//                       'FixCar',
//                       style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Servicii auto eficiente pentru o călătorie mai lină înainte',
//                       style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(height: 40),
//
//               Text(
//                 'DOCUMENTE ȘI ACȚIUNI',
//                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF448AFF), letterSpacing: 1.5),
//               ),
//               SizedBox(height: 16),
//
//               _buildActionCard(
//                 icon: Icons.description_outlined,
//                 title: 'Termeni și Condiții',
//                 subtitle: 'Ghidul legal al aplicației',
//                 onTap: () => _showPDF('assets/docs/terms_and_conditions_ro.pdf', 'Termeni și Condiții'),
//                 accentColor: Color(0xFF448AFF),
//               ),
//               _buildActionCard(
//                 icon: Icons.privacy_tip_outlined,
//                 title: 'Confidențialitate',
//                 subtitle: 'Protecția datelor tale',
//                 onTap: () => _showPDF('assets/docs/privacy_policy_ro.pdf', 'Politica de Confidențialitate'),
//                 accentColor: Color(0xFF69F0AE),
//               ),
//               _buildActionCard(
//                 icon: Icons.people_outline,
//                 title: 'Ghidul Comunității',
//                 subtitle: 'Regulile comunității FixCars',
//                 onTap: () => _showPDF('assets/docs/fixcars_community_guidelines_ro.pdf', 'Ghidul Comunității'),
//                 accentColor: Color(0xFF8B5CF6),
//               ),
//
//               SizedBox(height: 32),
//
//               // Account Actions
//               Text(
//                 'CONTUL MEU',
//                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF448AFF), letterSpacing: 1.5),
//               ),
//               SizedBox(height: 16),
//
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: _logout,
//                       style: OutlinedButton.styleFrom(
//                         side: BorderSide(color: Colors.white.withOpacity(0.1)),
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       child: Text('LOGOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: TextButton(
//                       onPressed: _showDeleteDialog,
//                       child: Text('ȘTERGE CONTUL', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 13)),
//                     ),
//                   ),
//                 ],
//               ),
//
//               SizedBox(height: 40),
//
//               // Referral Section
//               if (_showReferralField) ...[
//                 Row(
//                   children: [
//                     Text(
//                       'RECOMANDAT DE',
//                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF448AFF), letterSpacing: 1.5),
//                     ),
//                     InfoIcon(),
//                   ],
//                 ),
//                 SizedBox(height: 12),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Color(0xFF2C2C2C),
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Colors.white.withOpacity(0.05)),
//                   ),
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: _referralController,
//                           style: TextStyle(color: Colors.white),
//                           decoration: InputDecoration(
//                             hintText: 'Email angajat',
//                             hintStyle: TextStyle(color: Colors.white38),
//                             border: InputBorder.none,
//                           ),
//                         ),
//                       ),
//                       _isSubmitting
//                           ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF448AFF)))
//                           : TextButton(
//                         onPressed: _submitReferral,
//                         child: Text('TRIMITE', style: TextStyle(color: Color(0xFF448AFF), fontWeight: FontWeight.bold)),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//
//               SizedBox(height: 40),
//
//               // Info Section
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Color(0xFF2C2C2C),
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.white.withOpacity(0.05)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('INFORMAȚII SISTEM', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
//                     SizedBox(height: 16),
//                     _buildInfoRow('Versiune', '${_packageInfo.version}+${_packageInfo.buildNumber}'),
//                     _buildInfoRow('Platformă', _isLoadingInfo ? '...' : _deviceInfo),
//                     _buildInfoRow('Copyright', '2024 Charlotte IT Services'),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required Color accentColor}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: EdgeInsets.only(bottom: 12),
//         padding: EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Color(0xFF2C2C2C),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.white.withOpacity(0.05)),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: accentColor, size: 24),
//             SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
//                   Text(subtitle, style: TextStyle(color: Colors.white38, fontSize: 12)),
//                 ],
//               ),
//             ),
//             Icon(Icons.chevron_right, color: Colors.white24),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(color: Colors.white38, fontSize: 13)),
//           Text(value, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }
//
//   void _showDeleteDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Color(0xFF2C2C2C),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text('Șterge contul', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         content: Text(
//           'Această acțiune va programa ștergerea contului tău în 2 săptămâni.\n\nEfectul este ireversibil.',
//           style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: Text('Anulează', style: TextStyle(color: Colors.white38))),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF5252)),
//             onPressed: () async {
//               Navigator.pop(context);
//               try {
//                 final result = await DeleteAccountService().deleteAccount();
//                 _showToast(result['message'] ?? 'Programat pentru ștergere', background: Color(0xFF69F0AE));
//                 await ApiService().clearAllData();
//                 Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => start_screen()), (r) => false);
//               } catch (e) {
//                 _showToast('Eroare: $e', background: Colors.redAccent);
//               }
//             },
//             child: Text('Confirmă', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // --- PDF Viewer and InfoIcon Logic (Theming Updated) ---
//
// class PDFViewerScreen extends StatefulWidget {
//   final String pdfPath;
//   final String title;
//   const PDFViewerScreen({Key? key, required this.pdfPath, required this.title}) : super(key: key);
//   @override
//   _PDFViewerScreenState createState() => _PDFViewerScreenState();
// }
//
// class _PDFViewerScreenState extends State<PDFViewerScreen> {
//   String? localPath;
//   bool isLoading = true;
//   String? errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPDF();
//   }
//
//   Future<void> _loadPDF() async {
//     try {
//       final ByteData data = await rootBundle.load(widget.pdfPath);
//       final Directory tempDir = await getTemporaryDirectory();
//       final String tempPath = '${tempDir.path}/${widget.title.replaceAll(' ', '_')}.pdf';
//       final File tempFile = File(tempPath);
//       await tempFile.writeAsBytes(data.buffer.asUint8List());
//       setState(() { localPath = tempPath; isLoading = false; });
//     } catch (e) {
//       setState(() { errorMessage = 'Error: $e'; isLoading = false; });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF1E1E1E),
//       appBar: AppBar(
//         title: Text(widget.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         backgroundColor: Color(0xFF2C2C2C),
//         foregroundColor: Colors.white,
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator(color: Color(0xFF448AFF)))
//           : errorMessage != null
//           ? Center(child: Text(errorMessage!, style: TextStyle(color: Colors.white)))
//           : PDFView(filePath: localPath!),
//     );
//   }
// }
//
// class InfoIcon extends StatelessWidget {
//   const InfoIcon({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: Icon(Icons.help_outline, size: 16, color: Color(0xFF448AFF)),
//       onPressed: () {
//         showDialog(
//           context: context,
//           builder: (context) => Dialog(
//             backgroundColor: Color(0xFF2C2C2C),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             child: Padding(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.info_outline, size: 48, color: Color(0xFF448AFF)),
//                   SizedBox(height: 16),
//                   Text('Informație Referral', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
//                   SizedBox(height: 12),
//                   Text(
//                     'Doar pentru angajații FixCar – folosit pentru a urmări numărul de recomandări.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.white70, fontSize: 14),
//                   ),
//                   SizedBox(height: 24),
//                   TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: Color(0xFF448AFF)))),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
