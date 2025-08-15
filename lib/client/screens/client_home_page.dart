import 'package:flutter/material.dart';

import 'AutocolantScreen.dart';
import 'DetailingScreen.dart';
import 'ITPScreen.dart';
import 'MecanicScreen.dart';
import 'TapiterieScreen.dart';
import 'TractariScreen.dart';
import 'TuningScreen.dart';
import 'VulcanizareScreen.dart';


class client_home_page extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Cum te putem ajuta astăzi?', style: TextStyle(color: Colors.white , fontWeight: FontWeight.w500))),
        backgroundColor: Color(0xFF4B5563),
      ),
      backgroundColor: Color(0xFFFFFFFF),
      body: GridView.count(
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
      ),
    );
  }
}

// class ServiceCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;
//
//   ServiceCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
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
//             children: [
//               Icon(icon, size: 40, color: Color(0xFF808080)),
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


class ServiceCard extends StatelessWidget {
  final String imageAsset; // Path to the asset image
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double imageSize; // Flexible image size

  ServiceCard({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageSize = 80.0, // Default image size
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                imageAsset,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain, // Flexible fit to maintain aspect ratio
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
    );
  }
}