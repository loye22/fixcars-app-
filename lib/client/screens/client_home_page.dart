import 'package:flutter/material.dart';
import 'AutocolantScreen.dart';

import 'DetailingScreen.dart';
import 'ITPScreen.dart';
import 'MecanicScreen.dart';
import '../../shared/screens/NotificationScreen.dart';
import 'TapiterieScreen.dart';
import 'TractariScreen.dart';
import 'TuningScreen.dart';
import 'VulcanizareScreen.dart';
import '../../shared/screens/conversation_list_screen.dart';



class client_home_page extends StatefulWidget {
  @override
  _client_home_pageState createState() => _client_home_pageState();
}

class _client_home_pageState extends State<client_home_page> {
  int _currentIndex = 0;

  // Screens for each tab
  final List<Widget> _screens = [
    // Home screen (original content)
    _HomeContent(),

    // Notification screen
    NotificationScreen(),

    // Chat screen
    ConversationListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
        title: Center(
          child: Text(
              'Cum te putem ajuta astăzi?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
          ),
        ),
        backgroundColor: Color(0xFF4B5563),
      )
          : null,
      backgroundColor: Color(0xFFFFFFFF),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16)
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2)
            )
          ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16)
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF4B5563),
          unselectedItemColor: Color(0xFF808080),
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset('assets/home.png', width: 24),
              activeIcon: Image.asset('assets/home.png', width: 24),
              label: 'Acasă',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Image.asset('assets/bell.png', width: 24),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  )
                ],
              ),
              activeIcon: Stack(
                children: [
                  Image.asset('assets/bell.png', width: 24),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  )
                ],
              ),
              label: 'Notificări',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Image.asset('assets/chat4.png', width: 24),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  )
                ],
              ),
              activeIcon: Stack(
                children: [
                  Image.asset('assets/chat4.png', width: 24),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  )
                ],
              ),
              label: 'Mesaje',
            ),
          ],
        ),
      ),
    );
  }
}

// Extract the home content to a separate widget
class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.all(10),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        ServiceCard(
          imageAsset: 'assets/mechanic.png',
          title: 'Mecanic Auto',
          subtitle: 'Mecanic Auto',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MecanicScreen())),
        ),
        ServiceCard(
          imageAsset: 'assets/peeling.png',
          title: 'Autocolant & Folie Auto',
          subtitle: 'Servicii de Înfoliere',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AutocolantScreen())),
        ),
        ServiceCard(
          imageAsset: 'assets/car-polish.png',
          title: 'Detaliing Auto Profesional',
          subtitle: 'Detaliere Auto',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailingScreen())),
        ),
        ServiceCard(
          imageAsset: 'assets/search.png',
          title: 'ITP',
          subtitle: 'Inspecție Tehnică Periodică',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ITPScreen())),
        ),
        ServiceCard(
          imageAsset: 'assets/cleaning.png',
          title: 'Tapiterie Auto Profesională',
          subtitle: 'Tapiterie Auto',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TapiterieScreen())),
        ),
        ServiceCard(
          imageAsset: 'assets/flat-tire.png',
          title: 'Vulcanizare Auto Mobilă',
          subtitle: 'Servicii de Anvelope',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VulcanizareScreen())),
        ),
        ServiceCard(
          imageAsset: 'assets/towing-vehicle.png',
          title: 'Tractări Auto cu Platformă',
          subtitle: 'Tractări Auto',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TractariScreen())),
        ),
        ServiceCard(
          imageAsset: 'assets/upgrade.png',
          title: 'Upgrade pentru Mașină',
          subtitle: 'Tuning Auto',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TuningScreen())),
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double imageSize;

  ServiceCard({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageSize = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  imageAsset,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


//
// class client_home_page extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Center(child: Text('Cum te putem ajuta astăzi?', style: TextStyle(color: Colors.white , fontWeight: FontWeight.w500))),
//         backgroundColor: Color(0xFF4B5563),
//       ),
//       backgroundColor: Color(0xFFFFFFFF),
//       body: GridView.count(
//         crossAxisCount: 2,
//         padding: EdgeInsets.all(10),
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 10,
//         children: [
//           ServiceCard(
//             imageAsset: 'assets/mechanic.png',
//             title: 'Mecanic Auto',
//             subtitle: 'Mecanic Auto',
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MecanicScreen())),
//           ),
//           ServiceCard(
//             imageAsset: 'assets/peeling.png',
//             title: 'Autocolant & Folie Auto',
//             subtitle: 'Servicii de Înfoliere',
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AutocolantScreen())),
//           ),
//           ServiceCard(
//             imageAsset: 'assets/car-polish.png',
//             title: 'Detaliing Auto Profesional',
//             subtitle: 'Detaliere Auto',
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailingScreen())),
//           ),
//           ServiceCard(
//             imageAsset: 'assets/search.png',
//             title: 'ITP',
//             subtitle: 'Inspecție Tehnică Periodică',
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ITPScreen())),
//           ),
//           ServiceCard(
//             imageAsset: 'assets/cleaning.png',
//             title: 'Tapiterie Auto Profesională',
//             subtitle: 'Tapiterie Auto',
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TapiterieScreen())),
//           ),
//           ServiceCard(
//             imageAsset: 'assets/flat-tire.png',
//             title: 'Vulcanizare Auto Mobilă',
//             subtitle: 'Servicii de Anvelope',
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VulcanizareScreen())),
//           ),
//
//           ServiceCard(
//             imageAsset: 'assets/towing-vehicle.png',
//             title: 'Tractări Auto cu Platformă',
//             subtitle: 'Tractări Auto',
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TractariScreen())),
//           ),
//           ServiceCard(
//             imageAsset: 'assets/upgrade.png',
//             title: 'Upgrade pentru Mașină',
//             subtitle: 'Tuning Auto',
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TuningScreen())),
//           ),
//
//
//         ],
//       ),
//     );
//   }
// }
//
// class ServiceCard extends StatelessWidget {
//   final String imageAsset; // Path to the asset image
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;
//   final double imageSize; // Flexible image size
//
//   ServiceCard({
//     required this.imageAsset,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//     this.imageSize = 80.0, // Default image size
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Card(
//         color: Colors.white,
//         shape: RoundedRectangleBorder(
//           side: BorderSide(color: Color(0xFFE5E7EB)),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(10),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Image.asset(
//                 imageAsset,
//                 width: imageSize,
//                 height: imageSize,
//                 fit: BoxFit.contain, // Flexible fit to maintain aspect ratio
//               ),
//               SizedBox(height: 10),
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//               ),
//               SizedBox(height: 5),
//               Text(
//                 subtitle,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }