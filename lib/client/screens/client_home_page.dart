import 'package:fixcars/client/screens/CaroserieSiVopsitorieScreen.dart';
import 'package:fixcars/client/screens/ClimatizareAutoScreen.dart';
import 'package:fixcars/client/screens/ElectricaAutoScreen.dart';
import 'package:fixcars/client/screens/SpalatorieAutoScreen.dart';
import 'package:fixcars/shared/screens/Server_down_screen.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/services/NotificationService.dart';
import '../../shared/services/firebase_chat_service.dart';
import '../../shared/widgets/location_permission_gate.dart';
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
  bool _hasUnreadNotifications = false;
  final NotificationService _notificationService = NotificationService();
  final FirebaseChatService _chatService = FirebaseChatService();

  final List<Widget> _screens = [
    _HomeContent(),
    NotificationScreen(),
    ConversationListScreen(),
    AboutUsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _chatService.initializeFirebase();
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
    } catch (e) {
      print('Error fetching notification status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InternetConnectivityScreen(
      child: ServerDownWrapper(
        apiService: ApiService(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _screens[_currentIndex],
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: _metallicGradient(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF1A1A2E),
          unselectedItemColor: const Color(0xFF1A1A2E),
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A2E).withOpacity(0.6),
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            _navItemWithDot(
              outline: CupertinoIcons.house,
              filled: CupertinoIcons.house_fill,
              label: 'Acasă',
              isSelected: _currentIndex == 0,
            ),
            _navItemWithBadgeAndDot(
              outline: CupertinoIcons.bell,
              filled: CupertinoIcons.bell_fill,
              label: 'Notificări',
              showBadge: _hasUnreadNotifications,
              badgeColor: Colors.red,
              isSelected: _currentIndex == 1,
            ),
            _navItemWithStreamBadgeAndDot(
              outline: CupertinoIcons.chat_bubble,
              filled: CupertinoIcons.chat_bubble_fill,
              label: 'Mesaje',
              stream: _chatService.getTotalUnreadMessagesStream(),
              badgeColor: Colors.green,
              isSelected: _currentIndex == 2,
            ),
            _navItemWithDot(
              outline: CupertinoIcons.gear,
              filled: CupertinoIcons.gear_solid,
              label: 'Despre',
              isSelected: _currentIndex == 3,
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────── Bottom Nav Helpers ──────────────────────
  BottomNavigationBarItem _navItemWithDot({
    required IconData outline,
    required IconData filled,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: _iconWithDot(outline, isSelected),
      activeIcon: _iconWithDot(filled, isSelected),
      label: label,
    );
  }

  BottomNavigationBarItem _navItemWithBadgeAndDot({
    required IconData outline,
    required IconData filled,
    required String label,
    required bool showBadge,
    required Color badgeColor,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: _badgeIcon(outline, showBadge, badgeColor, isSelected),
      activeIcon: _badgeIcon(filled, showBadge, badgeColor, isSelected),
      label: label,
    );
  }

  BottomNavigationBarItem _navItemWithStreamBadgeAndDot({
    required IconData outline,
    required IconData filled,
    required String label,
    required Stream<int> stream,
    required Color badgeColor,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: StreamBuilder<int>(
        stream: stream,
        initialData: 0,
        builder: (c, snap) {
          final bool show = snap.hasData && snap.data! > 0;
          return _badgeIcon(outline, show, badgeColor, isSelected);
        },
      ),
      activeIcon: StreamBuilder<int>(
        stream: stream,
        initialData: 0,
        builder: (c, snap) {
          final bool show = snap.hasData && snap.data! > 0;
          return _badgeIcon(filled, show, badgeColor, isSelected);
        },
      ),
      label: label,
    );
  }

  Widget _iconWithDot(IconData icon, bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: const Color(0xFF1A1A2E)),
        if (selected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _badgeIcon(
      IconData icon,
      bool showBadge,
      Color badgeColor,
      bool isSelected,
      ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _iconWithDot(icon, isSelected),
        if (showBadge)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  LinearGradient _metallicGradient() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF787878),
        Color(0xFFE5E5E5),
        Color(0xFF787878),
      ],
      stops: [0.0, 0.5, 1.0],
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> services = [
    {'title': 'MECANICĂ AUTO', 'screen': () => LocationPermissionGate(child: MecanicScreen())},
    {'title': 'ELECTRICĂ AUTO', 'screen': () => LocationPermissionGate(child: ElectricaAutoScreen())},
    {'title': 'TUNING AUTO', 'screen': () => LocationPermissionGate(child: TuningScreen())},
    {'title': 'CAROSERIE & VOPSITORIE', 'screen': () => LocationPermissionGate(child: CaroserieSiVopsitorieScreen())},
    {'title': 'VULCANIZARE & GEOMETRIE', 'screen': () => LocationPermissionGate(child: VulcanizareScreen())},
    {'title': 'CLIMATIZARE AUTO', 'screen': () => LocationPermissionGate(child: ClimatizareAutoScreen())},
    {'title': 'AUTOCOLANT & FOLIE', 'screen': () => LocationPermissionGate(child: AutocolantScreen())},
    {'title': 'TAPIȚERIE AUTO', 'screen': () => LocationPermissionGate(child: TapiterieScreen())},
    {'title': 'SPĂLĂTORIE AUTO', 'screen': () => LocationPermissionGate(child: SpalatorieAutoScreen())},
    {'title': 'DETAILING AUTO', 'screen': () => LocationPermissionGate(child: DetailingScreen())},
    {'title': 'ITP', 'screen': () => LocationPermissionGate(child: ITPScreen())},
    {'title': 'TRACTĂRI AUTO', 'screen': () => LocationPermissionGate(child: TractariScreen())},

  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Luxury Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
          decoration: BoxDecoration(
            gradient: _metallicGradient(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Cum te putem ajuta astăzi?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
           //   const SizedBox(height: 12),
              Container(
                width: 60,
                height: 2,
                color: const Color(0xFF1A1A2E).withOpacity(0.4),
              ),
            ],
          ),
        ),

        // Service Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 1.75,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return _ServiceTile(
                  title: service['title'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => service['screen']()),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  LinearGradient _metallicGradient() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF787878),
        Color(0xFFE5E5E5),
        Color(0xFF787878),
      ],
      stops: [0.0, 0.5, 1.0],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ServiceTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: _metallicGradient(),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  LinearGradient _metallicGradient() {
    return const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF787878),
        Color(0xFFE5E5E5),
        Color(0xFF787878),
      ],
      stops: [0.0, 0.5, 1.0],
    );
  }
}



// import 'package:fixcars/client/screens/CaroserieSiVopsitorieScreen.dart';
// import 'package:fixcars/client/screens/ClimatizareAutoScreen.dart';
// import 'package:fixcars/client/screens/ElectricaAutoScreen.dart';
// import 'package:fixcars/client/screens/SpalatorieAutoScreen.dart';
// import 'package:fixcars/shared/screens/Server_down_screen.dart';
// import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
// import 'package:fixcars/shared/services/api_service.dart';
// import 'package:flutter/material.dart';
// import '../../shared/services/NotificationService.dart';
// import '../../shared/services/firebase_chat_service.dart';
// import '../../shared/widgets/location_permission_gate.dart';
// import 'AutocolantScreen.dart';
//
// import 'DetailingScreen.dart';
// import 'ITPScreen.dart';
// import 'MecanicScreen.dart';
// import '../../shared/screens/NotificationScreen.dart';
// import 'TapiterieScreen.dart';
// import 'TractariScreen.dart';
// import 'TuningScreen.dart';
// import 'VulcanizareScreen.dart';
// import '../../shared/screens/conversation_list_screen.dart';
// import '../../shared/screens/aboutUsScreen.dart';
//
//
//
// class client_home_page extends StatefulWidget {
//   @override
//   _client_home_pageState createState() => _client_home_pageState();
// }
//
// class _client_home_pageState extends State<client_home_page> {
//   int _currentIndex = 0;
//   bool _hasUnreadNotifications = false; // Add this to track notification status
//   final NotificationService _notificationService = NotificationService(); // Initialize service
//   final FirebaseChatService _chatService = FirebaseChatService(); // Add this
//
//   // Screens for each tab
//   final List<Widget> _screens = [
//     // Home screen (original content)
//     _HomeContent(),
//
//     // Notification screen
//     NotificationScreen(),
//
//     // Chat screen
//     ConversationListScreen(),
//
//     // About Us screen
//     AboutUsScreen(),
//   ];
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _initializeServices();
//   }
//
//   Future<void> _initializeServices() async {
//     try {
//       await _chatService.initializeFirebase(); // Initialize Firebase for chat
//       _fetchNotificationStatus();
//     } catch (e) {
//       print('Error initializing services: $e');
//     }
//   }
//
//   Future<void> _fetchNotificationStatus() async {
//     try {
//       bool hasUnread = await _notificationService.hasUnreadNotifications();
//       setState(() {
//         _hasUnreadNotifications = hasUnread;
//       });
//       print("notifcation $_hasUnreadNotifications");
//     } catch (e) {
//       print('Error fetching notification status: $e');
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return InternetConnectivityScreen(
//       child: ServerDownWrapper(
//         apiService:ApiService() ,
//         child: Scaffold(
//
//           appBar: _currentIndex == 0
//               ? AppBar(
//             title: Center(
//               child: Text(
//                   'Cum te putem ajuta astăzi?',
//                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
//               ),
//             ),
//             backgroundColor: Color(0xFF4B5563),
//           )
//               : null,
//           backgroundColor: /*Colors.black*/ Color(0xFFFFFFFF),
//           body: _screens[_currentIndex],
//           bottomNavigationBar: _buildBottomNavBar(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomNavBar() {
//     return Container(
//       decoration: BoxDecoration(
//           borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(16),
//               topRight: Radius.circular(16)
//           ),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 8,
//                 offset: Offset(0, -2)
//             )
//           ]
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(16),
//             topRight: Radius.circular(16)
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _currentIndex,
//           onTap: (index) {
//             setState(() {
//               _currentIndex = index;
//             });
//           },
//           backgroundColor: Colors.white ,//Color(0xFF4B5563),
//           selectedItemColor: Color(0xFF4B5563),
//           unselectedItemColor: Color(0xFF808080),
//           selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//           unselectedLabelStyle: TextStyle(fontSize: 12),
//           type: BottomNavigationBarType.fixed,
//           elevation: 8,
//           items: [
//             BottomNavigationBarItem(
//               icon: Image.asset('assets/home.png', width: 24),
//               activeIcon: Image.asset('assets/home.png', width: 24),
//               label: 'Acasă',
//             ),
//             BottomNavigationBarItem(
//               icon: Stack(
//                 children: [
//                   Image.asset('assets/bell.png', width: 24),
//                   if (_hasUnreadNotifications) // Conditionally show red dot
//                   Positioned(
//                     right: 0,
//                     child: Container(
//                       width: 10,
//                       height: 10,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         borderRadius: BorderRadius.circular(5),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//               activeIcon: Stack(
//                 children: [
//                   Image.asset('assets/bell.png', width: 24),
//                   if (_hasUnreadNotifications) // Conditionally show red dot
//                   Positioned(
//                     right: 0,
//                     child: Container(
//                       width: 10,
//                       height: 10,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         borderRadius: BorderRadius.circular(5),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//               label: 'Notificări',
//             ),
//             BottomNavigationBarItem(
//               icon: StreamBuilder<int>(
//                 stream: _chatService.getTotalUnreadMessagesStream(),
//                 initialData: 0,
//                 builder: (context, snapshot) {
//                   bool hasUnreadMessages = snapshot.hasData && snapshot.data! > 0;
//                   return Stack(
//                     children: [
//                       Image.asset('assets/chat4.png', width: 24),
//                       if (hasUnreadMessages)
//                         Positioned(
//                           right: 0,
//                           child: Container(
//                             width: 10,
//                             height: 10,
//                             decoration: BoxDecoration(
//                               color: Colors.green,
//                               borderRadius: BorderRadius.circular(5),
//                             ),
//                           ),
//                         ),
//                     ],
//                   );
//                 },
//               ),
//               activeIcon: StreamBuilder<int>(
//                 stream: _chatService.getTotalUnreadMessagesStream(),
//                 initialData: 0,
//                 builder: (context, snapshot) {
//                   bool hasUnreadMessages = snapshot.hasData && snapshot.data! > 0;
//                   return Stack(
//                     children: [
//                       Image.asset('assets/chat4.png', width: 24),
//                       if (hasUnreadMessages)
//                         Positioned(
//                           right: 0,
//                           child: Container(
//                             width: 10,
//                             height: 10,
//                             decoration: BoxDecoration(
//                               color: Colors.green,
//                               borderRadius: BorderRadius.circular(5),
//                             ),
//                           ),
//                         ),
//                     ],
//                   );
//                 },
//               ),
//               label: 'Mesaje',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.settings) , //Image.asset('assets/setting.png', width: 24),
//               activeIcon:  Icon(Icons.settings_suggest_outlined) , // Image.asset('assets/setting.png', width: 24),
//               label: 'Despre',
//             ),
//             // BottomNavigationBarItem(
//             //   icon: Stack(
//             //     children: [
//             //       Image.asset('assets/chat4.png', width: 24),
//             //       Positioned(
//             //         right: 0,
//             //         child: Container(
//             //           width: 10,
//             //           height: 10,
//             //           decoration: BoxDecoration(
//             //             color: Colors.green,
//             //             borderRadius: BorderRadius.circular(5),
//             //           ),
//             //         ),
//             //       )
//             //     ],
//             //   ),
//             //   activeIcon: Stack(
//             //     children: [
//             //       Image.asset('assets/chat4.png', width: 24),
//             //       Positioned(
//             //         right: 0,
//             //         child: Container(
//             //           width: 10,
//             //           height: 10,
//             //           decoration: BoxDecoration(
//             //             color: Colors.green,
//             //             borderRadius: BorderRadius.circular(5),
//             //           ),
//             //         ),
//             //       )
//             //     ],
//             //   ),
//             //   label: 'Mesaje',
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Extract the home content to a separate widget
// class _HomeContent extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GridView.count(
//       crossAxisCount: 2,
//       padding: EdgeInsets.all(10),
//       crossAxisSpacing: 10,
//       mainAxisSpacing: 10,
//       children: [
//         ServiceCard(
//           imageAsset: 'assets/mechanic.png',
//           title: 'Mecanic Auto',
//           subtitle: 'Mecanic Auto',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: MecanicScreen()))),
//         ),
//         ServiceCard(
//           imageAsset: 'assets/peeling.png',
//           title: 'Autocolant & Folie Auto',
//           subtitle: 'Servicii de Înfoliere',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: AutocolantScreen()))),
//         ),
//         ServiceCard(
//           imageAsset: 'assets/car-polish.png',
//           title: 'Detaliing Auto Profesional',
//           subtitle: 'Detaliere Auto',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: DetailingScreen()))),
//         ),
//         ServiceCard(
//           imageAsset: 'assets/search.png',
//           title: 'ITP',
//           subtitle: 'Inspecție Tehnică Periodică',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: ITPScreen()))),
//         ),
//         ServiceCard(
//           imageAsset: 'assets/cleaning.png',
//           title: 'Tapiterie Auto Profesională',
//           subtitle: 'Tapiterie Auto',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: TapiterieScreen()))),
//         ),
//         ServiceCard(
//           imageAsset: 'assets/flat-tire.png',
//           title: 'Vulcanizare Auto Mobilă',
//           subtitle: 'Servicii de Anvelope',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: VulcanizareScreen()))),
//         ),
//         ServiceCard(
//           imageAsset: 'assets/towing-vehicle.png',
//           title: 'Tractări Auto cu Platformă',
//           subtitle: 'Tractări Auto',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: TractariScreen()))),
//         ),
//         ServiceCard(
//           imageAsset: 'assets/upgrade.png',
//           title: 'Upgrade pentru Mașină',
//           subtitle: 'Tuning Auto',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: TuningScreen()))),
//         ),
//
//         ServiceCard(
//           imageAsset: 'assets/logos/1.png',
//           title: 'Electrica Auto',
//           subtitle: 'Electrica Auto',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: ElectricaAutoScreen()))),
//         ),
//
//         ServiceCard(
//           imageAsset: 'assets/logos/1.png',
//           title: 'Caroserie Si Vopsitorie',
//           subtitle: 'Caroserie Si Vopsitorie',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: CaroserieSiVopsitorieScreen()))),
//         ),
//
//         ServiceCard(
//           imageAsset: 'assets/logos/1.png',
//           title: 'Climatizare Auto',
//           subtitle: 'Climatizare Auto',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: ClimatizareAutoScreen()))),
//         ),
//
//         ServiceCard(
//           imageAsset: 'assets/logos/1.png',
//           title: 'Spalatorie Auto',
//           subtitle: 'Spalatorie Auto',
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: SpalatorieAutoScreen()))),
//         ),
//       ],
//     );
//   }
// }
//
// class ServiceCard extends StatelessWidget {
//   final String imageAsset;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;
//   final double imageSize;
//
//   ServiceCard({
//     required this.imageAsset,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//     this.imageSize = 80.0,
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
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Flexible(
//                 flex: 3,
//                 child: Image.asset(
//                   imageAsset,
//                   width: imageSize,
//                   height: imageSize,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//               SizedBox(height: 8),
//               Flexible(
//                 flex: 2,
//                 child: Text(
//                   title,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               SizedBox(height: 4),
//               Flexible(
//                 flex: 1,
//                 child: Text(
//                   subtitle,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: Colors.grey,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
