import 'package:fixcars/shared/screens/SupplierSignupScreen.dart';
import 'package:fixcars/shared/screens/client_singup_screen.dart';
import 'package:flutter/material.dart';


class signup_screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(19),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30)
              ),
              child: Image.asset(
                'assets/logos/introo.png', // Replace with your car icon asset
                height: 100,
              ),
            ),
            // SizedBox(height: 20),
            // Text(
            //   'Auto Rescue',
            //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
            // ),
            SizedBox(height: 5),
            Text(
              'Soluția ta completă pentru servicii auto',
              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
            SizedBox(height: 30),
            Text(
              'Alege rolul tău:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 125,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => client_singup_screen()),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Image.asset('assets/op1.png'),
                              title: Text(
                                'Client',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'Rezervă servicii, discută cu mecanicii și gestionează-ți vehiculele',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 125,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SupplierSignupScreen()),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Image.asset('assets/op2.png'),
                              title: Text(
                                'Mecanic',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'Gestionează programările și comunică cu clienții',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),



          ],
        ),
      ),
    );
  }
}