import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../profile/profile_screen.dart';
import '../bookings/handyman_bookings_screen.dart';
import '../notifications/notifications_screen.dart';

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
  String? _userId;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _handymanProfile;

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
          _handymanProfile = handymanData;
          // In your DB, the handymanProfile ID is the same as the userId
          _isAvailable = handymanData?['work_status'] == 'Available';
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
      case 3: return const ProfileScreen();
      default: return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadProfiles,
      child: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildStatsRow(),
          _buildSectionHeader('Upcoming Bookings', () => setState(() => _selectedIndex = 1)),
          _buildBookingsStream(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
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
              Text('Welcome Back! 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(_userProfile?['first_name'] ?? 'Handyman', style: const TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 20),
              _buildAvailabilitySwitch(),
            ],
          ),
        ),
      ),);
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

  Widget _buildStatsRow() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildStatCard('${_handymanProfile?['total_jobs_completed'] ?? 0}', 'Jobs Done', Icons.check_circle, AppColors.success),
            const SizedBox(width: 12),
            _buildStatCard('Rs ${(_handymanProfile?['hourly_rate'] ?? 0).toStringAsFixed(0)}', 'Rate/hr', Icons.payments, AppColors.primary),
            const SizedBox(width: 12),
            _buildStatCard('${(_handymanProfile?['rating_avg'] ?? 0.0).toStringAsFixed(1)}', 'Rating', Icons.star, Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsStream() {
    if (_userId == null) return const SliverToBoxAdapter(child: SizedBox());

    return StreamBuilder<List<Booking>>(
      stream: _firestoreService.getHandymanBookings(_userId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));

        final bookings = snapshot.data!.where((b) => b.status == 'Confirmed' || b.status == 'Pending').toList();

        if (bookings.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(booking.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(booking.status, style: TextStyle(color: booking.status == 'Confirmed' ? AppColors.success : Colors.orange, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(booking.customerName, style: const TextStyle(color: AppColors.textLight)),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildStatCard(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(child: Text('No upcoming jobs', style: TextStyle(color: AppColors.textLight))),
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
