import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import '../services/ServicesService.dart';

// Your specified color palette
const Color _darkBackground = Color(0xFF121212);
const Color _darkCard = Color(0xFF1E1E1E);
const Color _surfaceGray = Color(0xFF2C2C2C);
const Color _accentSilver = Color(0xFFE0E0E0);
const Color _primaryText = Color(0xFFFFFFFF);
const Color _secondaryText = Color(0xFFAAAAAA);
const Color _borderGray = Color(0xFF383838);

class ServiceSelectionWidget extends StatefulWidget {
  final Function(List<String>) onServicesSelected;
  final List<String> initialSelectedServices;
  final String AutoServicetype;

  ServiceSelectionWidget({
    Key? key,
    required this.onServicesSelected,
    this.initialSelectedServices = const [],
    this.AutoServicetype = "mecanic_auto",
  }) : super(key: key);

  @override
  _ServiceSelectionWidgetState createState() => _ServiceSelectionWidgetState();
}

class _ServiceSelectionWidgetState extends State<ServiceSelectionWidget> {
  final ServicesService _servicesApi = ServicesService();
  List<dynamic> _allServices = [];
  List<dynamic> _selectedServices = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredServices = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final response = await _servicesApi.fetchServices(category: widget.AutoServicetype);
      setState(() {
        _allServices = response['data'] ?? [];
        _filteredServices = _allServices;
        _isLoading = false;
      });
      _restoreSelectedServices();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterServices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredServices = _allServices;
      } else {
        _filteredServices = _allServices.where((service) {
          final name = service['service_name'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // iOS Style Modal Bottom Sheet instead of Overlay
  void _showIOSPicker() {
    HapticFeedback.mediumImpact(); // Adds that iOS feel
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    // iOS "Grabber" handle
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _borderGray,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        style: const TextStyle(color: _primaryText),
                        decoration: InputDecoration(
                          hintText: "Căutare servicii",
                          hintStyle: const TextStyle(color: _secondaryText),
                          prefixIcon: const Icon(Icons.search, color: _secondaryText),
                          fillColor: _surfaceGray,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          _filterServices(val);
                          setModalState(() {}); // Refresh modal list
                        },
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: _accentSilver))
                          : ListView.separated(
                        itemCount: _filteredServices.length,
                        separatorBuilder: (context, index) => const Divider(color: _borderGray, height: 1),
                        itemBuilder: (context, index) {
                          final service = _filteredServices[index];
                          final isSelected = _selectedServices.any((s) => s['service_id'] == service['service_id']);

                          return ListTile(
                            title: Text(service['service_name'], style: const TextStyle(color: _primaryText)),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: _accentSilver)
                                : null,
                            onTap: () {
                              _addService(service);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  void _addService(dynamic service) {
    if (!_selectedServices.any((s) => s['service_id'] == service['service_id'])) {
      setState(() {
        _selectedServices.add(service);
        _notifyParent();
      });
    }
  }

  void _restoreSelectedServices() {
    if (widget.initialSelectedServices.isEmpty) return;
    for (String serviceName in widget.initialSelectedServices) {
      final service = _allServices.firstWhere(
            (s) => s['service_name'] == serviceName,
        orElse: () => null,
      );
      if (service != null && !_selectedServices.any((s) => s['service_id'] == service['service_id'])) {
        _selectedServices.add(service);
      }
    }
    if (_selectedServices.isNotEmpty) setState(() {});
  }

  void _removeSelectedService(dynamic service) {
    setState(() {
      _selectedServices.remove(service);
      _notifyParent();
    });
  }

  void _notifyParent() {
    final service_names = _selectedServices.map((s) => s['service_name'].toString()).toList();
    widget.onServicesSelected(service_names);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The "Trigger" field
        GestureDetector(
          onTap: _showIOSPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _surfaceGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderGray),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: _secondaryText),
                const SizedBox(width: 12),
                const Text(
                  'Alege un serviciu...',
                  style: TextStyle(color: _secondaryText, fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: _secondaryText),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Selected chips display
        if (_selectedServices.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedServices.map((service) {
              return Chip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // iOS uses less rounded chips usually
                  side: const BorderSide(color: _borderGray),
                ),
                backgroundColor: _darkCard,
                label: Text(
                  service['service_name'],
                  style: const TextStyle(color: _primaryText, fontSize: 13),
                ),
                deleteIcon: const Icon(Icons.cancel, size: 18, color: _secondaryText),
                onDeleted: () => _removeSelectedService(service),
              );
            }).toList(),
          ),
      ],
    );
  }
}