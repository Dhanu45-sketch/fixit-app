// lib/screens/customer/customer_map_screen.dart
// Customer map to find and book handymen with privacy protection

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/location_privacy.dart';
import '../../utils/colors.dart';
import '../../services/auth_service.dart';
import '../handyman/handyman_detail_screen.dart';

class CustomerMapScreen extends StatefulWidget {
  const CustomerMapScreen({Key? key}) : super(key: key);

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen> {
  GoogleMapController? _mapController;
  final _authService = AuthService();

  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  bool _isLoading = true;
  String _selectedCategory = 'All';
  String? _selectedHandymanId;

  final List<String> _categories = [
    'All',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'AC Repair',
    'Cleaning',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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

        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        // Move camera to user location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            13,
          ),
        );

        _loadNearbyHandymen();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyHandymen() async {
    if (_currentPosition == null) return;

    try {
      final userId = _authService.currentUserId;

      // Check for active bookings
      final activeBookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('customer_id', isEqualTo: userId)
          .where('status', whereIn: ['Confirmed', 'In Progress'])
          .get();

      final activeBookingHandymen = activeBookingsSnapshot.docs
          .map((doc) => doc.data()['handyman_id'] as String)
          .toSet();

      // Query handymen
      Query query = FirebaseFirestore.instance
          .collection('handymanProfiles')
          .where('work_status', isEqualTo: 'Available');

      // Filter by category
      if (_selectedCategory != 'All') {
        query = query.where('category_name', isEqualTo: _selectedCategory);
      }

      final handymenSnapshot = await query.get();

      final markers = <Marker>{};
      final circles = <Circle>{};

      for (var doc in handymenSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check location sharing enabled
        if (data['location_sharing_enabled'] == false) continue;
        if (data['show_on_map'] == false) continue;

        final GeoPoint? geoPoint = data['location'];
        if (geoPoint == null) continue;

        final actualLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
        final handymanId = doc.id;

        // Privacy protection
        final hasActiveBooking = activeBookingHandymen.contains(handymanId);
        final bookingStatus = hasActiveBooking ? 'Confirmed' : 'None';

        final privacyRadius = LocationPrivacy.getPrivacyRadius(
          bookingStatus,
          hasActiveBooking,
        );

        final fuzzedLocation = LocationPrivacy.fuzzLocation(
          actualLocation,
          radiusKm: privacyRadius,
        );

        // Calculate distance
        final distance = LocationPrivacy.calculateApproximateDistance(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          fuzzedLocation,
        );

        // Create custom marker
        final markerIcon = await _getMarkerIcon(
          data['category_name'] ?? 'Service',
          hasActiveBooking,
        );

        markers.add(
          Marker(
            markerId: MarkerId(handymanId),
            position: fuzzedLocation,
            onTap: () => _onMarkerTapped(handymanId, data, fuzzedLocation, distance),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: '${data['category_name'] ?? 'Handyman'}',
              snippet: '${distance.toStringAsFixed(1)} km away • Rs ${data['hourly_rate']?.toStringAsFixed(0) ?? 'N/A'}/hr',
            ),
          ),
        );

        // Add privacy circle (only if no active booking)
        if (!hasActiveBooking && privacyRadius > 0.2) {
          circles.add(
            Circle(
              circleId: CircleId('privacy_$handymanId'),
              center: fuzzedLocation,
              radius: privacyRadius * 1000,
              fillColor: AppColors.primary.withOpacity(0.08),
              strokeColor: AppColors.primary.withOpacity(0.25),
              strokeWidth: 1,
            ),
          );
        }
      }

      setState(() {
        _markers = markers;
        _circles = circles;
      });
    } catch (e) {
      debugPrint('Error loading handymen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading handymen: $e')),
        );
      }
    }
  }

  Future<BitmapDescriptor> _getMarkerIcon(String category, bool hasBooking) async {
    // Use different colors based on category and booking status
    if (hasBooking) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }

    switch (category.toLowerCase()) {
      case 'plumbing':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'electrical':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'carpentry':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'painting':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _onMarkerTapped(
      String handymanId,
      Map<String, dynamic> data,
      LatLng location,
      double distance,
      ) {
    setState(() => _selectedHandymanId = handymanId);
    _showHandymanBottomSheet(handymanId, data, location, distance);
  }

  void _showHandymanBottomSheet(
      String handymanId,
      Map<String, dynamic> data,
      LatLng location,
      double distance,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(handymanId)
                  .snapshots(),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                final firstName = userData?['first_name'] ?? '';
                final lastName = userData?['last_name'] ?? '';
                final fullName = firstName.isEmpty
                    ? "Handyman"
                    : "$firstName $lastName";
                final profileImage = userData?['profile_image'];

                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            // Profile Image
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              backgroundImage: profileImage != null
                                  ? NetworkImage(profileImage)
                                  : null,
                              child: profileImage == null
                                  ? Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'H',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                                  : null,
                            ),

                            const SizedBox(width: 16),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['category_name'] ?? 'Service Provider',
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(data['rating_avg'] ?? 0.0).toStringAsFixed(1)} ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '(${data['review_count'] ?? 0})',
                                        style: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${data['jobs_completed'] ?? 0} jobs',
                                        style: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 13,
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

                      const SizedBox(height: 20),

                      // Privacy Notice
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip_outlined,
                                color: Colors.blue.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Approximate location shown for privacy. Exact address shared after booking.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Details
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.location_on,
                              'Distance',
                              '${distance.toStringAsFixed(1)} km away',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.attach_money,
                              'Hourly Rate',
                              'Rs ${data['hourly_rate']?.toStringAsFixed(0) ?? 'N/A'}',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.work_outline,
                              'Experience',
                              '${data['experience'] ?? 0} years',
                            ),
                            if (data['bio'] != null && data['bio'].toString().isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['bio'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HandymanDetailScreen(
                                        handymanId: handymanId,
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'View Full Profile',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HandymanDetailScreen(
                                        handymanId: handymanId,
                                        autoOpenBooking: true,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Book Now',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    ).whenComplete(() {
      setState(() => _selectedHandymanId = null);
    });
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(7.2906, 80.6337),
              zoom: 13,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _loadNearbyHandymen();
              }
            },
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Category Filter
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildCategoryFilter(),
          ),

          // Legend
          Positioned(
            bottom: 100,
            left: 16,
            child: _buildLegend(),
          ),

          // Refresh Button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _loadNearbyHandymen,
              child: const Icon(Icons.refresh, color: AppColors.primary),
            ),
          ),

          // Privacy Info Button
          Positioned(
            bottom: 155,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _showPrivacyInfo,
              child: const Icon(Icons.info_outline, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
                _loadNearbyHandymen();
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              elevation: 2,
              pressElevation: 4,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.red.shade700, size: 16),
              const SizedBox(width: 4),
              const Text('Available', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 4),
              const Text('Your Booking', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '⭕ Approximate area',
            style: TextStyle(fontSize: 10, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Privacy Protection'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'For handyman safety and privacy:\n\n'
                '• Approximate locations shown (~1-2 km radius)\n'
                '• Circles show approximate service areas\n'
                '• Exact addresses shared only after booking confirmed\n'
                '• Live tracking only during active service\n'
                '• Location hidden after job complete\n\n'
                'This protects handymen from stalking and harassment while helping you find nearby help.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
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