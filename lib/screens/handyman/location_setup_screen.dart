// lib/screens/handyman/location_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../auth/approval_pending_screen.dart';

class LocationSetupScreen extends StatefulWidget {
  final bool isRegistrationFlow;

  const LocationSetupScreen({
    Key? key,
    this.isRegistrationFlow = false,
  }) : super(key: key);

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  final _authService = AuthService();
  GoogleMapController? _mapController;

  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;

  final _addressController = TextEditingController();
  final _serviceRadiusController = TextEditingController(text: '10');

  static const LatLng _defaultLocation = LatLng(7.2906, 80.6337);

  @override
  void initState() {
    super.initState();
    if (!widget.isRegistrationFlow) {
      _loadExistingLocation();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _serviceRadiusController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLocation() async {
    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('handymanProfiles')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        final GeoPoint? geoPoint = data?['location'];

        if (geoPoint != null) {
          setState(() {
            _selectedLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
            _serviceRadiusController.text = (data?['service_radius_km'] ?? 10).toString();
          });
          await _getAddressFromCoordinates(_selectedLocation!);
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 14));
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final location = LatLng(position.latitude, position.longitude);

        setState(() => _selectedLocation = location);
        await _getAddressFromCoordinates(location);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 14));
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [place.street, place.locality, place.country].where((e) => e != null && e!.isNotEmpty).join(', ');
        setState(() {
          _selectedAddress = address;
          _addressController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUserId;
      final serviceRadius = double.tryParse(_serviceRadiusController.text) ?? 10.0;

      await FirebaseFirestore.instance.collection('handymanProfiles').doc(userId).update({
        'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        'location_address': _selectedAddress ?? _addressController.text,
        'service_radius_km': serviceRadius,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        if (widget.isRegistrationFlow) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ApprovalPendingScreen()),
            (route) => false,
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRegistrationFlow ? 'Step 4: Service Area' : 'Set Your Location'),
        automaticallyImplyLeading: !widget.isRegistrationFlow,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 3,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _selectedLocation ?? _defaultLocation, zoom: 14),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (loc) {
                    setState(() => _selectedLocation = loc);
                    _getAddressFromCoordinates(loc);
                  },
                  markers: _selectedLocation == null ? {} : {
                    Marker(markerId: const MarkerId('selected'), position: _selectedLocation!, draggable: true)
                  },
                  myLocationEnabled: true,
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Use My Location'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _serviceRadiusController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Service Radius (km)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveLocation,
                            child: Text(widget.isRegistrationFlow ? 'Complete Registration' : 'Save Location'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
