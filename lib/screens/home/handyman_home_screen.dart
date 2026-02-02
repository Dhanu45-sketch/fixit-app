import 'package:flutter/material.dart';
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

  Widget _buildStatsRow(Map<String, dynamic>? profile) {
    // Robustly handle missing or null data fields
    final String jobsDone = (profile?['jobs_completed'] ?? 0).toString();
    final String earnings = (profile?['total_earnings'] ?? 0.0).toStringAsFixed(0);
    final String rating = (profile?['rating_avg'] ?? 0.0).toStringAsFixed(1);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildStatCard(jobsDone, 'Jobs Done', Icons.check_circle, AppColors.success),
            const SizedBox(width: 12),
            _buildStatCard('Rs $earnings', 'Earned', Icons.account_balance_wallet, AppColors.primary),
            const SizedBox(width: 12),
            _buildStatCard(rating, 'Rating', Icons.star, Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection(Map<String, dynamic>? profile) {
    final bool active = profile?['accepts_emergencies'] ?? false;
    final double earnings = (profile?['emergency_earnings'] ?? 0.0).toDouble();
    final int count = profile?['emergency_jobs_count'] ?? 0;
    final double baseRate = (profile?['hourly_rate'] ?? 0.0).toDouble();
    final double emergencyRate = baseRate * 1.15;

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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: active ? Colors.red.shade700 : AppColors.textLight),
                const SizedBox(width: 12),
                const Expanded(child: Text('Emergency Services', style: TextStyle(fontWeight: FontWeight.bold))),
                Switch(
                  value: active,
                  onChanged: _toggleEmergencyServices,
                  activeColor: Colors.red.shade700,
                ),
              ],
            ),
            if (active) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(child: _buildEmergencyStatCard('Rs ${earnings.toStringAsFixed(0)}', 'Income', Icons.trending_up)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildEmergencyStatCard('$count', 'Jobs', Icons.bolt)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Emergency Rate: Rs ${emergencyRate.toStringAsFixed(0)}/hr (+15%)', 
                style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyStatCard(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.red.shade700, size: 18),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildBookingsStream() {
    if (_userId == null) return const SliverToBoxAdapter(child: SizedBox());

    return StreamBuilder<List<Booking>>(
      stream: _firestoreService.getHandymanBookings(_userId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(child: Center(child: Text('Error loading bookings')));
        }
        
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }

        final bookings = snapshot.data!.where((b) => 
          b.status == 'Confirmed' || b.status == 'Pending' || 
          b.status == 'On The Way' || b.status == 'In Progress'
        ).toList();

        if (bookings.isEmpty) {
          return _buildEmptyState();
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: booking),
          ),
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
                Text(booking.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(booking.status, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(booking.customerName, style: const TextStyle(color: AppColors.textLight)),
          ],
        ),
      ),
    );
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
