import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../profile/profile_screen.dart';
import '../bookings/handyman_bookings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../bookings/booking_detail_screen.dart';

class HandymanHomeScreen extends StatefulWidget {
  const HandymanHomeScreen({Key? key}) : super(key: key);

  @override
  State<HandymanHomeScreen> createState() => _HandymanHomeScreenState();
}

class _HandymanHomeScreenState extends State<HandymanHomeScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  int _selectedIndex = 0;
  bool _isAvailable = true;
  bool _acceptsEmergencies = false;
  String? _userId;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    _userId = _authService.currentUserId;
    if (_userId == null) return;

    try {
      final user = await _firestoreService.getUserProfile(_userId!);
      final handymanData = await _firestoreService.getHandymanProfileByUserId(_userId!);

      if (mounted) {
        setState(() {
          _userProfile = user;
          _isAvailable = handymanData?['work_status'] == 'Available';
          _acceptsEmergencies = handymanData?['accepts_emergencies'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error loading handyman profiles: $e");
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (_userId == null) return;

    setState(() => _isAvailable = value);

    try {
      await _firestoreService.updateHandymanProfile(_userId!, {
        'work_status': value ? 'Available' : 'Offline',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '✅ You are now available' : '⛔ You are now offline'),
            backgroundColor: value ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAvailable = !value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleEmergencyServices(bool value) async {
    if (_userId == null) return;

    setState(() => _acceptsEmergencies = value);

    try {
      await _firestoreService.updateHandymanProfile(_userId!, {
        'accepts_emergencies': value,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '🚨 Emergency services enabled - You\'ll receive priority jobs!'
                  : 'Emergency services disabled',
            ),
            backgroundColor: value ? Colors.red.shade700 : AppColors.textLight,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _acceptsEmergencies = !value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _getSelectedScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return const HandymanBookingsScreen();
      case 2: return const NotificationsScreen();
      case 3: return const ProfileScreen(isHandyman: true);
      default: return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    if (_userId == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _firestoreService.getHandymanProfileStream(_userId!),
      builder: (context, snapshot) {
        final handymanProfile = snapshot.data;
        
        return RefreshIndicator(
          onRefresh: _loadProfiles,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              _buildStatsRow(handymanProfile),
              _buildEmergencySection(handymanProfile),
              _buildSectionHeader('Upcoming Bookings', () => setState(() => _selectedIndex = 1)),
              _buildBookingsStream(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome Back! 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(_userProfile?['first_name'] ?? 'Handyman', style: const TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 20),
              _buildAvailabilitySwitch(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilitySwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(_isAvailable ? Icons.check_circle : Icons.cancel, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(child: Text('Online Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          Switch(
            value: _isAvailable,
            onChanged: _toggleAvailability,
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic>? handymanProfile) {
    if (_userId == null) return const SliverToBoxAdapter(child: SizedBox());

    // Master stream for all stats calculation from bookings and reviews
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('handyman_id', isEqualTo: _userId)
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, bookingSnapshot) {
        double totalIncome = 0.0;
        int jobsDone = 0;
        
        if (bookingSnapshot.hasData) {
          jobsDone = bookingSnapshot.data!.docs.length;
          for (var doc in bookingSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalIncome += (data['total_price'] ?? 0.0).toDouble();
          }
        }

        // Nested stream for ratings calculation
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('handyman_id', isEqualTo: _userId)
              .snapshots(),
          builder: (context, reviewSnapshot) {
            double avgRating = 0.0;
            if (reviewSnapshot.hasData && reviewSnapshot.data!.docs.isNotEmpty) {
              double totalRating = 0.0;
              for (var doc in reviewSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalRating += (data['rating'] ?? 0.0).toDouble();
              }
              avgRating = totalRating / reviewSnapshot.data!.docs.length;
            }

            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildStatCard('$jobsDone', 'Jobs Done', Icons.check_circle, AppColors.success),
                    const SizedBox(width: 12),
                    _buildStatCard('Rs ${totalIncome.toStringAsFixed(0)}', 'Income', Icons.account_balance_wallet, AppColors.primary),
                    const SizedBox(width: 12),
                    _buildStatCard(avgRating.toStringAsFixed(1), 'Rating', Icons.star, Colors.amber),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildEmergencySection(Map<String, dynamic>? handymanProfile) {
    if (_userId == null) return const SliverToBoxAdapter(child: SizedBox());

    final bool active = handymanProfile?['accepts_emergencies'] ?? false;
    final double baseRate = (handymanProfile?['hourly_rate'] ?? 0.0).toDouble();
    final double emergencyRate = baseRate * 1.15;

    // Calculate emergency stats locally from bookings stream
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('handyman_id', isEqualTo: _userId)
          .where('status', isEqualTo: 'Completed')
          .where('is_emergency', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        double emergencyIncome = 0.0;
        int emergencyJobsCount = 0;

        if (snapshot.hasData) {
          emergencyJobsCount = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            emergencyIncome += (data['total_price'] ?? 0.0).toDouble();
          }
        }

        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: active ? Colors.red.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? Colors.red.shade300 : Colors.grey.shade200,
                width: active ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(active ? 0.1 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: active ? Colors.red.shade100 : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.emergency,
                        color: active ? Colors.red.shade700 : AppColors.textLight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Emergency Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            active ? 'Active - Receiving priority jobs' : 'Earn 15% more with emergencies',
                            style: TextStyle(fontSize: 12, color: active ? Colors.red.shade700 : AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: active,
                      onChanged: _toggleEmergencyServices,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.red.shade700,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),
                if (active) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildEmergencyStatCard('Rs ${emergencyIncome.toStringAsFixed(0)}', 'Emergency Income', Icons.trending_up)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildEmergencyStatCard('$emergencyJobsCount', 'Emergency Jobs', Icons.bolt)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Standard Rate:', style: TextStyle(fontSize: 13)),
                            Text('Rs ${baseRate.toStringAsFixed(0)}/hr', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Emergency Rate:', style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                            Text('Rs ${emergencyRate.toStringAsFixed(0)}/hr (+15%)', style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildEmergencyStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, color: Colors.red.shade700, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBookingsStream() {
    if (_userId == null) return const SliverToBoxAdapter(child: SizedBox());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('handyman_id', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SliverToBoxAdapter(child: Center(child: Text('Error loading bookings')));
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));

        final bookings = snapshot.data!.docs
            .map((doc) => Booking.fromFirestore(doc))
            .where((b) => b.status == 'Confirmed' || b.status == 'Pending' || b.status == 'On The Way' || b.status == 'In Progress')
            .toList();

        if (bookings.isEmpty) return _buildEmptyState();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildBookingCard(bookings[index]),
            childCount: bookings.length > 3 ? 3 : bookings.length,
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: booking.isEmergency ? Border.all(color: Colors.red.shade300, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (booking.isEmergency) Icon(Icons.emergency, color: Colors.red.shade700, size: 20),
                    if (booking.isEmergency) const SizedBox(width: 8),
                    Text(booking.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(booking.status, style: TextStyle(color: _getStatusColor(booking.status), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(booking.customerName, style: const TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(child: Text(booking.address, style: const TextStyle(fontSize: 12, color: AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return AppColors.success;
      case 'pending': return Colors.orange;
      case 'on the way': return Colors.blue;
      case 'in progress': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _buildStatCard(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: onTap, child: const Text('See All')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('No upcoming jobs', style: TextStyle(color: AppColors.textLight))),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
