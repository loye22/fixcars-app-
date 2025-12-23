import 'package:flutter/material.dart';
import '../../shared/services/NavigationService.dart';
import '../../shared/services/phone_service.dart';
import '../services/CarService.dart';

// Presupunând că acesta este importul corect pentru profilul furnizorului
// import 'SupplierProfileScreen.dart';

class BusinessSearchBottomSheet extends StatefulWidget {
  final ObligationType obligationType;

  const BusinessSearchBottomSheet({
    super.key,
    required this.obligationType
  });

  @override
  State<BusinessSearchBottomSheet> createState() => _BusinessSearchBottomSheetState();
}

class _BusinessSearchBottomSheetState extends State<BusinessSearchBottomSheet> {
  final CarService _carService = CarService();
  late Future<Map<String, dynamic>> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    // Apelăm metoda de fetch din serviciul tău
    _suggestionsFuture = _carService.fetchGoldenSuggestions(widget.obligationType);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Indicator de tragere (Drag Indicator)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _suggestionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }

                if (snapshot.hasError || snapshot.data?['success'] == false) {
                  return _buildErrorState(snapshot.data?['error'] ?? 'A apărut o eroare la încărcarea datelor.');
                }

                final List<dynamic> businesses = snapshot.data?['data'] ?? [];

                if (businesses.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    final item = businesses[index];
                    return _buildBusinessCard(context, item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, dynamic item) {
    final bool isOpen = item['is_open'] ?? false;
    final String supplierName = item['supplier_name'] ?? 'Furnizor';

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // print('Navigare către profil: $supplierName');
          // Navigare către profilul furnizorului
          // Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierProfileScreen(userId: item['supplier_id'])));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagine Furnizor
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['supplier_photo'],
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[800], width: 70, height: 70, child: const Icon(Icons.image_not_supported, color: Colors.white38)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Detalii text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplierName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['supplier_address'] ?? 'Adresă indisponibilă',
                          maxLines: 2,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOpen ? '● DESCHIS ACUM' : '● ÎNCHIS',
                          style: TextStyle(
                            color: isOpen ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(color: Colors.white10, height: 1),
              ),
              // Butoane Acțiuni
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      label: 'Sună',
                      icon: Icons.phone,
                      color: Colors.blueAccent,
                      onTap: () => CallService.makeCall(
                          context: context,
                          phoneNumber: item['supplier_phone']
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionBtn(
                      label: 'Mergi',
                      icon: Icons.directions,
                      color: Colors.greenAccent,
                      onTap: () => NavigationService.navigateTo(
                        context: context,
                        latitude: item['latitude'],
                        longitude: item['longitude'],
                        locationName: supplierName,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("Nu am găsit furnizori disponibili.", style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';
//
// class BusinessSearchBottomSheet extends StatelessWidget {
//   const BusinessSearchBottomSheet({super.key});
//
//   // Dummy JSON Data source
//   final Map<String, dynamic> response = const {
//     "success": true,
//     "message": "Businesses found for obligation type: OIL_CHANGE",
//     "data": [
//       {
//         "id": "e44fac61-e112-441a-ae88-c1d2ff7d00cb",
//         "supplier_id": "06052eef-9bcc-4d9b-a243-61809ee944d0",
//         "supplier_name": "Fermă Ecologică Verde",
//         "supplier_photo": "https://ghidautoservice.ro/wp-content/uploads/2020/07/PA-WEB-AUTO-MASTER-SRL.jpg",
//         "supplier_address": "Bulevardul Revoluției din 1989 nr. 5, Timișoara, România",
//         "supplier_phone": "0763523421",
//         "brand_name": "BMW",
//         "is_open": false,
//         "review_score": 0,
//         "total_reviews": 0,
//         "city": "Cluj-Napoca",
//         "latitude": 45.7489,
//         "longitude": 21.2087,
//         "price": "0.00",
//         "active": true
//       }
//     ]
//   };
//
//   @override
//   Widget build(BuildContext context) {
//     final businesses = response['data'] as List<dynamic>;
//
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.65,
//       decoration: const BoxDecoration(
//         color: Color(0xFF1E1E1E),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: Column(
//         children: [
//           // Drag Indicator
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade600,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(
//               response['message'].toString().split(':').last.replaceAll('_', ' '),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 0.5,
//               ),
//             ),
//           ),
//
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: businesses.length,
//               itemBuilder: (context, index) {
//                 final item = businesses[index];
//                 final bool isOpen = item['is_open'] ?? false;
//
//                 return Card(
//                   color: const Color(0xFF2C2C2C),
//                   margin: const EdgeInsets.only(bottom: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     side: BorderSide(color: Colors.grey.withOpacity(0.1)),
//                   ),
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(16),
//                     onTap: () => print('Navigate to profile: ${item['supplier_name']}'),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Column(
//                         children: [
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Supplier Photo
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: Image.network(
//                                   item['supplier_photo'],
//                                   width: 80,
//                                   height: 80,
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (_, __, ___) => Container(
//                                     width: 80,
//                                     height: 80,
//                                     color: Colors.grey[800],
//                                     child: const Icon(Icons.business, color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               // Info
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       item['supplier_name'],
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       item['supplier_address'],
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     // Status Badge
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                       decoration: BoxDecoration(
//                                         color: (isOpen ? Colors.green : Colors.red).withOpacity(0.1),
//                                         borderRadius: BorderRadius.circular(4),
//                                       ),
//                                       child: Text(
//                                         isOpen ? 'OPEN' : 'CLOSED',
//                                         style: TextStyle(
//                                           color: isOpen ? Colors.greenAccent : Colors.redAccent,
//                                           fontSize: 10,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const Divider(height: 24, color: Colors.white10),
//                           // Action Buttons
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildActionButton(
//                                   icon: Icons.phone_in_talk_outlined,
//                                   label: 'Sună',
//                                   color: Colors.blueAccent,
//                                   onTap: () => print('Calling: ${item['supplier_phone']}'),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: _buildActionButton(
//                                   icon: Icons.near_me_outlined,
//                                   label: 'Mergi',
//                                   color: Colors.greenAccent,
//                                   onTap: () => print('Location: ${item['latitude']}, ${item['longitude']}'),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         decoration: BoxDecoration(
//           border: Border.all(color: color.withOpacity(0.5)),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 18, color: color),
//             const SizedBox(width: 8),
//             Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }
// }