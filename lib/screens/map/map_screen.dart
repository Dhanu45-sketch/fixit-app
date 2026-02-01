import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../utils/colors.dart';
import '../../widgets/handyman_card.dart';
import '../handyman/handyman_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final bool isEmergencyMode;

  const MapScreen({
    super.key,
    this.isEmergencyMode = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final FirestoreService _firestoreService = FirestoreService();

  Set<Marker> _markers = {};
  LatLng _currentPosition = const LatLng(7.2906, 80.6337); // Kandy, Sri Lanka
  bool _isLoading = true;
  String? _selectedHandymanId;
  Map<String, dynamic>? _selectedHandyman;
  List<Map<String, dynamic>> _allHandymen = [];
  bool _localEmergencyMode = false; // Local emergency toggle

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(7.2906, 80.6337),
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    _localEmergencyMode = widget.isEmergencyMode; // Initialize with passed value
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadHandymenMarkers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition,
              zoom: 14.0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadHandymenMarkers() async {
    try {
      // FIX: Use emergency filtering based on local toggle state
      final handymenStream = _firestoreService.getTopRatedHandymen(
        limit: 50,
        emergencyOnly: _localEmergencyMode, // Filter by emergency mode
      );

      handymenStream.listen((handymen) {
        if (!mounted) return;

        setState(() {
          _allHandymen = handymen;
          _markers = handymen.where((handyman) {
            // Check if location field exists and is a GeoPoint
            return handyman['location'] != null;
          }).map((handyman) {
            final id = handyman['id'] ?? handyman['user_id'] ?? '';

            // Extract GeoPoint from Firestore
            GeoPoint geoPoint = handyman['location'] as GeoPoint;
            final lat = geoPoint.latitude;
            final lng = geoPoint.longitude;

            // FIX: Use red markers for emergency mode, purple for normal
            return Marker(
              markerId: MarkerId(id),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _localEmergencyMode 
                    ? BitmapDescriptor.hueRed 
                    : BitmapDescriptor.hueViolet,
              ),
              infoWindow: InfoWindow(
                title: '${handyman['first_name']} ${handyman['last_name']}',
                snippet: _localEmergencyMode
                    ? '${handyman['category_name']} - ₨${FirestoreService.calculateEmergencyPrice((handyman['hourly_rate'] ?? 0.0).toDouble()).toStringAsFixed(0)}/hr (Emergency)'
                    : '${handyman['category_name']} - ₨${handyman['hourly_rate']}/hr',
              ),
              onTap: () => _onMarkerTapped(id, handyman),
            );
          }).toSet();
          _isLoading = false;
        });
      });
    } catch (e) {
      debugPrint("Error loading handymen: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMarkerTapped(String handymanId, Map<String, dynamic> handyman) {
    setState(() {
      _selectedHandymanId = handymanId;
      _selectedHandyman = handyman;
    });
  }

  Future<void> _goToCurrentLocation() async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 14.0,
        ),
      ),
    );
  }

  // FIX: Toggle emergency mode and reload markers
  void _toggleEmergencyMode(bool value) {
    setState(() {
      _localEmergencyMode = value;
      _isLoading = true;
      _markers.clear();
      _selectedHandymanId = null;
      _selectedHandyman = null;
    });
    _loadHandymenMarkers(); // Reload with new filter
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? '🚨 Showing emergency specialists only'
              : 'Showing all available specialists',
        ),
        backgroundColor: value ? Colors.red.shade700 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),

          // Top Bar with Emergency Toggle
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Emergency Toggle
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _localEmergencyMode ? Colors.red.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _localEmergencyMode ? Colors.red.shade300 : Colors.grey.shade300,
                        width: _localEmergencyMode ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emergency,
                          color: _localEmergencyMode ? Colors.red.shade700 : AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _localEmergencyMode 
                                    ? 'Emergency Mode Active' 
                                    : 'Available Handymen Nearby',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _localEmergencyMode 
                                      ? Colors.red.shade700 
                                      : AppColors.textDark,
                                ),
                              ),
                              Text(
                                _localEmergencyMode
                                    ? '${_markers.length} emergency specialists (+15% fee)'
                                    : '${_markers.length} specialists found',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _localEmergencyMode 
                                      ? Colors.red.shade700 
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _localEmergencyMode,
                          onChanged: _toggleEmergencyMode,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My Location Button
          Positioned(
            right: 16,
            bottom: _selectedHandymanId != null ? 200 : 100,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Selected Handyman Card
          if (_selectedHandymanId != null && _selectedHandyman != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          HandymanCard(
                            handymanId: _selectedHandymanId!,
                            categoryName: _selectedHandyman!['category_name'] ?? 'Specialist',
                            rating: (_selectedHandyman!['rating_avg'] ?? 0.0).toDouble(),
                            jobsCompleted: _selectedHandyman!['jobs_completed'] ?? 0,
                            hourlyRate: (_selectedHandyman!['hourly_rate'] ?? 0.0).toDouble(),
                            isEmergencyMode: _localEmergencyMode, // Pass emergency state
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedHandymanId = null;
                                      _selectedHandyman = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text('Close'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textDark,
                                    side: const BorderSide(color: AppColors.textLight),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HandymanDetailScreen(
                                          handymanId: _selectedHandymanId!,
                                          isEmergency: _localEmergencyMode, // Pass emergency state
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.person),
                                  label: const Text('View Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _localEmergencyMode 
                                        ? Colors.red.shade700 
                                        : AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
            ),
        ],
      ),
    );
  }
}
