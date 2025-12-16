import 'package:fixcars/client/screens/CarLoadingDecisionScreen.dart';
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
import 'car_initiate_screen.dart';


// ───────────────────────────────────── COLOR PALETTE ─────────────────────────────────────
// Tema Dark Mode Premium
const Color _darkBackground = Color(0xFF0A0A0A);
const Color _darkCard = Color(0xFF141414);
const Color _accentSilver = Color(0xFFB0B0B0); // Argintiu/Gri subtil
const Color _primaryText = Color(0xFFF0F0F0);
const Color _secondaryText = Color(0xFFAAAAAA);
const Color _navBarColor = Color(0xFF1A1A1A);
const Color _primaryBlack = Color(0xFF1A1A2E);


class client_home_page extends StatefulWidget {
  @override
  _client_home_pageState createState() => _client_home_pageState();
}

class _client_home_pageState extends State<client_home_page> {
  int _currentIndex = 0;
  bool _hasUnreadNotifications = false;
  final NotificationService _notificationService = NotificationService();
  final FirebaseChatService _chatService = FirebaseChatService();

  // LISTA DE ECRANE ACTUALIZATĂ
  final List<Widget> _screens = [
    _HomeContent(),             // Index 0: Acasă
    NotificationScreen(),       // Index 1: Notificări
    CarLoadingDecisionScreen(),
    // CarInitiateScreen(),        // Index 2: Gestionează Mașina
    ConversationListScreen(),   // Index 3: Mesaje
    AboutUsScreen(),            // Index 4: Despre
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
          backgroundColor: _darkBackground,
          body: _screens[_currentIndex],
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      // 1. MARGINI ELIMINATE: Bara ocupă lățimea completă.
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: _navBarColor,
        // 2. COLȚURI ROTUNJITE ELIMINATE.
        borderRadius: BorderRadius.zero,
        boxShadow: [
          // Umbra este orientată în sus pentru a separa bara de conținut
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, -10),
          ),
        ],
        // 3. Bordura superioară subtilă.
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
      ),
      // 4. Eliminăm ClipRRect
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        // Fundalul barei de navigare setat la culoarea Container-ului
        backgroundColor: _navBarColor,
        selectedItemColor: _accentSilver,
        unselectedItemColor: _secondaryText.withOpacity(0.6),
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _accentSilver,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _secondaryText.withOpacity(0.6),
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: [
          // Index 0: Acasă
          _navItemWithDot(
            outline: CupertinoIcons.house,
            filled: CupertinoIcons.house_fill,
            label: 'Acasă',
            isSelected: _currentIndex == 0,
          ),
          // Index 1: Notificări
          _navItemWithBadgeAndDot(
            outline: CupertinoIcons.bell,
            filled: CupertinoIcons.bell_fill,
            label: 'Notificări',
            showBadge: _hasUnreadNotifications,
            badgeColor: const Color(0xFFE74C3C),
            isSelected: _currentIndex == 1,
          ),
          // Index 2: Gestionează Mașina (NOU)
          _navItemWithDot(
            outline: CupertinoIcons.car_detailed,
            filled: CupertinoIcons.car_detailed,
            label: 'Mașina mea',
            isSelected: _currentIndex == 2,
          ),
          // Index 3: Mesaje
          _navItemWithStreamBadgeAndDot(
            outline: CupertinoIcons.chat_bubble,
            filled: CupertinoIcons.chat_bubble_fill,
            label: 'Mesaje',
            stream: _chatService.getTotalUnreadMessagesStream(),
            badgeColor: const Color(0xFF2ECC71),
            isSelected: _currentIndex == 3,
          ),
          // Index 4: Despre
          _navItemWithDot(
            outline: CupertinoIcons.info_circle,
            filled: CupertinoIcons.info_circle_fill,
            label: 'Despre',
            isSelected: _currentIndex == 4,
          ),
        ],
      ),
    );
  }

  // ────────────────────── Bottom Nav Helpers (Logica Păstrată) ──────────────────────

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
        Icon(icon, size: 28, color: selected ? _accentSilver : _secondaryText.withOpacity(0.6)),
        if (selected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _accentSilver,
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
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: _navBarColor, width: 2), // Margine pentru contrast
              ),
            ),
          ),
      ],
    );
  }
}


// ───────────────────────────────────── HOME CONTENT (REDESIGNED) ─────────────────────────────────────

class _HomeContent extends StatelessWidget {
  // Lista de servicii PĂSTRATĂ EXACT CA ÎN ORIGINAL
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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: _darkBackground,
          elevation: 0,
          pinned: true,
          expandedHeight: 200.0,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
            // Header-ul (Titlul) Redesenat
            title: Text(
              'Cum te putem ajuta astăzi?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _primaryText,
              ),
            ),
            background: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo-ul aplicației în Header
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _darkCard,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/logos/t1.png',
                        color: _accentSilver,
                      ),
                    ),
                  ),

                  // Mesajul principal (Repetat în background pentru efect)
                  Text(
                    'GARAJUL TĂU DIGITAL',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _secondaryText,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Grila de Servicii
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4, // Carduri mai late
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final service = services[index];
                return _ServiceTile(
                  title: service['title'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => service['screen']()),
                    );
                  },
                  // Atribuie o pictogramă relevantă pentru o estetică mai bună
                  icon: _getServiceIcon(service['title']),
                );
              },
              childCount: services.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 100), // Spațiu pentru a nu fi acoperit de nav bar
        )
      ],
    );
  }

  // Helper pentru a asocia pictograme serviciilor (opțional, dar arată mai elegant)
  IconData _getServiceIcon(String title) {
    if (title.contains('MECANICĂ')) return CupertinoIcons.wrench_fill;
    if (title.contains('ELECTRICĂ')) return CupertinoIcons.battery_25;
    if (title.contains('TUNING')) return CupertinoIcons.car_fill;
    if (title.contains('CAROSERIE')) return CupertinoIcons.paintbrush;
    if (title.contains('VULCANIZARE')) return CupertinoIcons.speedometer;
    if (title.contains('CLIMATIZARE')) return CupertinoIcons.snow;
    if (title.contains('AUTOCOLANT')) return CupertinoIcons.square_stack_3d_up_fill;
    if (title.contains('TAPIȚERIE')) return CupertinoIcons.bed_double_fill;
    if (title.contains('SPĂLĂTORIE')) return CupertinoIcons.drop_fill;
    if (title.contains('DETAILING')) return CupertinoIcons.sparkles;
    if (title.contains('ITP')) return CupertinoIcons.search;
    if (title.contains('TRACTĂRI')) return CupertinoIcons.rectangle_on_rectangle_angled;
    return CupertinoIcons.gear_alt_fill;
  }
}

// ───────────────────────────────────── SERVICE TILE (REDESIGNED) ─────────────────────────────────────

class _ServiceTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData icon;

  const _ServiceTile({required this.title, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _darkCard,
          borderRadius: BorderRadius.circular(20),
          // Umbra este esențială pentru a da adâncime pe fundalul întunecat
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: _accentSilver.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Iconița în stil iOS
            Icon(
              icon,
              size: 38,
              color: _accentSilver,
            ),
            const SizedBox(height: 10),
            // Titlul serviciului
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _primaryText,
                letterSpacing: 0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Indicator vizual
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 30,
              height: 2,
              color: _accentSilver.withOpacity(0.4),
            ),
          ],
        ),
      ),
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
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../shared/services/NotificationService.dart';
// import '../../shared/services/firebase_chat_service.dart';
// import '../../shared/widgets/location_permission_gate.dart';
// import 'AutocolantScreen.dart';
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
// class client_home_page extends StatefulWidget {
//   @override
//   _client_home_pageState createState() => _client_home_pageState();
// }
//
// class _client_home_pageState extends State<client_home_page> {
//   int _currentIndex = 0;
//   bool _hasUnreadNotifications = false;
//   final NotificationService _notificationService = NotificationService();
//   final FirebaseChatService _chatService = FirebaseChatService();
//
//   final List<Widget> _screens = [
//     _HomeContent(),
//     NotificationScreen(),
//     ConversationListScreen(),
//     AboutUsScreen(),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeServices();
//   }
//
//   Future<void> _initializeServices() async {
//     try {
//       await _chatService.initializeFirebase();
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
//     } catch (e) {
//       print('Error fetching notification status: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return InternetConnectivityScreen(
//       child: ServerDownWrapper(
//         apiService: ApiService(),
//         child: Scaffold(
//           backgroundColor: Colors.black,
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
//         gradient: _metallicGradient(),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 12,
//             offset: const Offset(0, -4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         child: BottomNavigationBar(
//           currentIndex: _currentIndex,
//           onTap: (i) => setState(() => _currentIndex = i),
//           backgroundColor: Colors.transparent,
//           selectedItemColor: const Color(0xFF1A1A2E),
//           unselectedItemColor: const Color(0xFF1A1A2E),
//           selectedLabelStyle: GoogleFonts.inter(
//             fontSize: 11,
//             fontWeight: FontWeight.w600,
//             color: const Color(0xFF1A1A2E),
//           ),
//           unselectedLabelStyle: GoogleFonts.inter(
//             fontSize: 11,
//             fontWeight: FontWeight.w500,
//             color: const Color(0xFF1A1A2E).withOpacity(0.6),
//           ),
//           type: BottomNavigationBarType.fixed,
//           elevation: 0,
//           items: [
//             _navItemWithDot(
//               outline: CupertinoIcons.house,
//               filled: CupertinoIcons.house_fill,
//               label: 'Acasă',
//               isSelected: _currentIndex == 0,
//             ),
//             _navItemWithBadgeAndDot(
//               outline: CupertinoIcons.bell,
//               filled: CupertinoIcons.bell_fill,
//               label: 'Notificări',
//               showBadge: _hasUnreadNotifications,
//               badgeColor: Colors.red,
//               isSelected: _currentIndex == 1,
//             ),
//             _navItemWithStreamBadgeAndDot(
//               outline: CupertinoIcons.chat_bubble,
//               filled: CupertinoIcons.chat_bubble_fill,
//               label: 'Mesaje',
//               stream: _chatService.getTotalUnreadMessagesStream(),
//               badgeColor: Colors.green,
//               isSelected: _currentIndex == 2,
//             ),
//             _navItemWithDot(
//               outline: CupertinoIcons.gear,
//               filled: CupertinoIcons.gear_solid,
//               label: 'Despre',
//               isSelected: _currentIndex == 3,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ────────────────────── Bottom Nav Helpers ──────────────────────
//   BottomNavigationBarItem _navItemWithDot({
//     required IconData outline,
//     required IconData filled,
//     required String label,
//     required bool isSelected,
//   }) {
//     return BottomNavigationBarItem(
//       icon: _iconWithDot(outline, isSelected),
//       activeIcon: _iconWithDot(filled, isSelected),
//       label: label,
//     );
//   }
//
//   BottomNavigationBarItem _navItemWithBadgeAndDot({
//     required IconData outline,
//     required IconData filled,
//     required String label,
//     required bool showBadge,
//     required Color badgeColor,
//     required bool isSelected,
//   }) {
//     return BottomNavigationBarItem(
//       icon: _badgeIcon(outline, showBadge, badgeColor, isSelected),
//       activeIcon: _badgeIcon(filled, showBadge, badgeColor, isSelected),
//       label: label,
//     );
//   }
//
//   BottomNavigationBarItem _navItemWithStreamBadgeAndDot({
//     required IconData outline,
//     required IconData filled,
//     required String label,
//     required Stream<int> stream,
//     required Color badgeColor,
//     required bool isSelected,
//   }) {
//     return BottomNavigationBarItem(
//       icon: StreamBuilder<int>(
//         stream: stream,
//         initialData: 0,
//         builder: (c, snap) {
//           final bool show = snap.hasData && snap.data! > 0;
//           return _badgeIcon(outline, show, badgeColor, isSelected);
//         },
//       ),
//       activeIcon: StreamBuilder<int>(
//         stream: stream,
//         initialData: 0,
//         builder: (c, snap) {
//           final bool show = snap.hasData && snap.data! > 0;
//           return _badgeIcon(filled, show, badgeColor, isSelected);
//         },
//       ),
//       label: label,
//     );
//   }
//
//   Widget _iconWithDot(IconData icon, bool selected) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 26, color: const Color(0xFF1A1A2E)),
//         if (selected)
//           Container(
//             margin: const EdgeInsets.only(top: 4),
//             width: 5,
//             height: 5,
//             decoration: const BoxDecoration(
//               color: Color(0xFF1A1A2E),
//               shape: BoxShape.circle,
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _badgeIcon(
//       IconData icon,
//       bool showBadge,
//       Color badgeColor,
//       bool isSelected,
//       ) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         _iconWithDot(icon, isSelected),
//         if (showBadge)
//           Positioned(
//             right: -2,
//             top: -2,
//             child: Container(
//               width: 10,
//               height: 10,
//               decoration: BoxDecoration(
//                 color: badgeColor,
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: badgeColor.withOpacity(0.4),
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//       ],
//     );
//   }
//
//   LinearGradient _metallicGradient() {
//     return const LinearGradient(
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//       colors: [
//         Color(0xFF787878),
//         Color(0xFFE5E5E5),
//         Color(0xFF787878),
//       ],
//       stops: [0.0, 0.5, 1.0],
//     );
//   }
// }
//
// class _HomeContent extends StatelessWidget {
//   final List<Map<String, dynamic>> services = [
//     {'title': 'MECANICĂ AUTO', 'screen': () => LocationPermissionGate(child: MecanicScreen())},
//     {'title': 'ELECTRICĂ AUTO', 'screen': () => LocationPermissionGate(child: ElectricaAutoScreen())},
//     {'title': 'TUNING AUTO', 'screen': () => LocationPermissionGate(child: TuningScreen())},
//     {'title': 'CAROSERIE & VOPSITORIE', 'screen': () => LocationPermissionGate(child: CaroserieSiVopsitorieScreen())},
//     {'title': 'VULCANIZARE & GEOMETRIE', 'screen': () => LocationPermissionGate(child: VulcanizareScreen())},
//     {'title': 'CLIMATIZARE AUTO', 'screen': () => LocationPermissionGate(child: ClimatizareAutoScreen())},
//     {'title': 'AUTOCOLANT & FOLIE', 'screen': () => LocationPermissionGate(child: AutocolantScreen())},
//     {'title': 'TAPIȚERIE AUTO', 'screen': () => LocationPermissionGate(child: TapiterieScreen())},
//     {'title': 'SPĂLĂTORIE AUTO', 'screen': () => LocationPermissionGate(child: SpalatorieAutoScreen())},
//     {'title': 'DETAILING AUTO', 'screen': () => LocationPermissionGate(child: DetailingScreen())},
//     {'title': 'ITP', 'screen': () => LocationPermissionGate(child: ITPScreen())},
//     {'title': 'TRACTĂRI AUTO', 'screen': () => LocationPermissionGate(child: TractariScreen())},
//
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Luxury Header
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
//           decoration: BoxDecoration(
//             gradient: _metallicGradient(),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               Text(
//                 'Cum te putem ajuta astăzi?',
//                 style: GoogleFonts.playfairDisplay(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF1A1A2E),
//                   height: 1.2,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//            //   const SizedBox(height: 12),
//               Container(
//                 width: 60,
//                 height: 2,
//                 color: const Color(0xFF1A1A2E).withOpacity(0.4),
//               ),
//             ],
//           ),
//         ),
//
//         // Service Grid
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: GridView.builder(
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 18,
//                 mainAxisSpacing: 18,
//                 childAspectRatio: 1.75,
//               ),
//               itemCount: services.length,
//               itemBuilder: (context, index) {
//                 final service = services[index];
//                 return _ServiceTile(
//                   title: service['title'],
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => service['screen']()),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   LinearGradient _metallicGradient() {
//     return const LinearGradient(
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//       colors: [
//         Color(0xFF787878),
//         Color(0xFFE5E5E5),
//         Color(0xFF787878),
//       ],
//       stops: [0.0, 0.5, 1.0],
//     );
//   }
// }
//
// class _ServiceTile extends StatelessWidget {
//   final String title;
//   final VoidCallback onTap;
//
//   const _ServiceTile({required this.title, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: _metallicGradient(),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.15),
//               blurRadius: 20,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Center(
//           child: Text(
//             title,
//             style: GoogleFonts.inter(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//               letterSpacing: 1.2,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       ),
//     );
//   }
//
//   LinearGradient _metallicGradient() {
//     return const LinearGradient(
//       begin: Alignment.centerLeft,
//       end: Alignment.centerRight,
//       colors: [
//         Color(0xFF787878),
//         Color(0xFFE5E5E5),
//         Color(0xFF787878),
//       ],
//       stops: [0.0, 0.5, 1.0],
//     );
//   }
// }
//
//
//
// // import 'package:fixcars/client/screens/CaroserieSiVopsitorieScreen.dart';
// // import 'package:fixcars/client/screens/ClimatizareAutoScreen.dart';
// // import 'package:fixcars/client/screens/ElectricaAutoScreen.dart';
// // import 'package:fixcars/client/screens/SpalatorieAutoScreen.dart';
// // import 'package:fixcars/shared/screens/Server_down_screen.dart';
// // import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
// // import 'package:fixcars/shared/services/api_service.dart';
// // import 'package:flutter/material.dart';
// // import '../../shared/services/NotificationService.dart';
// // import '../../shared/services/firebase_chat_service.dart';
// // import '../../shared/widgets/location_permission_gate.dart';
// // import 'AutocolantScreen.dart';
// //
// // import 'DetailingScreen.dart';
// // import 'ITPScreen.dart';
// // import 'MecanicScreen.dart';
// // import '../../shared/screens/NotificationScreen.dart';
// // import 'TapiterieScreen.dart';
// // import 'TractariScreen.dart';
// // import 'TuningScreen.dart';
// // import 'VulcanizareScreen.dart';
// // import '../../shared/screens/conversation_list_screen.dart';
// // import '../../shared/screens/aboutUsScreen.dart';
// //
// //
// //
// // class client_home_page extends StatefulWidget {
// //   @override
// //   _client_home_pageState createState() => _client_home_pageState();
// // }
// //
// // class _client_home_pageState extends State<client_home_page> {
// //   int _currentIndex = 0;
// //   bool _hasUnreadNotifications = false; // Add this to track notification status
// //   final NotificationService _notificationService = NotificationService(); // Initialize service
// //   final FirebaseChatService _chatService = FirebaseChatService(); // Add this
// //
// //   // Screens for each tab
// //   final List<Widget> _screens = [
// //     // Home screen (original content)
// //     _HomeContent(),
// //
// //     // Notification screen
// //     NotificationScreen(),
// //
// //     // Chat screen
// //     ConversationListScreen(),
// //
// //     // About Us screen
// //     AboutUsScreen(),
// //   ];
// //
// //   @override
// //   void initState() {
// //     // TODO: implement initState
// //     super.initState();
// //     _initializeServices();
// //   }
// //
// //   Future<void> _initializeServices() async {
// //     try {
// //       await _chatService.initializeFirebase(); // Initialize Firebase for chat
// //       _fetchNotificationStatus();
// //     } catch (e) {
// //       print('Error initializing services: $e');
// //     }
// //   }
// //
// //   Future<void> _fetchNotificationStatus() async {
// //     try {
// //       bool hasUnread = await _notificationService.hasUnreadNotifications();
// //       setState(() {
// //         _hasUnreadNotifications = hasUnread;
// //       });
// //       print("notifcation $_hasUnreadNotifications");
// //     } catch (e) {
// //       print('Error fetching notification status: $e');
// //     }
// //   }
// //   @override
// //   Widget build(BuildContext context) {
// //     return InternetConnectivityScreen(
// //       child: ServerDownWrapper(
// //         apiService:ApiService() ,
// //         child: Scaffold(
// //
// //           appBar: _currentIndex == 0
// //               ? AppBar(
// //             title: Center(
// //               child: Text(
// //                   'Cum te putem ajuta astăzi?',
// //                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
// //               ),
// //             ),
// //             backgroundColor: Color(0xFF4B5563),
// //           )
// //               : null,
// //           backgroundColor: /*Colors.black*/ Color(0xFFFFFFFF),
// //           body: _screens[_currentIndex],
// //           bottomNavigationBar: _buildBottomNavBar(),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildBottomNavBar() {
// //     return Container(
// //       decoration: BoxDecoration(
// //           borderRadius: BorderRadius.only(
// //               topLeft: Radius.circular(16),
// //               topRight: Radius.circular(16)
// //           ),
// //           boxShadow: [
// //             BoxShadow(
// //                 color: Colors.black12,
// //                 blurRadius: 8,
// //                 offset: Offset(0, -2)
// //             )
// //           ]
// //       ),
// //       child: ClipRRect(
// //         borderRadius: BorderRadius.only(
// //             topLeft: Radius.circular(16),
// //             topRight: Radius.circular(16)
// //         ),
// //         child: BottomNavigationBar(
// //           currentIndex: _currentIndex,
// //           onTap: (index) {
// //             setState(() {
// //               _currentIndex = index;
// //             });
// //           },
// //           backgroundColor: Colors.white ,//Color(0xFF4B5563),
// //           selectedItemColor: Color(0xFF4B5563),
// //           unselectedItemColor: Color(0xFF808080),
// //           selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
// //           unselectedLabelStyle: TextStyle(fontSize: 12),
// //           type: BottomNavigationBarType.fixed,
// //           elevation: 8,
// //           items: [
// //             BottomNavigationBarItem(
// //               icon: Image.asset('assets/home.png', width: 24),
// //               activeIcon: Image.asset('assets/home.png', width: 24),
// //               label: 'Acasă',
// //             ),
// //             BottomNavigationBarItem(
// //               icon: Stack(
// //                 children: [
// //                   Image.asset('assets/bell.png', width: 24),
// //                   if (_hasUnreadNotifications) // Conditionally show red dot
// //                   Positioned(
// //                     right: 0,
// //                     child: Container(
// //                       width: 10,
// //                       height: 10,
// //                       decoration: BoxDecoration(
// //                         color: Colors.red,
// //                         borderRadius: BorderRadius.circular(5),
// //                       ),
// //                     ),
// //                   )
// //                 ],
// //               ),
// //               activeIcon: Stack(
// //                 children: [
// //                   Image.asset('assets/bell.png', width: 24),
// //                   if (_hasUnreadNotifications) // Conditionally show red dot
// //                   Positioned(
// //                     right: 0,
// //                     child: Container(
// //                       width: 10,
// //                       height: 10,
// //                       decoration: BoxDecoration(
// //                         color: Colors.red,
// //                         borderRadius: BorderRadius.circular(5),
// //                       ),
// //                     ),
// //                   )
// //                 ],
// //               ),
// //               label: 'Notificări',
// //             ),
// //             BottomNavigationBarItem(
// //               icon: StreamBuilder<int>(
// //                 stream: _chatService.getTotalUnreadMessagesStream(),
// //                 initialData: 0,
// //                 builder: (context, snapshot) {
// //                   bool hasUnreadMessages = snapshot.hasData && snapshot.data! > 0;
// //                   return Stack(
// //                     children: [
// //                       Image.asset('assets/chat4.png', width: 24),
// //                       if (hasUnreadMessages)
// //                         Positioned(
// //                           right: 0,
// //                           child: Container(
// //                             width: 10,
// //                             height: 10,
// //                             decoration: BoxDecoration(
// //                               color: Colors.green,
// //                               borderRadius: BorderRadius.circular(5),
// //                             ),
// //                           ),
// //                         ),
// //                     ],
// //                   );
// //                 },
// //               ),
// //               activeIcon: StreamBuilder<int>(
// //                 stream: _chatService.getTotalUnreadMessagesStream(),
// //                 initialData: 0,
// //                 builder: (context, snapshot) {
// //                   bool hasUnreadMessages = snapshot.hasData && snapshot.data! > 0;
// //                   return Stack(
// //                     children: [
// //                       Image.asset('assets/chat4.png', width: 24),
// //                       if (hasUnreadMessages)
// //                         Positioned(
// //                           right: 0,
// //                           child: Container(
// //                             width: 10,
// //                             height: 10,
// //                             decoration: BoxDecoration(
// //                               color: Colors.green,
// //                               borderRadius: BorderRadius.circular(5),
// //                             ),
// //                           ),
// //                         ),
// //                     ],
// //                   );
// //                 },
// //               ),
// //               label: 'Mesaje',
// //             ),
// //             BottomNavigationBarItem(
// //               icon: Icon(Icons.settings) , //Image.asset('assets/setting.png', width: 24),
// //               activeIcon:  Icon(Icons.settings_suggest_outlined) , // Image.asset('assets/setting.png', width: 24),
// //               label: 'Despre',
// //             ),
// //             // BottomNavigationBarItem(
// //             //   icon: Stack(
// //             //     children: [
// //             //       Image.asset('assets/chat4.png', width: 24),
// //             //       Positioned(
// //             //         right: 0,
// //             //         child: Container(
// //             //           width: 10,
// //             //           height: 10,
// //             //           decoration: BoxDecoration(
// //             //             color: Colors.green,
// //             //             borderRadius: BorderRadius.circular(5),
// //             //           ),
// //             //         ),
// //             //       )
// //             //     ],
// //             //   ),
// //             //   activeIcon: Stack(
// //             //     children: [
// //             //       Image.asset('assets/chat4.png', width: 24),
// //             //       Positioned(
// //             //         right: 0,
// //             //         child: Container(
// //             //           width: 10,
// //             //           height: 10,
// //             //           decoration: BoxDecoration(
// //             //             color: Colors.green,
// //             //             borderRadius: BorderRadius.circular(5),
// //             //           ),
// //             //         ),
// //             //       )
// //             //     ],
// //             //   ),
// //             //   label: 'Mesaje',
// //             // ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // Extract the home content to a separate widget
// // class _HomeContent extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return GridView.count(
// //       crossAxisCount: 2,
// //       padding: EdgeInsets.all(10),
// //       crossAxisSpacing: 10,
// //       mainAxisSpacing: 10,
// //       children: [
// //         ServiceCard(
// //           imageAsset: 'assets/mechanic.png',
// //           title: 'Mecanic Auto',
// //           subtitle: 'Mecanic Auto',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: MecanicScreen()))),
// //         ),
// //         ServiceCard(
// //           imageAsset: 'assets/peeling.png',
// //           title: 'Autocolant & Folie Auto',
// //           subtitle: 'Servicii de Înfoliere',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: AutocolantScreen()))),
// //         ),
// //         ServiceCard(
// //           imageAsset: 'assets/car-polish.png',
// //           title: 'Detaliing Auto Profesional',
// //           subtitle: 'Detaliere Auto',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: DetailingScreen()))),
// //         ),
// //         ServiceCard(
// //           imageAsset: 'assets/search.png',
// //           title: 'ITP',
// //           subtitle: 'Inspecție Tehnică Periodică',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: ITPScreen()))),
// //         ),
// //         ServiceCard(
// //           imageAsset: 'assets/cleaning.png',
// //           title: 'Tapiterie Auto Profesională',
// //           subtitle: 'Tapiterie Auto',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: TapiterieScreen()))),
// //         ),
// //         ServiceCard(
// //           imageAsset: 'assets/flat-tire.png',
// //           title: 'Vulcanizare Auto Mobilă',
// //           subtitle: 'Servicii de Anvelope',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: VulcanizareScreen()))),
// //         ),
// //         ServiceCard(
// //           imageAsset: 'assets/towing-vehicle.png',
// //           title: 'Tractări Auto cu Platformă',
// //           subtitle: 'Tractări Auto',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: TractariScreen()))),
// //         ),
// //         ServiceCard(
// //           imageAsset: 'assets/upgrade.png',
// //           title: 'Upgrade pentru Mașină',
// //           subtitle: 'Tuning Auto',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: TuningScreen()))),
// //         ),
// //
// //         ServiceCard(
// //           imageAsset: 'assets/logos/1.png',
// //           title: 'Electrica Auto',
// //           subtitle: 'Electrica Auto',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: ElectricaAutoScreen()))),
// //         ),
// //
// //         ServiceCard(
// //           imageAsset: 'assets/logos/1.png',
// //           title: 'Caroserie Si Vopsitorie',
// //           subtitle: 'Caroserie Si Vopsitorie',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: CaroserieSiVopsitorieScreen()))),
// //         ),
// //
// //         ServiceCard(
// //           imageAsset: 'assets/logos/1.png',
// //           title: 'Climatizare Auto',
// //           subtitle: 'Climatizare Auto',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: ClimatizareAutoScreen()))),
// //         ),
// //
// //         ServiceCard(
// //           imageAsset: 'assets/logos/1.png',
// //           title: 'Spalatorie Auto',
// //           subtitle: 'Spalatorie Auto',
// //           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPermissionGate(child: SpalatorieAutoScreen()))),
// //         ),
// //       ],
// //     );
// //   }
// // }
// //
// // class ServiceCard extends StatelessWidget {
// //   final String imageAsset;
// //   final String title;
// //   final String subtitle;
// //   final VoidCallback onTap;
// //   final double imageSize;
// //
// //   ServiceCard({
// //     required this.imageAsset,
// //     required this.title,
// //     required this.subtitle,
// //     required this.onTap,
// //     this.imageSize = 80.0,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Card(
// //         color: Colors.white,
// //         shape: RoundedRectangleBorder(
// //           side: BorderSide(color: Color(0xFFE5E7EB)),
// //           borderRadius: BorderRadius.circular(10),
// //         ),
// //         child: Padding(
// //           padding: EdgeInsets.all(10),
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             crossAxisAlignment: CrossAxisAlignment.center,
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Flexible(
// //                 flex: 3,
// //                 child: Image.asset(
// //                   imageAsset,
// //                   width: imageSize,
// //                   height: imageSize,
// //                   fit: BoxFit.contain,
// //                 ),
// //               ),
// //               SizedBox(height: 8),
// //               Flexible(
// //                 flex: 2,
// //                 child: Text(
// //                   title,
// //                   textAlign: TextAlign.center,
// //                   style: TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 14,
// //                   ),
// //                   maxLines: 2,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               ),
// //               SizedBox(height: 4),
// //               Flexible(
// //                 flex: 1,
// //                 child: Text(
// //                   subtitle,
// //                   textAlign: TextAlign.center,
// //                   style: TextStyle(
// //                     fontSize: 11,
// //                     color: Colors.grey,
// //                   ),
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
