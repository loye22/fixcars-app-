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
  int _currentIndex = 2;
  bool _hasUnreadNotifications = false;
  final NotificationService _notificationService = NotificationService();
  final FirebaseChatService _chatService = FirebaseChatService();

// LISTA DE ECRANE ACTUALIZATĂ (Reordonată)
  final List<Widget> _screens = [
    CarLoadingDecisionScreen(), // Index 0: Mașina mea (Left)
    NotificationScreen(),       // Index 1: Notificări
    _HomeContent(),             // Index 2: Acasă (Middle)
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
      // Safety check after await
      if (!mounted) return;
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
          // Index 0: Mașina mea (Moved to Left)
          _navItemWithDot(
            outline: CupertinoIcons.car_detailed,
            filled: CupertinoIcons.car_detailed,
            label: 'Mașina mea',
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

          // Index 2: Acasă (Moved to Middle)
          _navItemWithDot(
            outline: CupertinoIcons.house,
            filled: CupertinoIcons.house_fill,
            label: 'Acasă',
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
    {'title': 'PLATFORMĂ ȘI TRACTĂRI AUTO', 'screen': () => LocationPermissionGate(child: TractariScreen())},
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
                    width: 60,
                    height: 60,
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
                  // Text(
                  //   'GARAJUL TĂU DIGITAL',
                  //   style: GoogleFonts.inter(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w600,
                  //     color: _secondaryText,
                  //     letterSpacing: 2,
                  //   ),
                  // ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Iconița în stil iOS
            // Icon(
            //   icon,
            //   size: 38,
            //   color: _accentSilver,
            // ),
           // const SizedBox(height: 10),
            // Titlul serviciului
            Center(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Indicator vizual
            // Container(
            //   margin: const EdgeInsets.only(top: 8),
            //   width: 100,
            //   height: 2,
            //   color: _accentSilver.withOpacity(0.4),
            // ),
          ],
        ),
      ),
    );
  }
}

