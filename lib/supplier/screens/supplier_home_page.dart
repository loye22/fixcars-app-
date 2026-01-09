import 'dart:async';
import 'dart:convert';
import 'package:fixcars/client/screens/ReviewScreen.dart';
import 'package:fixcars/shared/screens/BusinessLocationPermissionGate.dart';
import 'package:fixcars/shared/screens/NotificationScreen.dart';
import 'package:fixcars/client/screens/SupplierProfileScreen.dart';
import 'package:fixcars/shared/screens/Server_down_screen.dart';
import 'package:fixcars/shared/screens/conversation_list_screen.dart';
import 'package:fixcars/shared/screens/internet_connectivity_screen.dart';
import 'package:fixcars/supplier/screens/AddNewServiceScreen.dart';
import 'package:fixcars/supplier/screens/RequestsScreen.dart';
import 'package:fixcars/supplier/screens/waiting_review_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../client/widgets/BusinessCardWidget.dart';
import '../../shared/screens/aboutUsScreen.dart';
import '../../shared/services/PendingCountRequestsService.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/firebase_chat_service.dart';
import '../../shared/services/phone_service.dart';
import '../services/AccountStatusService.dart';
import '../services/BusinessHourService.dart';
import '../services/MarkNotificationAsReadService.dart';
import '../services/SupplierProfileService.dart';
import '../widgets/NotificationItemWidget.dart';
import '../widgets/ProfileEditBottomSheet.dart';

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
  Timer? _pendingCountTimer;
  final NotificationService _notificationService = NotificationService();

  Color _goldAccent = Color(0xFFFFD700);
  Color _surfaceGray = Color(0xFF2C2C2C);
  Color _borderGray = Color(0xFF424242);
  Color _secondaryText = Colors.grey;

  @override
  void initState() {
    super.initState();
    _fetchSupplierProfile();
    _startListeningToUnreadMessages();
    _loadPendingRequestCount();
    _startPendingCountPolling(); // ← start polling
    _fetchAccountStatus();
  }

  // Helper to map String from API to Enum
  SupplierTier get tier {
    final plan = _supplierData?['subscriptionPlan']?.toString().toLowerCase();
    if (plan == 'gold') return SupplierTier.gold;
    if (plan == 'bronze') return SupplierTier.bronze;
    return SupplierTier.silver; // Default/Silver
  }

  Widget _buildTierBadge(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTierBottomSheet(context),
      child: _getBadgeUI(),
    );
  }

  void _showTierBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            // Matching your page's secondary dark color
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (_, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    child: Column(
                      children: [
                        // --- Drag Handle ---
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Beneficii Abonament",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- Tier Sections ---
                        _buildTierInfo(
                          "Bronze Tier",
                          "Apareți în căutări, dar marcați ca neverificați. Recomandăm upgrade-ul pentru a debloca încrederea utilizatorilor.",
                          "assets/b.png",
                          _secondaryText,
                        ),
                        const Divider(color: Colors.white10, height: 40),
                        _buildTierInfo(
                          "Silver Tier",
                          "Afacerea este marcată ca VERIFICATĂ. Acest statut poate crește numărul de clienți cu până la 40%.",
                          "assets/s.png",
                          Colors.blueAccent,
                        ),
                        const Divider(color: Colors.white10, height: 40),
                        _buildTierInfo(
                          "Golden Tier",
                          "Include tot din Silver plus recomandări prioritare. Utilizatorii care au nevoie de servicii imediate (ex: schimb de ulei) vă vor vedea primii.",
                          "assets/g.png",
                          _goldAccent,
                        ),
                        const SizedBox(height: 32),
                        // --- Contact Section ---
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Dorești un upgrade?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Contactează-ne pentru a discuta despre cel mai bun plan pentru tine:",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildContactRow(
                                Icons.email,
                                "support@fixcars.ro",
                              ),
                              const SizedBox(height: 12),
                              _buildContactRow(Icons.phone, "0767333804"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- Close Button ---
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.08),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Închide",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  // Helper widget for each tier's description and image
  Widget _buildTierInfo(
    String title,
    String description,
    String imagePath,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 16),

        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.white10,
                  child: const Center(
                    child: Text(
                      "Previzualizare indisponibilă",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String label) {
    return InkWell(
      onTap: () {
        if (icon == Icons.phone) {
          // Trigger the call service
          CallService.makeCall(context: context, phoneNumber: label);
        } else if (icon == Icons.email) {
          // Optional: Add email logic here later
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the content
          children: [
            Icon(icon, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // // Helper widget for contact rows
  // Widget _buildContactRow(IconData icon, String text) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Icon(icon, size: 18, color: Colors.cyan),
  //       const SizedBox(width: 8),
  //       Text(
  //         text,
  //         style: const TextStyle(
  //           color: Colors.white,
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _getBadgeUI() {
    switch (tier) {
      case SupplierTier.gold:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _goldAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _goldAccent.withOpacity(0.4), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, color: _goldAccent, size: 12),
              SizedBox(width: 4),
              Text(
                'ALEGERE GOLD',
                style: TextStyle(
                  color: _goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case SupplierTier.bronze:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _surfaceGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderGray, width: 0.5),
          ),
          child: Text(
            'NEVERIFICAT',
            style: TextStyle(
              color: _secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      default: // Silver / Verificat
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blueAccent.withOpacity(0.4),
              width: 0.5,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, color: Colors.blueAccent, size: 12),
              SizedBox(width: 4),
              Text(
                'VERIFICAT',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  void _startPendingCountPolling() {
    // Load immediately, then every 5 seconds
    _loadPendingRequestCount();

    _pendingCountTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadPendingRequestCount(),
    );
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _pendingCountTimer?.cancel();
    // ShowcaseView.get().unregister();
    super.dispose();
  }

  Future<void> _fetchAccountStatus() async {
    try {
      final AccountStatusService service = AccountStatusService();
      final response = await service.fetchAccountStatus();

      if (response['success'] == true) {
        if (mounted) {
          // ← ADD THIS
          setState(() {
            isActive = response['account_status']['is_active'] as bool;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          // ← AND THIS
          setState(() {
            _errorMessage = 'Nu s-a putut verifica starea contului';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // ← AND THIS
        setState(() {
          _errorMessage = 'Eroare la verificarea contului: $e';
          _isLoading = false;
        });
      }
    }
  }

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
      if (mounted) {
        // Added safety check
        setState(() {
          _supplierData = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Added safety check
        setState(() {
          _errorMessage = 'Eroare la încărcarea profilului: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startListeningToUnreadMessages() async {
    final chatService = FirebaseChatService();
    if (!chatService.isAuthenticated()) {
      await chatService.initializeFirebase();
    }

    _unreadSubscription = chatService.getTotalUnreadMessagesStream().listen((
      count,
    ) {
      // Check if the widget is still in the tree before calling setState
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
          color: const Color(0xFF202020),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: Colors.grey.shade800, width: 0.5),
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
                  color: Colors.grey.shade400,
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
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: LoadingAnimationWidget.threeArchedCircle(
            color: Colors.orange,
            size: 34,
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
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
        child:
            isActive == false
                ? WaitingReviewScreen()
                : Scaffold(
                  backgroundColor: const Color(0xFF121212),
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: 420,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey.shade800,
                                  width: 0.5,
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
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        AboutUsScreen(),
                                              ),
                                            );
                                          },
                                          child: SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              child: CircleAvatar(
                                                radius: 46,
                                                backgroundImage: NetworkImage(
                                                  supplierPhotoUrl,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                              _buildTierBadge(context),
                                              // <--- ADDED THE BADGE HERE
                                              const SizedBox(height: 6),

                                              _buildEditProfileButton(context), // The new edit widget
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const SizedBox(height: 10),
                                            GestureDetector(
                                              onTap: () {
                                                // print(businessHours);
                                                // print("businessHours=======================================");

                                                _showBusinessHoursDialog(
                                                  context,
                                                  businessHours,
                                                  isOpen,
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isOpen
                                                          ? Colors
                                                              .green
                                                              .shade700
                                                              .withOpacity(0.2)
                                                          : Colors.red.shade700
                                                              .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color:
                                                        isOpen
                                                            ? Colors
                                                                .green
                                                                .shade700
                                                            : Colors
                                                                .red
                                                                .shade700,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      isOpen
                                                          ? "În serviciu"
                                                          : "Închis",
                                                      style: TextStyle(
                                                        color:
                                                            isOpen
                                                                ? Colors
                                                                    .green
                                                                    .shade300
                                                                : Colors
                                                                    .red
                                                                    .shade300,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 30),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0,
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
                                                    builder:
                                                        (context) =>
                                                            ConversationListScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0,
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
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0,
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
                                                    builder:
                                                        (context) =>
                                                            ReviewScreen(
                                                              supplierId:
                                                                  supplierID,
                                                              hideReviewButton:
                                                                  true,
                                                            ),
                                                  ),
                                                );
                                              },
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
                                  color: const Color(0xFF2C2C2C),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.grey.shade800,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // --- Alertă SOS Button (Step 6) ---
                                    Expanded(
                                      child: buildQuickAction(
                                        "Alertă SOS",
                                        "assets/ass2.png",
                                        Colors.red.shade700.withOpacity(0.2),
                                        count: _pendingRequestCount,
                                        onTap: () {
                                          print("SOS button tapped!");
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => RequestsScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    // --- Serviciile mele Button (Step 7) ---
                                    Expanded(
                                      child: buildQuickAction(
                                        "Serviciile mele",
                                        "assets/ass1.png",
                                        Colors.blue.shade700.withOpacity(0.2),
                                        onTap: () {
                                          print("Serviciile mele tapped!");
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      SupplierProfileScreen(
                                                        userId: supplierID,
                                                      ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    // --- Adaugă serviciu Button (Step 8) ---
                                    Expanded(
                                      child: buildQuickAction(
                                        "Adaugă serviciu",
                                        "assets/ass3.png",
                                        Colors.green.shade700.withOpacity(0.2),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (
                                                    context,
                                                  ) => BusinessLocationPermissionGate(
                                                    child:
                                                        AddNewServiceScreen(),
                                                  ),
                                            ),
                                          );
                                        },
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
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade800,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Notificări",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    NotificationScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Vezi toate",
                                        style: TextStyle(
                                          color: Colors.cyan,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (notifications.isNotEmpty)
                                  ...notifications
                                      .map<Widget>(
                                        (
                                          notification,
                                        ) => NotificationItemWidget(
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
                                  const Text(
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
                ),
      ),
    );
  }


  Widget _buildEditProfileButton(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          // 1. Open the sheet and wait for it to close
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const PremiumProfileEditSheet(),
          );

          // 2. Fetch data regardless of how the sheet was closed
          // (Save button, Swipe down, or Cancel)
          if (mounted) {
            _fetchSupplierProfile();
          }
        },
      // onTap: () => showModalBottomSheet(
      //   context: context,
      //   isScrollControlled: true,
      //   backgroundColor: Colors.transparent,
      //   builder: (context) => const PremiumProfileEditSheet(),
      // ),
      child:
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Keeps container tight around content
          children: [
            Icon(
              Icons.edit_outlined,
              size: 12,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 6),
            // Use Flexible so the text can shrink if the Row runs out of space
            Flexible(
              child: Text(
                "EDITEAZĂ PROFILUL",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[300],
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis, // Adds "..." if text is too long
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
      )
      // Container(
      //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      //   decoration: BoxDecoration(
      //     color: Colors.white.withOpacity(0.04),
      //     borderRadius: BorderRadius.circular(8),
      //     border: Border.all(color: Colors.white24, width: 0.6),
      //   ),
      //   child: Row(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Icon(
      //         Icons.edit_outlined,
      //         size: 12,
      //         color: Colors.grey[300],
      //       ),
      //       const SizedBox(width: 6),
      //       Text(
      //         "EDITEAZĂ PROFILUL",
      //         style: TextStyle(
      //           fontSize: 10,
      //           fontWeight: FontWeight.w700,
      //           color: Colors.grey[300],
      //           letterSpacing: 0.8,
      //         ),
      //       ),
      //     ],
      //   ),
      // )
    );
  }
  /// Elegant implementation of the business hours list
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

    String formatTime(String timeString) {
      if (timeString.length >= 5) {
        return timeString.substring(0, 5);
      }
      return timeString;
    }

    return days.map((day) {
      final dayData = businessHours[day['key']];
      final isClosed = dayData?['closed'] ?? true;

      final openTime = isClosed ? '' : formatTime(dayData?['open'] ?? '');
      final closeTime = isClosed ? '' : formatTime(dayData?['close'] ?? '');

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day['label']!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.grey.shade300,
              ),
            ),
            Text(
              isClosed ? 'Închis' : '$openTime - $closeTime',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isClosed ? FontWeight.w700 : FontWeight.w600,
                color: isClosed ? Color(0xFFE53935) : Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showBusinessHoursDialog(
    BuildContext context,
    Map<String, dynamic> businessHours,
    bool isOpen,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Allows sheet to height-adjust based on content
      backgroundColor: Colors.transparent,
      // Required to show custom container shape
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Slightly deeper dark for elegance
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- DRAG HANDLE ---
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Colors.grey,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Program de Lucru",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          // Mini Status Indicator in the header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isOpen
                                      ? const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.15)
                                      : const Color(
                                        0xFFE53935,
                                      ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOpen ? "DESCHIS" : "ÎNCHIS",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color:
                                    isOpen
                                        ? const Color(0xFF81C784)
                                        : const Color(0xFFE57373),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- BUSINESS HOURS LIST ---
                      // Note: Ensure _buildBusinessHoursList is optimized for dark theme
                      ..._buildBusinessHoursList(businessHours),

                      const SizedBox(height: 24),

                      const SizedBox(height: 24),

                      // --- CLOSE BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Închide",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Inside _showBusinessHoursDialog
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close info sheet
                            _showEditBusinessHoursSheet(context, businessHours); // Open edit sheet
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0, // Removes shadow for a flatter, modern look
                            backgroundColor: Colors.white.withOpacity(0.05), // Dark gray/translucent look
                            foregroundColor: Colors.white70, // Subtle white text
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withOpacity(0.15)) // Subtle gray border
                            ),
                          ),
                          child: const Text(
                            "Editează Program",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                      ),
                      // SizedBox(
                      //   width: double.infinity,
                      //   height: 54,
                      //   child: ElevatedButton(
                      //     onPressed: () {
                      //       Navigator.pop(context); // Close info sheet
                      //       _showEditBusinessHoursSheet(
                      //         context,
                      //         businessHours,
                      //       ); // Open edit sheet
                      //     },
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      //       foregroundColor: Colors.blueAccent,
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(16),
                      //         side: BorderSide(
                      //           color: Colors.blueAccent.withOpacity(0.3),
                      //         ),
                      //       ),
                      //     ),
                      //     child: const Text("Editează Program"),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditBusinessHoursSheet(
      BuildContext context,
      Map<String, dynamic> initialHours,
      ) {
    // Create a deep copy to avoid modifying the original list until "Save" is pressed
    Map<String, dynamic> editedHours = jsonDecode(jsonEncode(initialHours));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    "Editează Program",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 30),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: editedHours.keys.map((day) {
                        bool isClosed = editedHours[day]['closed'] ?? false;

                        // Translate the day to Romanian and capitalize it
                        String romanianDay = _translateDay(day);
                        String displayDay = romanianDay.isNotEmpty
                            ? romanianDay[0].toUpperCase() + romanianDay.substring(1)
                            : day;

                        return ListTile(
                          title: Text(
                            displayDay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            isClosed
                                ? "Închis"
                                : "${editedHours[day]['open']} - ${editedHours[day]['close']}",
                            style: TextStyle(
                              color: isClosed ? Colors.redAccent : Colors.grey[400],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: !isClosed,
                                onChanged: (val) => setModalState(
                                      () => editedHours[day]['closed'] = !val,
                                ),
                                activeColor: Colors.greenAccent,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.access_time_filled_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: isClosed
                                    ? null
                                    : () => _showDualTimePicker(
                                  context,
                                  day,
                                  editedHours,
                                  setModalState,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          // 1. Show a loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );

                          // 2. Prepare the data (Ensure HH:mm format)
                          Map<String, dynamic> payload = {};
                          editedHours.forEach((key, value) {
                            payload[key] = {
                              "open": value['open'].toString().substring(0, 5),
                              "close": value['close'].toString().substring(0, 5),
                              "closed": value['closed']
                            };
                          });

                          // 3. Call the API
                          bool success = await BusinessHourService().updateBusinessHours(payload);

                          // 4. Remove loading indicator
                          Navigator.pop(context);

                          if (success) {
                            // Close the edit sheet
                            Navigator.pop(context);

                            // Refresh the main page data
                            _fetchSupplierProfile();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Program actualizat cu succes!")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Eroare la salvarea programului.")),
                            );
                          }
                        },
                        child: const Text(
                          "Salvează Modificările",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // void _showEditBusinessHoursSheet(
  //   BuildContext context,
  //   Map<String, dynamic> initialHours,
  // )
  // {
  //   // Create a deep copy to avoid modifying the original list until "Save" is pressed
  //   Map<String, dynamic> editedHours = jsonDecode(jsonEncode(initialHours));
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: const Color(0xFF1E1E1E),
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  //     ),
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setModalState) {
  //           return SafeArea(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const SizedBox(height: 12),
  //                 const Text(
  //                   "Editează Program",
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const Divider(color: Colors.white10, height: 30),
  //
  //                 ConstrainedBox(
  //                   constraints: BoxConstraints(
  //                     maxHeight: MediaQuery.of(context).size.height * 0.5,
  //                   ),
  //                   child: ListView(
  //                     shrinkWrap: true,
  //                     children:
  //                         editedHours.keys.map((day) {
  //                           bool isClosed = editedHours[day]['closed'] ?? false;
  //                           return ListTile(
  //                             title: Text(
  //                               day[0].toUpperCase() + day.substring(1),
  //                               style: const TextStyle(
  //                                 color: Colors.white,
  //                                 fontWeight: FontWeight.w600,
  //                               ),
  //                             ),
  //                             subtitle: Text(
  //                               isClosed
  //                                   ? "Închis"
  //                                   : "${editedHours[day]['open']} - ${editedHours[day]['close']}",
  //                               style: TextStyle(
  //                                 color:
  //                                     isClosed
  //                                         ? Colors.redAccent
  //                                         : Colors.grey[400],
  //                               ),
  //                             ),
  //                             trailing: Row(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 Switch(
  //                                   value: !isClosed,
  //                                   onChanged:
  //                                       (val) => setModalState(
  //                                         () =>
  //                                             editedHours[day]['closed'] = !val,
  //                                       ),
  //                                   activeColor: Colors.greenAccent,
  //                                 ),
  //                                 IconButton(
  //                                   // iOS style time icon
  //                                   icon: const Icon(
  //                                     Icons.access_time_filled_rounded,
  //                                     color: Colors.grey,
  //                                   ),
  //                                   onPressed:
  //                                       isClosed
  //                                           ? null
  //                                           : () => _showDualTimePicker(
  //                                             context,
  //                                             day,
  //                                             editedHours,
  //                                             setModalState,
  //                                           ),
  //                                 ),
  //                               ],
  //                             ),
  //                           );
  //                         }).toList(),
  //                   ),
  //                 ),
  //
  //                 Padding(
  //                   padding: const EdgeInsets.all(24.0),
  //                   child: SizedBox(
  //                     width: double.infinity,
  //                     height: 54,
  //                     child: ElevatedButton(
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Colors.white,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(16),
  //                         ),
  //                       ),
  //                       // onPressed: () async {
  //                       //   // Logic to call BusinessHourService().updateBusinessHours(editedHours)
  //                       //   Navigator.pop(context);
  //                       // },
  //                       // Inside _showEditBusinessHoursSheet -> ElevatedButton onPressed:
  //                       onPressed: () async {
  //                         // 1. Show a loading indicator
  //                         showDialog(
  //                           context: context,
  //                           barrierDismissible: false,
  //                           builder: (context) => const Center(child: CircularProgressIndicator()),
  //                         );
  //
  //                         // 2. Prepare the data (Ensure HH:mm format)
  //                         // Our picker might produce HH:mm:ss, but the API wants HH:mm
  //                         Map<String, dynamic> payload = {};
  //                         editedHours.forEach((key, value) {
  //                           payload[key] = {
  //                             "open": value['open'].toString().substring(0, 5),
  //                             "close": value['close'].toString().substring(0, 5),
  //                             "closed": value['closed']
  //                           };
  //                         });
  //
  //                         // 3. Call the API
  //                         bool success = await BusinessHourService().updateBusinessHours(payload);
  //
  //                         // 4. Remove loading indicator
  //                         Navigator.pop(context);
  //
  //                         if (success) {
  //                           // Close the edit sheet
  //                           Navigator.pop(context);
  //
  //                           // Refresh the main page data
  //                           _fetchSupplierProfile();
  //
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             const SnackBar(content: Text("Program actualizat cu succes!")),
  //                           );
  //                         } else {
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             const SnackBar(content: Text("Eroare la salvarea programului.")),
  //                           );
  //                         }
  //                       },
  //                       child: const Text(
  //                         "Salvează Modificările",
  //                         style: TextStyle(color: Colors.black),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void _showDualTimePicker(
    BuildContext context,
    String day,
    Map hours,
    Function setState,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Material(
            color: Colors.transparent,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.dark,
                // Ensures system labels adapt to dark mode
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: Colors.white, // Changed from Red to White
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              child: Container(
                height: 350,
                color: const Color(0xFF1E1E1E),
                child: Column(
                  children: [
                    // --- HEADER ---
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: const Border(
                          bottom: BorderSide(color: Colors.white10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            child: const Text(
                              "Anulează",
                              style: TextStyle(color: Colors.grey),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            _translateDay(day).toUpperCase(),
                            // Romanian Day Label
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          CupertinoButton(
                            child: const Text(
                              "Gata",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // --- PICKERS ---
                    Expanded(
                      child: Row(
                        children: [
                          _buildPickerColumn("DESCHIDERE", hours[day]['open'], (
                            newTime,
                          ) {
                            setState(
                              () =>
                                  hours[day]['open'] = _durationToTimeString(
                                    newTime,
                                  ),
                            );
                          }),
                          _buildPickerColumn("ÎNCHIDERE", hours[day]['close'], (
                            newTime,
                          ) {
                            setState(
                              () =>
                                  hours[day]['close'] = _durationToTimeString(
                                    newTime,
                                  ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // Helper to translate day names if your 'day' variable is in English (e.g., "Monday")
  String _translateDay(String day) {
    const Map<String, String> romanianDays = {
      'monday': 'Luni',
      'tuesday': 'Marți',
      'wednesday': 'Miercuri',
      'thursday': 'Joi',
      'friday': 'Vineri',
      'saturday': 'Sâmbătă',
      'sunday': 'Duminică',
    };
    return romanianDays[day.toLowerCase()] ?? day;
  }


  Widget _buildPickerColumn(
    String label,
    String initialTime,
    Function(Duration) onChanged,
  ) {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          Expanded(
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,

              // Forces the label to show "hour" and "min"
              initialTimerDuration: _parseTimeString(initialTime),
              onTimerDurationChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // Parses HH:mm:ss into Duration for the picker
  Duration _parseTimeString(String time) {
    try {
      List<String> parts = time.split(':');
      return Duration(hours: int.parse(parts[0]), minutes: int.parse(parts[1]));
    } catch (e) {
      return const Duration(hours: 8, minutes: 0);
    }
  }

  String _durationToTimeString(Duration duration) {
    final String h = duration.inHours.toString().padLeft(2, '0');
    final String m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return "$h:$m"; // Removed the :00 to satisfy the API
  }


  Widget buildQuickAction(
    String title,
    String assetImagePath,
    Color containerBg, {
    int count = 0,
    required VoidCallback onTap, // ADDED required onTap callback
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      // Wrap the whole structure in GestureDetector to capture all taps
      child: GestureDetector(
        onTap: onTap,
        // Wrap with a SizedBox to ensure it expands to fit the Padding width/height
        // or rely on the inner container's padding to define the tap area.
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: Colors.grey.shade800, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Keep column size minimal
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    assetImagePath,
                    width: 48,
                    height: 48,
                    //color: Colors.grey.shade400,
                  ),
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
                  color: Colors.white,
                ),
              ),
            ],
          ),
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
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade800, width: 0.5),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pentru a adăuga servicii noi, vă rugăm să ne contactați:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade300),
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
                  onTap:
                      () =>
                          _copyToClipboard(context, phone, 'Număr de telefon'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade700, width: 0.5),
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
          color: const Color(0xFF202020),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
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
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.content_copy, size: 18, color: Colors.grey.shade400),
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
