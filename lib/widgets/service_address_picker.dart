// lib/widgets/service_address_picker.dart
// Widget for customers to pick service address when booking

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../utils/colors.dart';

class ServiceAddressPicker extends StatefulWidget {
  final Function(String address, LatLng? location) onAddressSelected;
  final String? initialAddress;

  const ServiceAddressPicker({
    Key? key,
    required this.onAddressSelected,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<ServiceAddressPicker> createState() => _ServiceAddressPickerState();
}

class _ServiceAddressPickerState extends State<ServiceAddressPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;
  bool _useCurrentLocation = false;

  final _addressController = TextEditingController();

  // Default center (Kandy, Sri Lanka)
  static const LatLng _defaultCenter = LatLng(7.2906, 80.6337);

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final location = LatLng(position.latitude, position.longitude);

        setState(() {
          _selectedLocation = location;
          _useCurrentLocation = true;
        });

        await _getAddressFromCoordinates(location);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Current location set'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Location permission denied'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address;
          _addressController.text = address;
        });

        // Notify parent
        widget.onAddressSelected(address, location);
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      final coordsText = 'Lat: ${location.latitude.toStringAsFixed(4)}, '
          'Lng: ${location.longitude.toStringAsFixed(4)}';
      setState(() {
        _addressController.text = coordsText;
        _selectedAddress = coordsText;
      });
      widget.onAddressSelected(coordsText, location);
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty && mounted) {
        final location = LatLng(locations.first.latitude, locations.first.longitude);

        setState(() {
          _selectedLocation = location;
          _selectedAddress = query;
          _useCurrentLocation = false;
        });

        widget.onAddressSelected(query, location);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Address found'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address not found. Please try a different search.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapPickerSheet(
        initialLocation: _selectedLocation ?? _defaultCenter,
        onLocationSelected: (location, address) {
          setState(() {
            _selectedLocation = location;
            _selectedAddress = address;
            _addressController.text = address;
            _useCurrentLocation = false;
          });
          widget.onAddressSelected(address, location);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Use Current Location Checkbox
        CheckboxListTile(
          value: _useCurrentLocation,
          onChanged: _isLoading
              ? null
              : (value) {
            if (value == true) {
              _getCurrentLocation();
            } else {
              setState(() {
                _useCurrentLocation = false;
                _selectedLocation = null;
                _selectedAddress = null;
                _addressController.clear();
              });
              widget.onAddressSelected('', null);
            }
          },
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _isLoading ? 'Getting location...' : 'Use my current location',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: _useCurrentLocation && _selectedAddress != null
              ? Text(
            _selectedAddress!,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
              : null,
        ),

        const SizedBox(height: 8),

        // Manual Address Entry
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addressController,
                enabled: !_useCurrentLocation && !_isLoading,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Service Address',
                  hintText: 'Enter your address or search location',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: !_useCurrentLocation
                      ? IconButton(
                    icon: const Icon(Icons.map, size: 20),
                    onPressed: _isLoading ? null : _openMapPicker,
                    tooltip: 'Pick on map',
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: _useCurrentLocation
                      ? Colors.grey.shade100
                      : AppColors.background,
                ),
                onSubmitted: (_) => _searchAddress(),
              ),
            ),
            if (!_useCurrentLocation) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _isLoading ? null : _searchAddress,
                  tooltip: 'Search address',
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Info Text
        if (!_useCurrentLocation)
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tap the map icon to pick location visually',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),

        // Selected Location Indicator
        if (_selectedLocation != null && !_useCurrentLocation) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location set: ${_selectedAddress ?? 'Custom location'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================
// Map Picker Bottom Sheet
// ============================================

class _MapPickerSheet extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng location, String address) onLocationSelected;

  const _MapPickerSheet({
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _displayAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _getAddressFromCoordinates(_selectedLocation!);
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    setState(() => _isLoading = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _displayAddress = address.isNotEmpty
              ? address
              : 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      setState(() {
        _displayAddress = 'Lat: ${location.latitude.toStringAsFixed(4)}, '
            'Lng: ${location.longitude.toStringAsFixed(4)}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!, _displayAddress);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pick Service Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (location) {
                    setState(() => _selectedLocation = location);
                    _getAddressFromCoordinates(location);
                  },
                  markers: _selectedLocation != null
                      ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() => _selectedLocation = newPosition);
                        _getAddressFromCoordinates(newPosition);
                      },
                    ),
                  }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),

                // Instructions overlay
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tap on map or drag marker to set location',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Address Display & Confirm
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isLoading
                            ? const Text(
                          'Getting address...',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        )
                            : Text(
                          _displayAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}