import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../shared/services/api_service.dart';
import '../services/BrandService.dart';
import 'ServiceSelectionWidget.dart'; // Adjust path if needed

class BrandSelectorWidget extends StatefulWidget {
  final Function(Map<String, dynamic>?) onBrandSelected;

  const BrandSelectorWidget({Key? key, required this.onBrandSelected}) : super(key: key);

  @override
  _BrandSelectorWidgetState createState() => _BrandSelectorWidgetState();
}

class _BrandSelectorWidgetState extends State<BrandSelectorWidget> {
  final BrandService _brandService = BrandService();
  List<Map<String, dynamic>> _allBrands = [];
  List<Map<String, dynamic>> _filteredBrands = [];
  String? _selectedBrandId;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBrands();
    _searchController.addListener(_filterBrands);
  }

  Future<void> _fetchBrands() async {
    try {
      final brands = await _brandService.fetchBrands();
      setState(() {
        _allBrands = brands;
        _filteredBrands = brands;
        _isLoading = false;
      });
      // Default to selecting "all cars" if it exists
      final allCarsBrand = brands.firstWhere(
            (brand) => brand['brand_name'].toLowerCase() == 'all cars',
        orElse: () => {},
      );
      if (allCarsBrand.isNotEmpty) {
        _selectBrand(allCarsBrand);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterBrands() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBrands = _allBrands.where((brand) {
        return brand['brand_name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _selectBrand(Map<String, dynamic> brand) {
    setState(() {
      _selectedBrandId = brand['brand_id'];
    });
    widget.onBrandSelected(brand['brand_name'].toLowerCase() == 'all cars' ? null : brand);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Selectează marcă automobil',
            hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(0xFFCCCCCC), // Same border color
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(0xFFCCCCCC), // Same border color
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        SizedBox(height: 16),

        _isLoading
            ? Center(
          child: LoadingAnimationWidget.threeArchedCircle(
            color: Color(0xFF4B5563),
            size: 50,
          ),
        )
            : _error != null
            ? Text(_error!, style: TextStyle(color: Colors.red))
            : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filteredBrands.map((brand) {
              final isSelected = _selectedBrandId == brand['brand_id'];
              return GestureDetector(
                onTap: () => _selectBrand(brand),
                child: Padding(
                  padding: const EdgeInsets.only(left:  5.0 , right:  5 ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.white,

                    ),
                    padding: EdgeInsets.all( 12),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                          ),
                          child: Image.network(
                            brand['brand_photo'],
                            width: 60,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          brand['brand_name'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}