import 'package:fixcars/shared/screens/Server_down_screen.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../shared/services/NotificationService.dart';
import '../../shared/services/firebase_chat_service.dart';
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
import '../../shared/screens/aboutUsScreen.dart';



class client_home_page extends StatefulWidget {
  @override
  _client_home_pageState createState() => _client_home_pageState();
}

class _client_home_pageState extends State<client_home_page> {
  int _currentIndex = 0;
  bool _hasUnreadNotifications = false; // Add this to track notification status
  final NotificationService _notificationService = NotificationService(); // Initialize service
  final FirebaseChatService _chatService = FirebaseChatService(); // Add this

  // Screens for each tab
  final List<Widget> _screens = [
    // Home screen (original content)
    _HomeContent(),

    // Notification screen
    NotificationScreen(),

    // Chat screen
    ConversationListScreen(),

    // About Us screen
    AboutUsScreen(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _chatService.initializeFirebase(); // Initialize Firebase for chat
      _fetchNotificationStatus();
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  Future<void> _fetchNotificationStatus() async {
    try {
      bool hasUnread = await _notificationService.hasUnreadNotifications();
      setState(() {
        _hasUnreadNotifications = hasUnread;
      });
      print("notifcation $_hasUnreadNotifications");
    } catch (e) {
      print('Error fetching notification status: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return InternetConnectivityScreen(
      child: ServerDownWrapper(
        apiService:ApiService() ,
        child: Scaffold(

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
          backgroundColor: /*Colors.black*/ Color(0xFFFFFFFF),
          body: _screens[_currentIndex],
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
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
          backgroundColor: Colors.white ,//Color(0xFF4B5563),
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
                  if (_hasUnreadNotifications) // Conditionally show red dot
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
                  if (_hasUnreadNotifications) // Conditionally show red dot
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
              icon: StreamBuilder<int>(
                stream: _chatService.getTotalUnreadMessagesStream(),
                initialData: 0,
                builder: (context, snapshot) {
                  bool hasUnreadMessages = snapshot.hasData && snapshot.data! > 0;
                  return Stack(
                    children: [
                      Image.asset('assets/chat4.png', width: 24),
                      if (hasUnreadMessages)
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
                        ),
                    ],
                  );
                },
              ),
              activeIcon: StreamBuilder<int>(
                stream: _chatService.getTotalUnreadMessagesStream(),
                initialData: 0,
                builder: (context, snapshot) {
                  bool hasUnreadMessages = snapshot.hasData && snapshot.data! > 0;
                  return Stack(
                    children: [
                      Image.asset('assets/chat4.png', width: 24),
                      if (hasUnreadMessages)
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
                        ),
                    ],
                  );
                },
              ),
              label: 'Mesaje',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings) , //Image.asset('assets/setting.png', width: 24),
              activeIcon:  Icon(Icons.settings_suggest_outlined) , // Image.asset('assets/setting.png', width: 24),
              label: 'Despre',
            ),
            // BottomNavigationBarItem(
            //   icon: Stack(
            //     children: [
            //       Image.asset('assets/chat4.png', width: 24),
            //       Positioned(
            //         right: 0,
            //         child: Container(
            //           width: 10,
            //           height: 10,
            //           decoration: BoxDecoration(
            //             color: Colors.green,
            //             borderRadius: BorderRadius.circular(5),
            //           ),
            //         ),
            //       )
            //     ],
            //   ),
            //   activeIcon: Stack(
            //     children: [
            //       Image.asset('assets/chat4.png', width: 24),
            //       Positioned(
            //         right: 0,
            //         child: Container(
            //           width: 10,
            //           height: 10,
            //           decoration: BoxDecoration(
            //             color: Colors.green,
            //             borderRadius: BorderRadius.circular(5),
            //           ),
            //         ),
            //       )
            //     ],
            //   ),
            //   label: 'Mesaje',
            // ),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),                ),
                SizedBox(height: 5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

