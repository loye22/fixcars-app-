import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/AddressService.dart';
import '../services/MecanicAutoService.dart';
import '../widgets/BrandService.dart';
import '../widgets/BusinessCardWidget.dart';
import '../widgets/ServiceSelectionWidget.dart';

class MecanicScreen extends StatefulWidget {
  @override
  _MecanicScreenState createState() => _MecanicScreenState();
}

class _MecanicScreenState extends State<MecanicScreen> {
  String _address = "Se încarcă adresa...";
  List<Map<String, dynamic>> _mechanicServices = [];
  List<Map<String, dynamic>> _filteredMechanicServices = [];
  List<String> _selectedServices = [];
  Map<String, dynamic>? _selectedBrand; // Add this
  bool _isLoading = true;
  String? _error;

  final AddressService _addressService = AddressService();
  final MecanicAutoService _mechanicService = MecanicAutoService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch address
      String address = await _addressService.getCurrentAddress();

      // Fetch mechanic services
      List<Map<String, dynamic>> services =   //lat=&lng=
          await _mechanicService.fetchMecanicAutos(category: AutoService.mecanic_auto ,lat:45.6486 , lng: 25.6061  );

      setState(() {
        _address = address;
        _mechanicServices = services;
        _filteredMechanicServices = services; // Initialize with all
        _isLoading = false;
      });


    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterServicesByBrand(Map<String, dynamic>? brand) {
    setState(() {
      _selectedBrand = brand;
      if (brand == null) {
        _filteredMechanicServices = _mechanicServices;
      } else {
        _filteredMechanicServices =
            _mechanicServices.where((service) {
              return service['brand_photo'] == brand['brand_photo'];
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/location.png', width: 30),
            SizedBox(width: 8),
            Center(
              child: Text(
                _address,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF4B5563),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child:
            _isLoading
                ? Center(
                  child: LoadingAnimationWidget.threeArchedCircle(
                    color: Color(0xFF4B5563),
                    size: 50,
                  ),
                )
                : _error != null
                ? Center(
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                )
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrandSelectorWidget(
                        onBrandSelected:
                            _filterServicesByBrand, // Callback to filter
                      ),
                      SizedBox(height: 16),
                      ServiceSelectionWidget(
                        onServicesSelected: (selectedServices) {
                          setState(() {
                            //_selectedServices = selectedServices;
                          });
                          // You can add filtering logic here if needed
                        },
                      ),
                      SizedBox(height: 16), // Optional spacing
                      _filteredMechanicServices.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/noresults.png', // your image path
                              width: 150,
                              height: 150,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nu s-au găsit rezultate, te rugăm să ajustezi filtrul.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                          : Column(
                        children: _filteredMechanicServices.map((service) {
                          return BusinessCardWidget(
                            businessName: service['supplier_name'] ?? 'Unknown',
                            rating: (service['review_score'] as num?)?.toDouble() ?? 0.0,
                            reviewCount: service['total_reviews'] ?? 0,
                            distance: "${service['distance_km'] ?? 0.0} km",
                            location: service['supplier_address'] ?? 'Unknown',
                            isAvailable: service['is_open'] ?? false,
                            profileUrl: service['supplier_photo'] ?? '',
                            servicesUrl: service['photo_url'] ?? '',
                            carBrandUrl: service['brand_photo'] ?? '',
                          );
                        }).toList(),
                      ),


                      // ..._filteredMechanicServices.map((service) {
                      //   return BusinessCardWidget(
                      //     businessName: service['supplier_name'] ?? 'Unknown',
                      //     rating:
                      //         (service['review_score'] as num?)?.toDouble() ??
                      //         0.0,
                      //     reviewCount: service['total_reviews'] ?? 0,
                      //     distance: "${service['distance_km'] ?? 0.0} km",
                      //     location: service['supplier_address'] ?? 'Unknown',
                      //     isAvailable: service['is_open'] ?? false,
                      //     profileUrl: service['supplier_photo'] ?? '',
                      //     servicesUrl: service['photo_url'] ?? '',
                      //     carBrandUrl: service['brand_photo'] ?? '',
                      //   );
                      // }).toList(),
                    ],
                  ),
                ),
      ),
    );
  }
}


