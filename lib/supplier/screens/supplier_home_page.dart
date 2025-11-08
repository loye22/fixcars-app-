import 'dart:async';
import 'dart:developer';

import 'package:fixcars/client/screens/ReviewScreen.dart';
import 'package:fixcars/shared/screens/NotificationScreen.dart';
import 'package:fixcars/client/screens/SupplierProfileScreen.dart';
import 'package:fixcars/shared/screens/Server_down_screen.dart';
import 'package:fixcars/shared/screens/conversation_list_screen.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
import 'package:fixcars/supplier/screens/AddNewServiceScreen.dart';
import 'package:fixcars/supplier/screens/MyServicesScreen.dart';
import 'package:fixcars/supplier/screens/RequestsScreen.dart';
import 'package:fixcars/supplier/screens/waiting_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../shared/screens/aboutUsScreen.dart';
import '../../shared/services/OneSignalService.dart';
import '../../shared/services/PendingCountRequestsService.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/firebase_chat_service.dart';
import '../services/AccountStatusService.dart';
import '../services/MarkNotificationAsReadService.dart';
import '../services/SupplierProfileService.dart';
import '../widgets/NotificationItemWidget.dart';

class supplier_home_page extends StatefulWidget {
  const supplier_home_page({super.key});

  @override
  State<supplier_home_page> createState() => _supplier_home_pageState();
}

class _supplier_home_pageState extends State<supplier_home_page> {
  final SupplierProfileSummaryService _profileService =
  SupplierProfileSummaryService();
  Map<String, dynamic>? _supplierData;
  bool _isLoading = true;
  String _errorMessage = '';
  int _totalUnreadCount = 0;
  StreamSubscription<int>? _unreadSubscription;
  int _pendingRequestCount = 0;
  bool isActive = true;

  // Showcase keys for tutorial
  final GlobalKey _profileImageKey = GlobalKey();
  final GlobalKey _businessHoursKey = GlobalKey();
  final GlobalKey _messagesKey = GlobalKey();
  final GlobalKey _completedKey = GlobalKey();
  final GlobalKey _ratingKey = GlobalKey();
  final GlobalKey _sosAlertKey = GlobalKey();
  final GlobalKey _myServicesKey = GlobalKey();
  final GlobalKey _addServiceKey = GlobalKey();
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _viewAllNotificationsKey = GlobalKey();
  Timer? _pendingCountTimer;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fetchSupplierProfile();
    _startListeningToUnreadMessages();
    _loadPendingRequestCount();
    _startPendingCountPolling();      // ← start polling
    _fetchAccountStatus();
    _initializeShowcase();
  }

  void _startPendingCountPolling() {
    // Load immediately, then every 5 seconds
    _loadPendingRequestCount();

    _pendingCountTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _loadPendingRequestCount(),
    );
  }

  void _initializeShowcase() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final shouldShowTutorial = prefs.getBool('hasSeenTutorial') != true;

      // ALWAYS register ShowcaseView (fixes the hot restart error)
      ShowcaseView.register(
        blurValue: 1,
        autoPlayDelay: const Duration(seconds: 5),
        globalTooltipActionConfig: const TooltipActionConfig(
          position: TooltipActionPosition.inside,
          alignment: MainAxisAlignment.spaceBetween,
          actionGap: 20,
        ),
        globalTooltipActions: [
          TooltipActionButton(
            type: TooltipDefaultActionType.previous,
            textStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
          ),
          TooltipActionButton(
            type: TooltipDefaultActionType.next,
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.blue[700],
          ),
        ],
        onStart: (index, key) {
          log('Tutorial început: $index, $key');
        },
        onComplete: (index, key) {
          log('Tutorial completat: $index, $key');
        },
        onDismiss: (key) {
          log('Tutorial închis la: $key');
        },
      );

      // Only auto-start the tutorial if it's the first time
      if (shouldShowTutorial && mounted) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            ShowcaseView.get().startShowCase([
              _profileImageKey,
              _businessHoursKey,
              _messagesKey,
              _completedKey,
              _ratingKey,
              _sosAlertKey,
              _myServicesKey,
              _addServiceKey,
              _notificationsKey,
              _viewAllNotificationsKey,
            ]);

            // Mark tutorial as seen
            prefs.setBool('hasSeenTutorial', true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _pendingCountTimer?.cancel();
    ShowcaseView.get().unregister();
    super.dispose();
  }

  Future<void> _fetchAccountStatus() async {
    try {
      final AccountStatusService service = AccountStatusService();
      final response = await service.fetchAccountStatus();

      if (response['success'] == true) {
        if (mounted) {  // ← ADD THIS
          setState(() {
            isActive = response['account_status']['is_active'] as bool;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {  // ← AND THIS
          setState(() {
            _errorMessage = 'Nu s-a putut verifica starea contului';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {  // ← AND THIS
        setState(() {
          _errorMessage = 'Eroare la verificarea contului: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Future<void> _fetchAccountStatus() async {
  //   try {
  //     final AccountStatusService service = AccountStatusService();
  //     final response = await service.fetchAccountStatus();
  //
  //     if (response['success'] == true) {
  //       setState(() {
  //         isActive = response['account_status']['is_active'] as bool;
  //         _isLoading = false;
  //       });
  //     } else {
  //       setState(() {
  //         'Nu s-a putut verifica starea contului';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  void _loadPendingRequestCount() async {
    try {
      final pendingCountService = PendingCountService();
      final count = await pendingCountService.fetchPendingCount();
      if (mounted) {
        setState(() {
          _pendingRequestCount = count;
        });
      }
    } catch (e) {
      print('Eroare la încărcarea numărului de cereri: $e');
      if (mounted) {
        setState(() {
          _pendingRequestCount = 0;
        });
      }
    }
  }

  Future<void> _fetchSupplierProfile() async {
    try {
      final data = await _profileService.fetchSupplierProfile();
      setState(() {
        _supplierData = data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Eroare la încărcarea profilului: $e';
        _isLoading = false;
      });
    }
  }

  void _startListeningToUnreadMessages() async {
    final chatService = FirebaseChatService();
    if (!chatService.isAuthenticated()) {
      await chatService.initializeFirebase();
    }

    _unreadSubscription = chatService.getTotalUnreadMessagesStream().listen((count) {
      if (mounted) {
        setState(() {
          _totalUnreadCount = count;
        });
      }
    });
  }

  Widget _buildStat(
      String number,
      String label,
      String assetImagePath,
      Color color,
      VoidCallback onTap, {
        int unreadCount = 0,
      }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF212A39),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  assetImagePath,
                  height: 48,
                  color: color,
                  fit: BoxFit.contain,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -4,
                    left: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: LoadingAnimationWidget.threeArchedCircle(
            color: Colors.black,
            size: 34,
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(child: Text(_errorMessage)),
      );
    }

    final supplier = _supplierData;
    final isOpen = supplier?['isOpen'] ?? false;
    final supplierID = supplier?['supplierId'] ?? "";
    final completedRequests = supplier?['completedRequests']?.toString() ?? '0';
    final averageRating =
        supplier?['reviews']?['averageRating']?.toString() ?? '0';
    final offeredServicesCount =
        supplier?['offeredServicesCount']?.toString() ?? '0';
    final supplierPhotoUrl =
        supplier?['supplierPhotoUrl'] ??
            'https://cdn-icons-png.flaticon.com/512/9203/9203764.png';
    final notifications = supplier?['notifications'] ?? [];
    final String supplierFullName =
        supplier?['supplierFullName'] ?? "404Notfound";
    final businessHours = supplier?['businessHours'] ?? {};

    return InternetConnectivityScreen(
      child: ServerDownWrapper(
        apiService: ApiService(),
        child: isActive == false
            ? WaitingReviewScreen()
            : Scaffold(
          backgroundColor: Colors.grey[100],
          body: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 420,
                      decoration: const BoxDecoration(
                        color: Color(0xFF161E2D),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 60,
                          left: 20,
                          right: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Showcase(
                                  key: _profileImageKey,
                                  title: "Profilul tău",
                                  description: "Aici poți vedea și edita informațiile tale de profil. Apasă pentru a accesa setările complete.",
                                  tooltipBackgroundColor: Colors.white,
                                  titleTextStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  descTextStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  targetShapeBorder: const CircleBorder(),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => AboutUsScreen()),
                                      );
                                    },
                                    child: SizedBox(
                                      height: 100,
                                      width: 100,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        child: CircleAvatar(
                                          radius: 46,
                                          backgroundImage: NetworkImage(supplierPhotoUrl),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Bună, $supplierFullName",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(height: 10),
                                    Showcase(
                                      key: _businessHoursKey,
                                      title: "Program de lucru",
                                      description: "Vezi starea curentă a afacerii tale și programul tău de lucru. Indicatorul roșu arată cereri în așteptare.",
                                      tooltipBackgroundColor: Colors.white,
                                      titleTextStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      descTextStyle: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          _showBusinessHoursDialog(context, businessHours, isOpen);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isOpen ? const Color(0xFF1B4239) : Colors.red,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'assets/check2.png',
                                                width: 18,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                isOpen ? "În serviciu" : "Închis",
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Showcase(
                                      key: _messagesKey,
                                      title: "Mesaje",
                                      description: "Aici vezi conversațiile cu clienții tăi. Bulina roșie indică mesaje necitite care necesită atenția ta.",
                                      tooltipBackgroundColor: Colors.white,
                                      titleTextStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      descTextStyle: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                      child: _buildStat(
                                        unreadCount: _totalUnreadCount,
                                        _totalUnreadCount.toString(),
                                        "Mesaje",
                                        "assets/chat22.png",
                                        Colors.blue,
                                            () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ConversationListScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Showcase(
                                      key: _completedKey,
                                      title: "Servicii Finalizate",
                                      description: "Acesta este numărul total de servicii pe care le-ai finalizat cu succes până acum.",
                                      tooltipBackgroundColor: Colors.white,
                                      titleTextStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      descTextStyle: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                      child: _buildStat(
                                        completedRequests,
                                        "Finalizate",
                                        "assets/check3.png",
                                        Colors.green,
                                            () {
                                          print("Finalizate apăsat!");
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Showcase(
                                      key: _ratingKey,
                                      title: "Evaluare Clienți",
                                      description: "Aici vezi media evaluărilor primite de la clienții tăi. O evaluare bună atrage mai mulți clienți!",
                                      tooltipBackgroundColor: Colors.white,
                                      titleTextStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      descTextStyle: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                      child: _buildStat(
                                        averageRating,
                                        "Evaluare",
                                        "assets/rating4.png",
                                        Colors.orange,
                                            () {
                                          print("Evaluare apăsat!");
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ReviewScreen(
                                                supplierId: supplierID,
                                                hideReviewButton: true,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.40,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Showcase(
                                key: _sosAlertKey,
                                title: "Alertă SOS",
                                description: "Cereri urgente de la clienți. Bulina roșie arată câte cereri noi ai care necesită acțiune imediată.",
                                tooltipBackgroundColor: Colors.white,
                                titleTextStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                descTextStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    print("SOS button tapped!");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RequestsScreen(),
                                      ),
                                    );
                                  },
                                  splashColor: Colors.red.withOpacity(0.3),
                                  highlightColor: Colors.red.withOpacity(0.1),
                                  child: buildQuickAction(
                                    "Alertă SOS",
                                    "assets/ass2.png",
                                    const Color(0xFFFEF2F2),
                                    count: _pendingRequestCount,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Showcase(
                                key: _myServicesKey,
                                title: "Serviciile Mele",
                                description: "Gestionează serviciile oferite, prețurile și disponibilitatea. Aici poți actualiza oferta ta.",
                                tooltipBackgroundColor: Colors.white,
                                titleTextStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                descTextStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    print("Serviciile mele tapped!");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SupplierProfileScreen(
                                          userId: supplierID,
                                        ),
                                      ),
                                    );
                                  },
                                  child: buildQuickAction(
                                    "Serviciile mele",
                                    "assets/ass1.png",
                                    const Color(0xFFEFF6FF),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Showcase(
                                key: _addServiceKey,
                                title: "Adaugă Serviciu",
                                description: "Vrei să oferi un serviciu nou? Contactează echipa noastră pentru a-ți extinde gama de servicii.",
                                tooltipBackgroundColor: Colors.white,
                                titleTextStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                descTextStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    showContactPopup(context);
                                  },
                                  child: buildQuickAction(
                                    "Adaugă serviciu",
                                    "assets/ass3.png",
                                    const Color(0xFFF0FDF4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 150),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Showcase(
                              key: _notificationsKey,
                              title: "Notificări",
                              description: "Aici primești actualizări importante despre serviciile tale, cereri noi și mesaje de la clienți.",
                              tooltipBackgroundColor: Colors.white,
                              titleTextStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              descTextStyle: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                              child: Text(
                                "Notificări",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Showcase(
                              key: _viewAllNotificationsKey,
                              title: "Vezi Toate Notificările",
                              description: "Apasă aici pentru a vedea istoricul complet al notificărilor tale.",
                              tooltipBackgroundColor: Colors.white,
                              titleTextStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              descTextStyle: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NotificationScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Vezi toate",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (notifications.isNotEmpty)
                          ...notifications
                              .map<Widget>(
                                (notification) => NotificationItemWidget(
                              notification: notification,
                              onTap: () {
                                _markNotificationAsRead(
                                  notification["notification_id"],
                                );
                              },
                            ),
                          )
                              .toList()
                        else
                          Text(
                            "Nu există notificări",
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: () {
                  ShowcaseView.get().startShowCase([
                    _profileImageKey,
                    _businessHoursKey,
                    _messagesKey,
                    _completedKey,
                    _ratingKey,
                    _sosAlertKey,
                    _myServicesKey,
                    _addServiceKey,
                    _notificationsKey,
                    _viewAllNotificationsKey,
                  ]);
                },
                child: Icon(Icons.help_outline, color: Colors.white),
                backgroundColor: Colors.blue[700],
                tooltip: 'Arată tutorialul',
                heroTag: "helpButton",
              ),
              SizedBox(height: 10),

            ],
          ),
        ),
      ),
    );
  }

  void _showBusinessHoursDialog(
      BuildContext context,
      Map<String, dynamic> businessHours,
      bool isOpen,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Program de lucru",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildBusinessHoursList(businessHours),
                const SizedBox(height: 16),
                Divider(),
                const SizedBox(height: 8),
                Text(
                  "Pentru a modifica programul de lucru, vă rugăm să contactați echipa noastră de support la support@fixcars.ro",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        "Închide",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildBusinessHoursList(Map<String, dynamic> businessHours) {
    final days = [
      {'key': 'monday', 'label': 'Luni'},
      {'key': 'tuesday', 'label': 'Marți'},
      {'key': 'wednesday', 'label': 'Miercuri'},
      {'key': 'thursday', 'label': 'Joi'},
      {'key': 'friday', 'label': 'Vineri'},
      {'key': 'saturday', 'label': 'Sâmbătă'},
      {'key': 'sunday', 'label': 'Duminică'},
    ];

    return days.map((day) {
      final dayData = businessHours[day['key']];
      final isClosed = dayData['closed'] ?? true;

      String formatTime(String timeString) {
        if (timeString.length >= 5) {
          return timeString.substring(0, 5);
        }
        return timeString;
      }

      final openTime = isClosed ? '' : formatTime(dayData['open'] ?? '');
      final closeTime = isClosed ? '' : formatTime(dayData['close'] ?? '');

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day['label']!,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              isClosed ? 'Închis' : '$openTime - $closeTime',
              style: TextStyle(color: isClosed ? Colors.red : Colors.green),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget buildQuickAction(
      String title,
      String assetImagePath,
      Color containerBg, {
        int count = 0,
      }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(assetImagePath, width: 48, height: 48),
                if (count > 0)
                  Positioned(
                    top: -4,
                    left: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title.replaceAll(" ", "\n"),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markNotificationAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      print('Notificare marcată ca citită');
    } catch (e) {
      print('Eroare: $e');
    }
  }

  void showContactPopup(BuildContext context) {
    final String email = 'support@fixcars.com';
    final String phone = '+40 766 910 195';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.contact_support,
                    size: 32,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Adăugare Servicii Noi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pentru a adăuga servicii noi, vă rugăm să ne contactați:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                _buildContactItem(
                  icon: Icons.email,
                  label: 'Email',
                  value: email,
                  onTap: () => _copyToClipboard(context, email, 'Email'),
                ),
                const SizedBox(height: 16),
                _buildContactItem(
                  icon: Icons.phone,
                  label: 'Telefon',
                  value: phone,
                  onTap: () => _copyToClipboard(context, phone, 'Număr de telefon'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Închide'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.content_copy, size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label a fost copiat în clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// import 'dart:async';
//
// import 'package:fixcars/client/screens/ReviewScreen.dart';
// import 'package:fixcars/shared/screens/NotificationScreen.dart';
// import 'package:fixcars/client/screens/SupplierProfileScreen.dart';
// import 'package:fixcars/shared/screens/Server_down_screen.dart';
// import 'package:fixcars/shared/screens/conversation_list_screen.dart';
// import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
// import 'package:fixcars/supplier/screens/AddNewServiceScreen.dart';
// import 'package:fixcars/supplier/screens/MyServicesScreen.dart';
// import 'package:fixcars/supplier/screens/RequestsScreen.dart';
// import 'package:fixcars/supplier/screens/waiting_review_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import '../../shared/screens/aboutUsScreen.dart';
// import '../../shared/services/OneSignalService.dart';
// import '../../shared/services/PendingCountRequestsService.dart';
// import '../../shared/services/api_service.dart';
// import '../../shared/services/firebase_chat_service.dart';
// import '../services/AccountStatusService.dart';
// import '../services/MarkNotificationAsReadService.dart';
// import '../services/SupplierProfileService.dart';
// import '../widgets/NotificationItemWidget.dart';
//
// class supplier_home_page extends StatefulWidget {
//   const supplier_home_page({super.key});
//
//   @override
//   State<supplier_home_page> createState() => _supplier_home_pageState();
// }
//
// class _supplier_home_pageState extends State<supplier_home_page> {
//   final SupplierProfileSummaryService _profileService =
//       SupplierProfileSummaryService();
//   Map<String, dynamic>? _supplierData;
//   bool _isLoading = true;
//   String _errorMessage = '';
//   int _totalUnreadCount = 0;
//   StreamSubscription<int>? _unreadSubscription;
//   int _pendingRequestCount = 0;
//   bool isActive = true;
//
//   final NotificationService _notificationService = NotificationService();
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchSupplierProfile();
//     _startListeningToUnreadMessages();
//     _loadPendingRequestCount();
//     _fetchAccountStatus();
//   }
//
//   @override
//   void dispose() {
//     _unreadSubscription?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _fetchAccountStatus() async {
//     try {
//       final AccountStatusService service = AccountStatusService();
//       final response = await service.fetchAccountStatus();
//
//       if (response['success'] == true) {
//         setState(() {
//           isActive = response['account_status']['is_active'] as bool;
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           'Failed to fetch account status';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _loadPendingRequestCount() async {
//     try {
//       final pendingCountService = PendingCountService();
//       final count = await pendingCountService.fetchPendingCount();
//       if (mounted) {
//         setState(() {
//           _pendingRequestCount = count;
//         });
//         // print("_pendingRequestCount $_pendingRequestCount");
//       }
//     } catch (e) {
//       print('Error loading pending request count: $e');
//       // You can set a default value or show an error indicator
//       if (mounted) {
//         setState(() {
//           _pendingRequestCount = 0; // Or -1 to indicate error
//         });
//       }
//     }
//   }
//
//   Future<void> _fetchSupplierProfile() async {
//     try {
//       final data = await _profileService.fetchSupplierProfile();
//       setState(() {
//         _supplierData = data['data'];
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Eroare la încărcarea profilului: $e';
//         _isLoading = false;
//       });
//     }
//   }
//
//   // Add this method to your FirebaseChatService class
//   void _startListeningToUnreadMessages() async {
//     // Initialize Firebase if needed
//     final chatService = FirebaseChatService();
//     if (!chatService.isAuthenticated()) {
//       await chatService.initializeFirebase();
//     }
//
//     // Listen for real-time updates
//     _unreadSubscription = chatService.getTotalUnreadMessagesStream().listen((
//       count,
//     ) {
//       if (mounted) {
//         setState(() {
//           _totalUnreadCount = count;
//         });
//       }
//     });
//   }
//
//   Widget _buildStat(
//     String number,
//     String label,
//     String assetImagePath,
//     Color color,
//     VoidCallback onTap, {
//     int unreadCount = 0, // Add this parameter for unread count
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: const Color(0xFF212A39),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Stack for image with badge
//             Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 // Your image
//                 Image.asset(
//                   assetImagePath,
//                   height: 48,
//                   color: color,
//                   fit: BoxFit.contain,
//                 ),
//                 // Red bubble badge positioned at top left of image
//                 if (unreadCount > 0)
//                   Positioned(
//                     top: -4, // Adjust to position relative to image
//                     left: -4, // Adjust to position relative to image
//                     child: Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: const BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                       constraints: const BoxConstraints(
//                         minWidth: 16,
//                         minHeight: 16,
//                       ),
//                       child: Text(
//                         unreadCount > 99 ? '99+' : unreadCount.toString(),
//                         style: const TextStyle(
//                           color: Colors.red,
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             Text(
//               number,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               label,
//               style: const TextStyle(color: Colors.white70, fontSize: 12),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: Colors.grey[100],
//         body: Center(
//           child: LoadingAnimationWidget.threeArchedCircle(
//             color: Colors.black,
//             size: 34,
//           ),
//         ),
//       );
//     }
//
//     if (_errorMessage.isNotEmpty) {
//       return Scaffold(
//         backgroundColor: Colors.grey[100],
//         body: Center(child: Text(_errorMessage)),
//       );
//     }
//
//     final supplier = _supplierData;
//     final isOpen = supplier?['isOpen'] ?? false;
//     final supplierID = supplier?['supplierId'] ?? "";
//     final completedRequests = supplier?['completedRequests']?.toString() ?? '0';
//     final averageRating =
//         supplier?['reviews']?['averageRating']?.toString() ?? '0';
//     final offeredServicesCount =
//         supplier?['offeredServicesCount']?.toString() ?? '0';
//     final supplierPhotoUrl =
//         supplier?['supplierPhotoUrl'] ??
//         'https://cdn-icons-png.flaticon.com/512/9203/9203764.png';
//     final notifications = supplier?['notifications'] ?? [];
//     final String supplierFullName =
//         supplier?['supplierFullName'] ?? "404Notfound";
//     final businessHours = supplier?['businessHours'] ?? {};
//
//     return InternetConnectivityScreen(
//       child: ServerDownWrapper(
//         apiService: ApiService(),
//         child:
//             isActive == false
//                 ? WaitingReviewScreen()
//
//                 : Scaffold(
//                   backgroundColor: Colors.grey[100],
//                   body: SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         Stack(
//                           clipBehavior: Clip.none,
//                           children: [
//                             // Dark Header Background
//                             Container(
//                               height: 420,
//                               // Increased height to accommodate quick actions card
//                               decoration: const BoxDecoration(
//                                 color: Color(0xFF161E2D),
//                                 borderRadius: BorderRadius.only(
//                                   bottomLeft: Radius.circular(24),
//                                   bottomRight: Radius.circular(24),
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.only(
//                                   top: 60,
//                                   left: 20,
//                                   right: 20,
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//
//
//
//                                     Row(
//                                       children: [
//                                         GestureDetector(
//                                           onTap: () {
//                                             Navigator.push(
//                                               context,
//                                               MaterialPageRoute(builder: (context) => AboutUsScreen()),
//                                             );
//                                           },
//                                           child: SizedBox(
//                                             height: 100,
//                                             width: 100,
//                                             child: Container(
//                                               padding: const EdgeInsets.all(4), // border thickness
//
//                                               child: CircleAvatar(
//                                                 radius: 46, // slightly smaller to fit inside the border
//                                                 backgroundImage: NetworkImage(supplierPhotoUrl),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 12),
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 "Bună, $supplierFullName",
//                                                 style: const TextStyle(
//                                                   color: Colors.white,
//                                                   fontSize: 18,
//                                                   fontWeight: FontWeight.bold,
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 6),
//                                             ],
//                                           ),
//                                         ),
//                                         const SizedBox(width: 12),
//                                         Column(
//                                           crossAxisAlignment: CrossAxisAlignment.end,
//                                           children: [
//                                             const SizedBox(height: 10),
//                                             GestureDetector(
//                                               onTap: () {
//                                                 _showBusinessHoursDialog(context, businessHours, isOpen);
//                                               },
//                                               child: Container(
//                                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                                 decoration: BoxDecoration(
//                                                   color: isOpen ? const Color(0xFF1B4239) : Colors.red,
//                                                   borderRadius: BorderRadius.circular(20),
//                                                 ),
//                                                 child: Row(
//                                                   mainAxisSize: MainAxisSize.min,
//                                                   children: [
//                                                     Image.asset(
//                                                       'assets/check2.png',
//                                                       width: 18,
//                                                     ),
//                                                     const SizedBox(width: 10),
//                                                     Text(
//                                                       isOpen ? "În serviciu" : "Închis",
//                                                       style: const TextStyle(color: Colors.white),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//
//
//
//
//
//
//
//
//
//                                     SizedBox(height: 30),
//
//                                     Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceEvenly,
//                                       // Changed to spaceEvenly for better spacing
//                                       children: [
//                                         Expanded(
//                                           child: Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 4.0,
//                                             ), // Add spacing
//                                             child: _buildStat(
//                                               unreadCount: _totalUnreadCount ,
//                                               _totalUnreadCount.toString(),
//                                               "Mesaje",
//                                               "assets/chat22.png",
//                                               Colors.blue,
//                                               () {
//                                                 ///here
//                                                 Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder:
//                                                         (context) =>
//                                                             ConversationListScreen(),
//                                                   ),
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                         ),
//                                         Expanded(
//                                           child: Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 4.0,
//                                             ),
//                                             child: _buildStat(
//                                               completedRequests,
//                                               "Finalizate",
//                                               "assets/check3.png",
//                                               Colors.green,
//                                               () {
//                                                 print("Finalizate apăsat!");
//                                               },
//                                             ),
//                                           ),
//                                         ),
//                                         Expanded(
//                                           child: Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 4.0,
//                                             ),
//                                             child: _buildStat(
//                                               averageRating,
//                                               "Evaluare",
//                                               "assets/rating4.png",
//                                               Colors.orange,
//                                               () {
//                                                 print("Evaluare apăsat!");
//                                                 Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder:
//                                                         (context) =>
//                                                             ReviewScreen(
//                                                               supplierId:
//                                                                   supplierID,
//                                                               hideReviewButton:
//                                                                   true,
//                                                             ),
//                                                   ),
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             // Quick Actions Card
//                             Positioned(
//                               top: MediaQuery.of(context).size.height * 0.40,
//                               // Adjusted for better visibility
//                               // top: MediaQuery.of(context).size.height * 0.45, // Adjusted for better visibility
//                               left: 20,
//                               right: 20,
//                               child: Container(
//                                 padding: const EdgeInsets.all(20),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(16),
//                                   boxShadow: const [
//                                     BoxShadow(
//                                       color: Colors.black12,
//                                       blurRadius: 10,
//                                       spreadRadius: 2,
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Expanded(
//                                       child: InkWell(
//                                         onTap: () {
//                                           print("SOS button tapped!");
//                                           Navigator.push(
//                                             context,
//                                             MaterialPageRoute(
//                                               builder:
//                                                   (context) => RequestsScreen(),
//                                             ),
//                                           );
//                                         },
//                                         splashColor: Colors.red.withOpacity(
//                                           0.3,
//                                         ),
//                                         highlightColor: Colors.red.withOpacity(
//                                           0.1,
//                                         ),
//                                         child: buildQuickAction(
//                                           "Alertă SOS",
//                                           "assets/ass2.png",
//                                           const Color(0xFFFEF2F2),
//                                           count: _pendingRequestCount,
//                                         ),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: InkWell(
//                                         onTap: () {
//                                           print("Serviciile mele tapped!");
//                                           // Add navigation or action for "Serviciile mele"
//                                           Navigator.push(
//                                             context,
//                                             MaterialPageRoute(
//                                               builder:
//                                                   (context) =>
//                                                       SupplierProfileScreen(
//                                                         userId: supplierID,
//                                                       ),
//                                             ),
//                                           );
//                                         },
//                                         child: buildQuickAction(
//                                           "Serviciile mele",
//                                           "assets/ass1.png",
//                                           const Color(0xFFEFF6FF),
//                                         ),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: InkWell(
//                                         onTap: () {
//                                           showContactPopup(context);
//                                         },
//                                         child: buildQuickAction(
//                                           "Adaugă serviciu",
//                                           "assets/ass3.png",
//                                           const Color(0xFFF0FDF4),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         SizedBox(height: 150),
//
//                         Padding(
//                           padding: const EdgeInsets.all(18.0),
//                           child: Container(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       "Notificări",
//                                       style: TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     InkWell(
//                                       onTap: () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder:
//                                                 (context) =>
//                                                     NotificationScreen(),
//                                           ),
//                                         );
//                                       },
//                                       child: Text(
//                                         "Vezi toate",
//                                         style: TextStyle(
//                                           color: Colors.blue,
//                                           fontSize: 14,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 16),
//                                 // Display notifications from API
//                                 if (notifications.isNotEmpty)
//                                   ...notifications
//                                       .map<Widget>(
//                                         (
//                                           notification,
//                                         ) => NotificationItemWidget(
//                                           notification: notification,
//                                           onTap: () {
//                                             _markNotificationAsRead(
//                                               notification["notification_id"],
//                                             );
//                                           },
//                                         ),
//                                       )
//                                       .toList()
//                                 else
//                                   Text(
//                                     "Nu există notificări",
//                                     style: TextStyle(color: Colors.grey),
//                                   ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//       ),
//     );
//   }
//
//   void _showBusinessHoursDialog(
//     BuildContext context,
//     Map<String, dynamic> businessHours,
//     bool isOpen,
//   ) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16.0),
//           ),
//           elevation: 0,
//           backgroundColor: Colors.transparent,
//           child: Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Program de lucru",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ..._buildBusinessHoursList(businessHours),
//                 const SizedBox(height: 16),
//                 Divider(),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Pentru a modifica programul de lucru, vă rugăm să contactați echipa noastră de support la support@fixcars.ro",
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       gradient: LinearGradient(
//                         colors: [Colors.blue.shade700, Colors.blue.shade500],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.blue.withOpacity(0.3),
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: TextButton(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                       },
//                       style: TextButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 10,
//                         ),
//                       ),
//                       child: Text(
//                         "Închide",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   List<Widget> _buildBusinessHoursList(Map<String, dynamic> businessHours) {
//     final days = [
//       {'key': 'monday', 'label': 'Luni'},
//       {'key': 'tuesday', 'label': 'Marți'},
//       {'key': 'wednesday', 'label': 'Miercuri'},
//       {'key': 'thursday', 'label': 'Joi'},
//       {'key': 'friday', 'label': 'Vineri'},
//       {'key': 'saturday', 'label': 'Sâmbătă'},
//       {'key': 'sunday', 'label': 'Duminică'},
//     ];
//
//     return days.map((day) {
//       final dayData = businessHours[day['key']];
//       final isClosed = dayData['closed'] ?? true;
//
//       // Format time from "19:00:00" to "19:00"
//       String formatTime(String timeString) {
//         if (timeString.length >= 5) {
//           return timeString.substring(0, 5);
//         }
//         return timeString;
//       }
//
//       final openTime = isClosed ? '' : formatTime(dayData['open'] ?? '');
//       final closeTime = isClosed ? '' : formatTime(dayData['close'] ?? '');
//
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               day['label']!,
//               style: TextStyle(
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[700],
//               ),
//             ),
//             Text(
//               isClosed ? 'Închis' : '$openTime - $closeTime',
//               style: TextStyle(color: isClosed ? Colors.red : Colors.green),
//             ),
//           ],
//         ),
//       );
//     }).toList();
//   }
//
//   // Quick Action Widget with container background + rounded border
//   Widget buildQuickAction(
//     String title,
//     String assetImagePath,
//     Color containerBg, {
//     int count = 0, // Add optional count parameter
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 4.0),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
//         decoration: BoxDecoration(
//           color: containerBg,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Stack for image with red bubble
//             Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 // Image
//                 Image.asset(assetImagePath, width: 48, height: 48),
//                 // Red bubble badge at top left of image
//                 if (count > 0)
//                   Positioned(
//                     top: -4, // Position above the image slightly
//                     left: -4, // Position left of the image slightly
//                     child: Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: const BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                       constraints: const BoxConstraints(
//                         minWidth: 20,
//                         minHeight: 20,
//                       ),
//                       child: Text(
//                         count > 99 ? '99+' : count.toString(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               title.replaceAll(" ", "\n"),
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Widget buildQuickAction(
//   //   String title,
//   //   String assetImagePath,
//   //   Color containerBg,
//   //
//   // )
//   // {
//   //   return Padding(
//   //     padding: const EdgeInsets.only(left: 4.0),
//   //     child: Container(
//   //       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
//   //       decoration: BoxDecoration(
//   //         color: containerBg,
//   //         borderRadius: BorderRadius.circular(16),
//   //       ),
//   //       child: Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children: [
//   //           Image.asset(assetImagePath, width: 48, height: 48),
//   //           const SizedBox(height: 8),
//   //           Text(
//   //             title.replaceAll(" ", "\n"),
//   //             textAlign: TextAlign.center,
//   //             style: const TextStyle(
//   //               fontSize: 14,
//   //               fontWeight: FontWeight.w500,
//   //               color: Colors.black87,
//   //             ),
//   //           ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }
//
//   void _markNotificationAsRead(String notificationId) async {
//     try {
//       await _notificationService.markNotificationAsRead(notificationId);
//       print('Notification marked as read successfully');
//       // Optionally update UI or show a success message
//     } catch (e) {
//       print('Error: $e');
//       // Optionally show an error message to the user
//     }
//   }
//
//   void showContactPopup(BuildContext context) {
//     final String email = 'support@fixcars.com';
//     final String phone = '+40 766 910 195';
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16.0),
//           ),
//           elevation: 0,
//           backgroundColor: Colors.transparent,
//           child: Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // Icon
//                 Container(
//                   width: 64,
//                   height: 64,
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.contact_support,
//                     size: 32,
//                     color: Colors.blue.shade700,
//                   ),
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 // Title
//                 const Text(
//                   'Adăugare Servicii Noi',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//
//                 const SizedBox(height: 8),
//
//                 // Description
//                 const Text(
//                   'Pentru a adăuga servicii noi, vă rugăm să ne contactați:',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 16, color: Colors.black54),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 // Email section
//                 _buildContactItem(
//                   icon: Icons.email,
//                   label: 'Email',
//                   value: email,
//                   onTap: () => _copyToClipboard(context, email, 'Email'),
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 // Phone section
//                 _buildContactItem(
//                   icon: Icons.phone,
//                   label: 'Telefon',
//                   value: phone,
//                   onTap:
//                       () =>
//                           _copyToClipboard(context, phone, 'Număr de telefon'),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 // Close button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue.shade700,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text('Închide'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildContactItem({
//     required IconData icon,
//     required String label,
//     required String value,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade50,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade200),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade100,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, size: 20, color: Colors.blue.shade700),
//             ),
//
//             const SizedBox(width: 16),
//
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     label,
//                     style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     value,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(width: 8),
//
//             Icon(Icons.content_copy, size: 18, color: Colors.grey.shade500),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _copyToClipboard(BuildContext context, String text, String label) async {
//     await Clipboard.setData(ClipboardData(text: text));
//
//     // Show a confirmation
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('$label a fost copiat în clipboard'),
//         duration: const Duration(seconds: 2),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
// }
