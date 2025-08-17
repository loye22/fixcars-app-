import 'package:flutter/material.dart';
import '../services/MecanicAutoService.dart';
import '../services/ServicesService.dart';

class ServiceSelectionWidget extends StatefulWidget {
  final Function(List<String>) onServicesSelected;
  final List<String> initialSelectedServices;
  String AutoServicetype ;

   ServiceSelectionWidget({
    Key? key,
    required this.onServicesSelected,
    this.initialSelectedServices = const [],
    this.AutoServicetype = "mecanic_auto"
  }) : super(key: key);

  @override
  _ServiceSelectionWidgetState createState() => _ServiceSelectionWidgetState();
}

class _ServiceSelectionWidgetState extends State<ServiceSelectionWidget> {
  final ServicesService _servicesApi = ServicesService();
  List<dynamic> _allServices = [];
  List<dynamic> _selectedServices = [];
  bool _isLoading = false;
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _dropdownOverlay;
  List<dynamic> _filteredServices = [];
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _searchController.addListener(_filterServices);
    _searchFocusNode.addListener(_handleFocusChange);

    // Initialize selected services from parent
    if (widget.initialSelectedServices.isNotEmpty) {
      print('ServiceSelectionWidget: Initializing with services: ${widget.initialSelectedServices}');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeDropdown();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_searchFocusNode.hasFocus && _isDropdownOpen) {
      _closeDropdown();
    }
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
     // print('ServiceSelectionWidget: Fetched ${_allServices.length} services');
      if (_allServices.isNotEmpty) {
        print('ServiceSelectionWidget: First service: ${_allServices[0]}');
      }

      // After fetching services, restore selected services from parent
      _restoreSelectedServices();
    } catch (e) {
      setState(() => _isLoading = false);
      print('ServiceSelectionWidget: Error fetching services: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load services: $e')));
    }
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredServices = _allServices;
      } else {
        _filteredServices =
            _allServices.where((service) {
              // Search in service name
              if (service['service_name'].toString().toLowerCase().contains(
                query,
              )) {
                return true;
              }
              // Search in tags
              final tags = service['tags'] as List;
              return tags.any(
                    (tag) =>
                    tag['tag_name'].toString().toLowerCase().contains(query),
              );
            }).toList();
      }
    });

    // Update dropdown if open
    if (_isDropdownOpen) {
      _updateDropdown();
    }
  }

  void _openDropdown() {
    if (_isDropdownOpen) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _dropdownOverlay = OverlayEntry(
      builder:
          (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 4,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child:
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredServices.isEmpty
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No services found'),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredServices.length,
                itemBuilder: (context, index) {
                  final service = _filteredServices[index];
                  return ListTile(
                    title: Text(service['service_name']),
                    onTap: () {
                      _addService(service);
                      _closeDropdown();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_dropdownOverlay!);
    setState(() => _isDropdownOpen = true);
  }

  void _closeDropdown() {
    if (!_isDropdownOpen) return;
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
    _searchFocusNode.unfocus();
    setState(() => _isDropdownOpen = false);
  }

  void _updateDropdown() {
    _dropdownOverlay?.markNeedsBuild();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _addService(dynamic service) {
    print('ServiceSelectionWidget: Adding service: ${service['service_name']}');
    if (!_selectedServices.any(
          (s) => s['service_id'] == service['service_id'],
    )) {
      setState(() {
        _selectedServices.add(service);
        print('ServiceSelectionWidget: Selected services count: ${_selectedServices.length}');
        _notifyParent();
      });
    } else {
      print('ServiceSelectionWidget: Service already selected');
    }
  }

  void _restoreSelectedServices() {
    if (widget.initialSelectedServices.isEmpty) return;

    print('ServiceSelectionWidget: Restoring selected services: ${widget.initialSelectedServices}');

    // Find services by name and add them to selected services
    for (String serviceName in widget.initialSelectedServices) {
      final service = _allServices.firstWhere(
            (s) => s['service_name'] == serviceName,
        orElse: () => null,
      );
      if (service != null && !_selectedServices.any((s) => s['service_id'] == service['service_id'])) {
        _selectedServices.add(service);
        print('ServiceSelectionWidget: Restored service: $serviceName');
      }
    }

    if (_selectedServices.isNotEmpty) {
      setState(() {});
    }
  }

  void _removeSelectedService(dynamic service) {
    setState(() {
      _selectedServices.remove(service);
      _notifyParent();
    });
  }

  void _notifyParent() {
    // final ids = _selectedServices.map((s) => s['service_id'].toString()).toList();
    // print("_selectedServices $_selectedServices");
    final service_name = _selectedServices.map((s) => s['service_name'].toString()).toList();

    print('ServiceSelectionWidget: Notifying parent with services: $service_name');
    print('ServiceSelectionWidget: Selected services count: ${_selectedServices.length}');

    widget.onServicesSelected(service_name);
  }

  @override
  Widget build(BuildContext context) {
    print('ServiceSelectionWidget: Building with ${_selectedServices.length} selected services');
    print('ServiceSelectionWidget: Selected services: ${_selectedServices.map((s) => s['service_name']).toList()}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Caută un serviciu sau etichetă',
              hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
              prefixIcon: Icon(Icons.search, color: Color(0xFFCCCCCC)),
              filled: true,
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
                  color: Colors.grey, // Same border color
                  width: 1.5,
                ),
              ),
              fillColor: Colors.white,
              // Background white
              suffixIcon: IconButton(
                icon:
                _isDropdownOpen
                    ? Image.asset(
                  'assets/arrowup.png',
                  width: 24,
                  height: 24,
                )
                    : Image.asset(
                  'assets/arrowdown.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: _toggleDropdown,
              ),
            ),
            onTap: () {
              if (!_isDropdownOpen) {
                _openDropdown();
              }
            },
          ),
        ),
        SizedBox(height: 16),
        if (_selectedServices.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
            _selectedServices
                .map(
                  (service) => Chip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    20,
                  ), // Adjust the radius as needed
                ),
                backgroundColor: Colors.white,
                label: Text(service['service_name'] ),
                deleteIcon: Icon(Icons.close, size: 18),
                onDeleted: () => _removeSelectedService(service),
              ),
            )
                .toList(),
          ),
          SizedBox(height: 16),
        ] else ...[

        ],
      ],
    );
  }

  void _removeDropdown() {
    // Check if dropdown is actually open
    if (!_isDropdownOpen || _dropdownOverlay == null) return;

    // Remove the overlay from the screen
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;

    // Reset the dropdown state
    setState(() {
      _isDropdownOpen = false;
    });

    // Clear any focus from the search field
    FocusScope.of(context).requestFocus(FocusNode());

    // Optional: Reset search filter when dropdown closes
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _filteredServices = _allServices;
    }
  }
}

