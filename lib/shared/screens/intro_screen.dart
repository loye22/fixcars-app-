import 'package:fixcars/shared/screens/start_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



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
              OnboardingScreen1(),
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
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Image.asset('assets/logo.png', height: 100),
                    Text('Workshop', style: TextStyle(fontSize: 19)),
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
            SizedBox(height: 40),
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
          image: DecorationImage(
            image: AssetImage('assets/intro1.jpg'),
            // Replace with your image asset
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 100),
            Text(
              'FIXCARS',
              style: TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Servicii auto eficiente pentru o călătorie mai lină înainte',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            SizedBox(height: 20),
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
          image: DecorationImage(
            image: AssetImage('assets/intro2.png'),
            // Replace with your image asset
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 100),
            Text(
              'Descoperă servicii auto din apropiere.',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),
            Center(
              child: Text(
                'Suntem aici pentru a-ți oferi servicii și asistență\n de cea mai bună calitate.',
                style: const TextStyle(fontSize: 12, color: Colors.white),
                textAlign:
                    TextAlign.center, // Centers the text within its own bounds
              ),
            ),
            SizedBox(height: 20),
            Image.asset('assets/dots.png', width: 50),
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
          image: DecorationImage(
            image: AssetImage('assets/intro3.png'),
            // Replace with your image asset
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 100),
            Text(
              'Serviciu ușor de rezervat',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              'Stai liniștit și relaxează-te în timp ce ne ocupăm de restul',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 20),
            Image.asset('assets/dots2.png', width: 50),
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