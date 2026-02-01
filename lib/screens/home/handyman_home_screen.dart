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
  bool _acceptsEmergencies = false; // NEW: Emergency toggle state
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
          _isAvailable = handymanData?['work_status'] == 'Available';
          _acceptsEmergencies = handymanData?['accepts_emergencies'] ?? false; // NEW: Load emergency status
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

  // NEW: Toggle emergency services
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
    return RefreshIndicator(
      onRefresh: _loadProfiles,
      child: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildStatsRow(),
          _buildEmergencySection(), // NEW: Emergency services section
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

  Widget _buildStatsRow() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildStatCard('${_handymanProfile?['jobs_completed'] ?? 0}', 'Jobs Done', Icons.check_circle, AppColors.success),
            const SizedBox(width: 12),
            _buildStatCard('Rs ${(_handymanProfile?['hourly_rate'] ?? 0).toStringAsFixed(0)}', 'Rate/hr', Icons.payments, AppColors.primary),
            const SizedBox(width: 12),
            _buildStatCard('${(_handymanProfile?['rating_avg'] ?? 0.0).toStringAsFixed(1)}', 'Rating', Icons.star, Colors.amber),
          ],
        ),
      ),
    );
  }

  // NEW: Emergency Services Section
  Widget _buildEmergencySection() {
    final double emergencyEarnings = (_handymanProfile?['emergency_earnings'] ?? 0.0).toDouble();
    final int emergencyJobsCount = _handymanProfile?['emergency_jobs_count'] ?? 0;
    final double baseRate = (_handymanProfile?['hourly_rate'] ?? 0.0).toDouble();
    final double emergencyRate = FirestoreService.calculateEmergencyPrice(baseRate);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _acceptsEmergencies ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _acceptsEmergencies ? Colors.red.shade300 : Colors.grey.shade200,
            width: _acceptsEmergencies ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_acceptsEmergencies ? 0.1 : 0.05),
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
                    color: _acceptsEmergencies ? Colors.red.shade100 : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.emergency,
                    color: _acceptsEmergencies ? Colors.red.shade700 : AppColors.textLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Services',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _acceptsEmergencies ? 'Active - Receiving priority jobs' : 'Earn 15% more with emergencies',
                        style: TextStyle(
                          fontSize: 12,
                          color: _acceptsEmergencies ? Colors.red.shade700 : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _acceptsEmergencies,
                  onChanged: _toggleEmergencyServices,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.red.shade700,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ],
            ),

            if (_acceptsEmergencies) ...[
              const Divider(height: 24),

              // Emergency Earnings Stats
              Row(
                children: [
                  Expanded(
                    child: _buildEmergencyStatCard(
                      'Rs ${emergencyEarnings.toStringAsFixed(0)}',
                      'Emergency Earnings',
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEmergencyStatCard(
                      '$emergencyJobsCount',
                      'Emergency Jobs',
                      Icons.bolt,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Rate comparison
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
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
                        Text(
                          'Emergency Rate:',
                          style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Rs ${emergencyRate.toStringAsFixed(0)}/hr (+15%)',
                          style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
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

  Widget _buildEmergencyStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.red.shade700, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
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
        border: booking.isEmergency
            ? Border.all(color: Colors.red.shade300, width: 2)
            : null,
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
                  if (booking.isEmergency)
                    Icon(Icons.emergency, color: Colors.red.shade700, size: 20),
                  if (booking.isEmergency) const SizedBox(width: 8),
                  Text(booking.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                booking.status,
                style: TextStyle(
                  color: booking.status == 'Confirmed' ? AppColors.success : Colors.orange,
                  fontSize: 12,
                ),
              ),
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