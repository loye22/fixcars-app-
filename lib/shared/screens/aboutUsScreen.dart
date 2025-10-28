import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/DeleteAccountService.dart';
import '../services/api_service.dart';
import 'start_screen.dart';

class AboutUsScreen extends StatefulWidget {
  @override
  _AboutUsScreenState createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  void _showPDF(String pdfPath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          pdfPath: pdfPath,
          title: title,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          title: Text(
            'Deconectare',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20.0,
              color: Colors.black87,
              fontFamily: 'Roboto', // Use a clean, modern font
            ),
          ),
          content: Text(
            'Ești sigur că vrei să te deconectezi?',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.black54,
              fontFamily: 'Roboto',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Anulează',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.3),
                      blurRadius: 8.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Deconectează',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        // Clear all authentication data using ApiService
        await ApiService().clearAllData();

        // Navigate to start screen using MaterialPageRoute
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => start_screen()),
              (Route<dynamic> route) => false,
        );
      } catch (e) {
        print('Error during logout: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la deconectare: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: EdgeInsets.all(16.0),
          ),
        );
      }
    }
  }


  // Future<void> _logout() async {
  //   // Show confirmation dialog
  //   bool? shouldLogout = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Deconectare'),
  //         content: Text('Ești sigur că vrei să te deconectezi?'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(false),
  //             child: Text('Anulează'),
  //           ),
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(true),
  //             child: Text('Deconectează'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  //
  //   if (shouldLogout == true) {
  //     try {
  //       // Clear all authentication data using ApiService
  //       await ApiService().clearAllData();
  //
  //       // Navigate to start screen using MaterialPageRoute
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(builder: (context) => start_screen()),
  //         (Route<dynamic> route) => false,
  //       );
  //     } catch (e) {
  //       print('Error during logout: $e');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Eroare la deconectare: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Despre Noi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1C2526),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
            color: Color(0xFF1C2526),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo
                  Container(
                    height: 80,
                    child: Image.asset(
                      'assets/logos/introo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'FixCars',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Servicii auto eficiente pentru o călătorie mai lină înainte',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Made by Charlotte for IT Services SRL',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Action Buttons Section
            Text(
              'Documente și Acțiuni',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
              ),
            ),
            SizedBox(height: 15),
            
            // Terms & Conditions Button
            _buildActionButton(
              icon: Icons.description,
              title: 'Termeni și Condiții',
              subtitle: 'Citește termenii și condițiile aplicației',
              onTap: () => _showPDF('assets/docs/terms_and_conditions_ro.pdf', 'Termeni și Condiții'),
              color: Color(0xFF3B82F6),
            ),
            
            SizedBox(height: 15),
            
            // Privacy Policy Button
            _buildActionButton(
              icon: Icons.privacy_tip,
              title: 'Politica de Confidențialitate',
              subtitle: 'Informații despre protecția datelor tale',
              onTap: () => _showPDF('assets/docs/privacy_policy_ro.pdf', 'Politica de Confidențialitate'),
              color: Color(0xFF10B981),
            ),
            
            SizedBox(height: 15),
            
            // Community Guidelines Button
            _buildActionButton(
              icon: Icons.people,
              title: 'Ghidul Comunității',
              subtitle: 'Reguli și ghiduri pentru comunitatea FixCars',
              onTap: () => _showPDF('assets/docs/fixcars_community_guidelines_ro.pdf', 'Ghidul Comunității'),
              color: Color(0xFF8B5CF6),
            ),
            
            SizedBox(height: 25),
            
            // Logout Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF000000),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        title: Text(
                          'Șterge contul',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        content: Text(
                          'Această acțiune va programa ștergerea contului tău în 2 săptămâni.\n\n'
                              'După ce ștergerea este efectuată, acțiunea este ireversibilă.\n\n'
                              'În această perioadă de 2 săptămâni, poți anula ștergerea contactând suportul la:\n'
                              'support@fixcars.ro',
                          style: TextStyle(
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Anulează',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop(); // Închide dialogul

                              try {
                                final result = await DeleteAccountService().deleteAccount();

                                // Afișează mesaj de succes
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Contul a fost programat pentru ștergere'),
                                    backgroundColor: Colors.green,
                                  ),
                                );



                                // Apel logout
                                // Clear all authentication data using ApiService
                                await ApiService().clearAllData();

                                // Navigate to start screen using MaterialPageRoute
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => start_screen()),
                                      (Route<dynamic> route) => false,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Eroare: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Confirmă'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Șterge contul',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // App Info Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informații Aplicație',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildInfoRow('Versiune', '1.0.0'),
                  _buildInfoRow('Platformă', 'Android & iOS'),
                  _buildInfoRow('Dezvoltator', 'Charlotte for IT Services SRL'),
                  _buildInfoRow('Anul', '2024'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF4B5563),
          padding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Color(0xFFE5E7EB)),
          ),
          elevation: 2,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9CA3AF),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PDFViewerScreen({
    Key? key,
    required this.pdfPath,
    required this.title,
  }) : super(key: key);

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      // Load the asset as bytes
      final ByteData data = await rootBundle.load(widget.pdfPath);
      
      // Get the temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/${widget.title.replaceAll(' ', '_')}.pdf';
      
      // Write the bytes to a temporary file
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      
      setState(() {
        localPath = tempPath;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading PDF: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Color(0xFF4B5563),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Înapoi'),
                      ),
                    ],
                  ),
                )
              : localPath != null
                  ? PDFView(
                      filePath: localPath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: false,
                      pageSnap: true,
                      pageFling: true,
                      onRender: (pages) {
                        // PDF loaded
                      },
                      onViewCreated: (PDFViewController controller) {
                        // PDF view created
                      },
                      onPageChanged: (page, total) {
                        // Page changed
                      },
                      onError: (error) {
                        print('PDF Error: $error');
                        setState(() {
                          errorMessage = 'Error displaying PDF: $error';
                        });
                      },
                    )
                  : Center(
                      child: Text('PDF not found'),
                    ),
    );
  }
}
