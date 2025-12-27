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
  const MapScreen({super.key});

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

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(7.2906, 80.6337), // Kandy coordinates
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
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
      final handymenStream = _firestoreService.getTopRatedHandymen(limit: 50);

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

            return Marker(
              markerId: MarkerId(id),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
              infoWindow: InfoWindow(
                title: '${handyman['first_name']} ${handyman['last_name']}',
                snippet: '${handyman['category_name']} - ₨${handyman['hourly_rate']}/hr',
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

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                    const Icon(Icons.location_on, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Handymen Nearby',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${_markers.length} specialists found',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.person),
                                  label: const Text('View Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
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