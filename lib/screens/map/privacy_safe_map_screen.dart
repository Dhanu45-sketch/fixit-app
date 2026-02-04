// lib/screens/map/privacy_safe_map_screen.dart
// PRIVACY-PROTECTED Map Screen for Customers

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/location_privacy.dart';
import '../../utils/colors.dart';
import '../../services/auth_service.dart';
import '../handyman/handyman_detail_screen.dart';

class PrivacySafeMapScreen extends StatefulWidget {
  const PrivacySafeMapScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySafeMapScreen> createState() => _PrivacySafeMapScreenState();
}

class _PrivacySafeMapScreenState extends State<PrivacySafeMapScreen> {
  GoogleMapController? _mapController;
  final _authService = AuthService();

  Position? _currentPosition;
  bool _isLoading = true;
  String _selectedCategory = 'All';

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

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Nearby Handymen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showPrivacyInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _getCurrentLocation,
          child: Stack(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('handymanProfiles')
                    .where('work_status', isEqualTo: 'Available')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  return FutureBuilder<Set<String>>(
                    future: _getActiveBookingHandymen(),
                    builder: (context, activeSnapshot) {
                      final activeBookingHandymen = activeSnapshot.data ?? {};
                      final markers = <Marker>{};
                      final circles = <Circle>{};

                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        
                        if (data['location_sharing_enabled'] == false) continue;
                        if (data['show_on_map'] == false) continue;
                        
                        final GeoPoint? geoPoint = data['location'];
                        if (geoPoint == null) continue;

                        if (_selectedCategory != 'All' && data['category_name'] != _selectedCategory) continue;

                        final actualLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
                        final handymanId = doc.id;
                        final hasActiveBooking = activeBookingHandymen.contains(handymanId);
                        final bookingStatus = hasActiveBooking ? 'Confirmed' : 'None';

                        final privacyRadius = LocationPrivacy.getPrivacyRadius(bookingStatus, hasActiveBooking);
                        final fuzzedLocation = LocationPrivacy.fuzzLocation(actualLocation, radiusKm: privacyRadius);

                        markers.add(
                          Marker(
                            markerId: MarkerId(handymanId),
                            position: fuzzedLocation,
                            onTap: () => _showHandymanInfo(handymanId, data, fuzzedLocation),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              hasActiveBooking ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
                            ),
                            infoWindow: InfoWindow(
                              title: '${data['category_name'] ?? 'Handyman'}',
                              snippet: _currentPosition != null 
                                ? LocationPrivacy.formatDistance(
                                    LocationPrivacy.calculateApproximateDistance(
                                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                      fuzzedLocation,
                                    ),
                                  )
                                : null,
                            ),
                          ),
                        );

                        if (!hasActiveBooking) {
                          circles.add(
                            Circle(
                              circleId: CircleId('privacy_$handymanId'),
                              center: fuzzedLocation,
                              radius: privacyRadius * 1000,
                              fillColor: AppColors.primary.withOpacity(0.1),
                              strokeColor: AppColors.primary.withOpacity(0.3),
                              strokeWidth: 1,
                            ),
                          );
                        }
                      }

                      return GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition != null
                              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                              : const LatLng(7.2906, 80.6337),
                          zoom: 13,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        markers: markers,
                        circles: circles,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      );
                    },
                  );
                },
              ),

              // Category filter
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildCategoryFilter(),
              ),

              // Legend
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildLegend(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Set<String>> _getActiveBookingHandymen() async {
    final userId = _authService.currentUserId;
    if (userId == null) return {};

    final activeBookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('customer_id', isEqualTo: userId)
        .where('status', whereIn: ['Confirmed', 'In Progress'])
        .get();

    return activeBookingsSnapshot.docs
        .map((doc) => doc.data()['handyman_id'] as String)
        .toSet();
  }

  void _showHandymanInfo(String handymanId, Map<String, dynamic> data, LatLng location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: data['profile_image'] != null
                      ? NetworkImage(data['profile_image'])
                      : null,
                  child: data['profile_image'] == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['category_name'] ?? 'Handyman',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${(data['rating_avg'] ?? 0.0).toStringAsFixed(1)} (${data['review_count'] ?? 0} reviews)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Privacy notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Approximate location shown for privacy. Exact address shared only after booking confirmed.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on, color: AppColors.primary),
              title: const Text('Distance'),
              subtitle: Text(
                _currentPosition != null 
                  ? LocationPrivacy.formatDistance(
                      LocationPrivacy.calculateApproximateDistance(
                        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        location,
                      ),
                    )
                  : 'N/A',
              ),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_money, color: AppColors.primary),
              title: const Text('Hourly Rate'),
              subtitle: Text('Rs ${data['hourly_rate']?.toStringAsFixed(0) ?? 'N/A'}'),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
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
                ),
                child: const Text('View Profile & Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Plumbing', 'Electrical', 'Carpentry', 'Painting'];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
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
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 4),
              const Text('Available', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 4),
              const Text('Your Booking', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '⭕ = Approximate area',
            style: TextStyle(fontSize: 10, color: Colors.grey),
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
        content: const Text(
          'For handyman safety and privacy:\n\n'
              '• Approximate locations shown (~1-2 km radius)\n'
              '• Exact addresses only after booking confirmed\n'
              '• Live tracking only during active service\n'
              '• Location hidden after job complete\n\n'
              'This protects handymen from stalking and harassment while helping you find nearby help.',
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
}
