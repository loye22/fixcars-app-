
import 'package:fixcars/client/screens/SupplierProfileScreen.dart';
import 'package:fixcars/shared/services/api_service.dart';
import 'package:flutter/material.dart';

enum SupplierTier { bronze, silver, gold }

// Theme Palette
const Color _darkCard = Color(0xFF1E1E1E);
const Color _surfaceGray = Color(0xFF2C2C2C);
const Color _accentSilver = Color(0xFFE0E0E0);
const Color _primaryText = Color(0xFFFFFFFF);
const Color _secondaryText = Color(0xFFAAAAAA);
const Color _borderGray = Color(0xFF383838);
const Color _goldAccent = Color(0xFFFFD700);

class BusinessCardWidget extends StatelessWidget {
  final String supplierID;
  final String businessName;
  final double rating;
  final int reviewCount;
  final String distance;
  final String location;
  final bool isAvailable;
  final String profileUrl;
  final String servicesUrl;
  final String carBrandUrl;
  final SupplierTier tier;

  const BusinessCardWidget({
    required this.businessName,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.location,
    required this.isAvailable,
    required this.profileUrl,
    required this.servicesUrl,
    required this.carBrandUrl,
    required this.supplierID,
    this.tier = SupplierTier.silver,
  });

  // Elegant Bottom Sheet Explanation
  void _showTierBottomSheet(BuildContext context) {
    String title;
    String description;
    IconData icon;
    Color iconColor;

    switch (tier) {
      case SupplierTier.gold:
        title = 'ALEGERE GOLD';
        description = 'Acest partener este verificat și recomandat oficial de către echipa fixcars.ro. Alegerea Gold reprezintă un standard înalt de calitate și profesionalism.';
        icon = Icons.stars;
        iconColor = _goldAccent;
        break;
      case SupplierTier.bronze:
        title = 'NEVERIFICAT';
        description = 'Acest profil este în curs de revizuire manuală. Recomandăm verificarea detaliilor direct cu furnizorul până la confirmarea finală a platformei.';
        icon = Icons.info_outline;
        iconColor = _secondaryText;
        break;
      case SupplierTier.silver:
      default:
        title = 'VERIFICAT';
        description = 'Identitatea și documentele acestui partener au fost verificate cu succes. Este un membru confirmat al comunității noastre.';
        icon = Icons.verified;
        iconColor = Colors.blueAccent;
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderGray,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Icon(icon, color: iconColor, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _secondaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _surfaceGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'AM ÎNȚELES',
                    style: TextStyle(color: _primaryText, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTierBadge(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTierBottomSheet(context),
      child: _getBadgeUI(),
    );
  }

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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, color: _goldAccent, size: 12),
              SizedBox(width: 4),
              Text('ALEGERE GOLD', style: TextStyle(color: _goldAccent, fontSize: 10, fontWeight: FontWeight.bold)),
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
          child: const Text('NEVERIFICAT', style: TextStyle(color: _secondaryText, fontSize: 10, fontWeight: FontWeight.w600)),
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
            const SizedBox(width: 4),
            const Text('VERIFICAT', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderGray, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryText),
                          ),
                          _buildTierBadge(context),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: _goldAccent, size: 20),
                          const SizedBox(width: 4),
                          Text('${rating.toStringAsFixed(2)}', style: const TextStyle(color: _primaryText, fontWeight: FontWeight.bold)),
                          Text(' ($reviewCount recenzii)', style: const TextStyle(color: _secondaryText, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: _secondaryText, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text('$distance • $location', style: const TextStyle(color: _secondaryText, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAvailable ? 'DESCHIS' : 'ÎNCHIS',
                          style: TextStyle(
                            color: isAvailable ? const Color(0xFF16A34A) : const Color(0xFFFF4141),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    CircleAvatar(radius: 40, backgroundImage: NetworkImage(profileUrl), backgroundColor: _surfaceGray),
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 40, padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Image.network(ApiService.baseMediaUrl + carBrandUrl, fit: BoxFit.contain),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderGray, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SupplierProfileScreen(userId: supplierID)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _surfaceGray,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _borderGray)),
                ),
                child: const Text('CONTACTEAZĂ', style: TextStyle(color: _primaryText, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}