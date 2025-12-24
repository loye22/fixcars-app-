import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/BrandService.dart';

// Refined Gray Palette for Visibility
const Color _darkBackground = Color(0xFF121212); // Deep Charcoal
const Color _darkCard = Color(0xFF1E1E1E);       // Lighter Gray for elevation
const Color _surfaceGray = Color(0xFF2C2C2C);    // Surface for inputs
const Color _accentSilver = Color(0xFFE0E0E0);   // Bright Silver for icons/titles
const Color _primaryText = Color(0xFFFFFFFF);    // Pure White for contrast
const Color _secondaryText = Color(0xFFFFFFFF);  // Muted Gray for hints
const Color _borderGray = Color(0xFF383838);     // Subtle borders

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
    final selectedBrand = brand['brand_name'].toLowerCase() == 'all cars' ? null : brand;
    widget.onBrandSelected(selectedBrand);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedBrandId = null;
      _filteredBrands = _allBrands;
    });
    widget.onBrandSelected(null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selectează Marcă',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.history, size: 16, color: _secondaryText),
                label: const Text(
                  'Resetare',
                  style: TextStyle(color: _secondaryText, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: _darkCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field - Now more visible with _surfaceGray
          TextField(
            controller: _searchController,
            style: const TextStyle(color: _primaryText),
            decoration: InputDecoration(
              hintText: 'Caută marcă automobil...',
              hintStyle: const TextStyle(color: _secondaryText),
              prefixIcon: const Icon(Icons.search, color: _accentSilver),
              filled: true,
              fillColor: _surfaceGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderGray, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _isLoading
              ? Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: _accentSilver,
              size: 40,
            ),
          )
              : _error != null
              ? Text(_error!, style: const TextStyle(color: Colors.redAccent))
              : _buildBrandList(),
        ],
      ),
    );
  }

  Widget _buildBrandList() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredBrands.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final brand = _filteredBrands[index];
          final isSelected = _selectedBrandId == brand['brand_id'];

          return GestureDetector(
            onTap: () => _selectBrand(brand),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 70,
                  width: 70,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white , //isSelected ? _accentSilver : _darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.white : _borderGray,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 10)]
                        : [],
                  ),
                  child: Image.network(
                    brand['brand_photo'] ?? "",
                    fit: BoxFit.contain,
                    // Apply a dark filter to logo if background is silver (selected)
                    color: isSelected ? Colors.black87 : null,
                    colorBlendMode: isSelected ? BlendMode.srcIn : null,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.directions_car, color: isSelected ? Colors.black : _secondaryText),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  brand['brand_name'] ?? "",
                  style: TextStyle(
                    color: isSelected ? _primaryText : _secondaryText,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

