import 'package:fixcars/shared/screens/SupplierSignupScreen.dart';
import 'package:fixcars/shared/screens/client_singup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- DESIGN CONSTANTS ---
const Color kBackgroundColor = Color(0xFF000000);
const Color kSurfaceColor = Color(0xFF121212);
const Color kBorderColor = Color(0xFF2C2C2C);
const Color kPrimaryAccent = Color(0xFF00B4D8);
const String kFontFamily = 'monospace';

class signup_screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryAccent.withOpacity(0.1),
                    blurRadius: 40,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Image.asset(
                'assets/logos/introo.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 40),

            // Subtitle
            const Text(
              'SOLUȚIA TA COMPLETĂ AUTO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                letterSpacing: 3,
                fontFamily: kFontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 60),

            const Text(
              'ALEGE ROLUL TĂU',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 5,
                fontFamily: kFontFamily,
              ),
            ),
            const SizedBox(height: 30),

            // Role Selection Cards
            _buildRoleCard(
              context,
              title: 'CLIENT',
              subtitle: 'Solicită asistență și gestionează mașina',
              icon: CupertinoIcons.person_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => client_singup_screen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              title: 'Furnizor de servicii',
              subtitle: 'Gestionează programări și fluxul de lucru',
              icon: CupertinoIcons.wrench_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SupplierSignupScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: kPrimaryAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                     // fontFamily: kFontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: kBorderColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
// import 'package:fixcars/shared/screens/SupplierSignupScreen.dart';
// import 'package:fixcars/shared/screens/client_singup_screen.dart';
// import 'package:flutter/material.dart';
//
//
// class signup_screen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF3F4F6),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: EdgeInsets.all(19),
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(30)
//               ),
//               child: Image.asset(
//                 'assets/logos/introo.png', // Replace with your car icon asset
//                 height: 100,
//               ),
//             ),
//             // SizedBox(height: 20),
//             // Text(
//             //   'Auto Rescue',
//             //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
//             // ),
//             SizedBox(height: 5),
//             Text(
//               'Soluția ta completă pentru servicii auto',
//               style: TextStyle(fontSize: 16, color: Colors.blueGrey),
//             ),
//             SizedBox(height: 30),
//             Text(
//               'Alege rolul tău:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
//             ),
//             SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 children: [
//                   Stack(
//                     children: [
//                       Container(
//                         height: 125,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                           ),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         left: 0,
//                         right: 0,
//                         child: GestureDetector(
//                           onTap: (){
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => client_singup_screen()),
//                             );
//                           },
//                           child: Card(
//                             color: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             margin: EdgeInsets.zero,
//                             child: ListTile(
//                               contentPadding: EdgeInsets.all(16),
//                               leading: Image.asset('assets/op1.png'),
//                               title: Text(
//                                 'Client',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                               subtitle: Text(
//                                 'Rezervă servicii, discută cu mecanicii și gestionează-ți vehiculele',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 10),
//                   Stack(
//                     children: [
//                       Container(
//                         height: 125,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                           ),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         left: 0,
//                         right: 0,
//                         child: GestureDetector(
//                           onTap: (){
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => SupplierSignupScreen()),
//                             );
//                           },
//                           child: Card(
//                             color: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             margin: EdgeInsets.zero,
//                             child: ListTile(
//                               contentPadding: EdgeInsets.all(16),
//                               leading: Image.asset('assets/op2.png'),
//                               title: Text(
//                                 'Mecanic',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                               subtitle: Text(
//                                 'Gestionează programările și comunică cu clienții',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//
//
//           ],
//         ),
//       ),
//     );
//   }
// }