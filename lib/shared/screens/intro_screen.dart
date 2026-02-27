import 'package:fixcars/shared/screens/start_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';



class TermsAgreementScreen extends StatefulWidget {
  @override
  _TermsAgreementScreenState createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _isAgreed = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 100,) ,
                      // Logo
                      Container(
                        height: 120,
                        child: Image.asset(
                          'assets/logos/introo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 40),
                      
                      // Title
                      Text(
                        'Bun venit la FixCars!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      
                      // Subtitle
                      Text(
                        'Pentru a continua, vă rugăm să citiți și să acceptați următoarele documente:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      
                      // Agreement text with clickable links
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(text: 'Sunt de acord cu '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => _showPDF('assets/docs/terms_and_conditions_ro.pdf', 'Termeni și Condiții'),
                                  child: Text(
                                    'Termenii și Condițiile',
                                    style: TextStyle(
                                      color: Colors.blue[300],
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(text: ', '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => _showPDF('assets/docs/privacy_policy_ro.pdf', 'Politica de Confidențialitate'),
                                  child: Text(
                                    'Politica de Confidențialitate',
                                    style: TextStyle(
                                      color: Colors.blue[300],
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(text: ' și '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => _showPDF('assets/docs/fixcars_community_guidelines_ro.pdf', 'Ghidul Comunității'),
                                  child: Text(
                                    'Ghidul Comunității',
                                    style: TextStyle(
                                      color: Colors.blue[300],
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(text: ' ale aplicației FixCars.'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      
                      // Checkbox
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _isAgreed,
                            onChanged: (value) {
                              setState(() {
                                _isAgreed = value ?? false;
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                          Expanded(
                            child: Text(
                              'Am citit și accept termenii de mai sus',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isAgreed
                      ? () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => OnboardingScreen1()),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAgreed ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text('CONTINUĂ'),
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
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
        backgroundColor: Colors.black,
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

class into_screen extends StatefulWidget {
  @override
  _into_screenState createState() => _into_screenState();
}

class _into_screenState extends State<into_screen> {
  @override
  void initState() {
    super.initState();
    // Schedule precacheImage after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(AssetImage('assets/intro1.jpg'), context);
      precacheImage(AssetImage('assets/intro2.png'), context);
      precacheImage(AssetImage('assets/intro3.png'), context);
    });
    // Navigate after a delay
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TermsAgreementScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: SizedBox(height: 10)),
            Card(
              elevation: 5,
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      // decoration: BoxDecoration(
                      //     border: Border.all(color: Colors.red)
                      // ),
                      child: SizedBox(
                        height: 250,
                        child: Image.asset(
                          'assets/logos/introo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                  //  Text('Fixcars', style: TextStyle(fontSize: 19 , color: Colors.white)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Aplicație pentru reparații auto',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Expanded(child: SizedBox(height: 10)),
            Text(
              'Made By',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Charlotte for it services SRL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}


class OnboardingScreen1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, //
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage('assets/nintro.png'),
            // Replace with your image asset
            fit: BoxFit.fitWidth,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * .33,),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OnboardingScreen2()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF808080),
                // Gray background color
                foregroundColor: Colors.white,
                // White text color
                textStyle: const TextStyle(
                  fontSize: 16, // Optional: Adjust text size
                  fontWeight: FontWeight.bold, // Optional: Make text bold
                ),
                minimumSize: const Size(500, 40),
                // Increased width and height
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ), // Optional: Additional padding
              ),

              child: Text('URMĂTORUL'),
            ),
            Expanded(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // Ensure it takes full width
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage('assets/nintro2.png'),
            // Replace with your image asset
            fit: BoxFit.fitWidth,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [

            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OnboardingScreen3()),
                  );
                },
                child: Text('URMĂTORUL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF808080),
                  // Gray background color
                  foregroundColor: Colors.white,
                  // White text color
                  textStyle: const TextStyle(
                    fontSize: 24, // Optional: Adjust text size
                    fontWeight: FontWeight.bold, // Optional: Make text bold
                  ),
                  minimumSize: const Size(500, 40),
                  // Increased width and height
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ), // Optional: Additional padding
                ),
              ),
            ),
            Expanded(child: SizedBox(height: 20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFF808080),
                      // Gray background (#808080)
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Optional: rounded corners
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => start_screen()),
                      );
                    },

                    child: Text('Omite', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // Ensure it takes full width
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage('assets/nintro3.png'),
            // Replace with your image asset
            fit: BoxFit.fitWidth,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            //SizedBox(height: 70),


           // Image.asset('assets/dots2.png', width: 50),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OnboardingScreen4()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF808080),
                  // Gray background color
                  foregroundColor: Colors.white,
                  // White text color
                  textStyle: const TextStyle(
                    fontSize: 24, // Optional: Adjust text size
                    fontWeight: FontWeight.bold, // Optional: Make text bold
                  ),
                  minimumSize: const Size(500, 40),
                  // Increased width and height
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ), // Optional: Additional padding
                ),
                child: Text('URMĂTORUL'),
              ),
            ),
            Expanded(child: SizedBox(height: 20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => start_screen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFF808080),
                      // Gray background (#808080)
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Optional: rounded corners
                      ),
                    ),
                    child: Text('Omite', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
} 

class OnboardingScreen4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage('assets/nintro4.png'),
            fit: BoxFit.fitWidth,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => start_screen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF808080),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  minimumSize: const Size(500, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                child: Text('URMĂTORUL'),
              ),
            ),
            Expanded(child: SizedBox(height: 20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => start_screen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFF808080),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text('Omite', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}