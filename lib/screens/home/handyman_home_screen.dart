// ==========================================
// FILE: lib/screens/home/handyman_home_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import '../../models/job_request_model.dart';
import '../../models/booking_model.dart';
import '../../widgets/job_request_card.dart';
import '../../widgets/booking_card.dart';
import '../../utils/colors.dart';
import 'package:fixit_app/screens/home/customer_home_screen.dart';
import 'package:fixit_app/screens/home/handyman_home_screen.dart';
import '../profile/profile_screen.dart';

import '../../widgets/job_request_details_bottom_sheet.dart';

class HandymanHomeScreen extends StatefulWidget {
  const HandymanHomeScreen({Key? key}) : super(key: key);

  @override
  State<HandymanHomeScreen> createState() => _HandymanHomeScreenState();
}

class _HandymanHomeScreenState extends State<HandymanHomeScreen> {
  int _selectedIndex = 0;
  bool _isAvailable = true;

  // Mock data - Replace with API calls
  final List<JobRequest> _jobRequests = [
    JobRequest(
      id: 1,
      customerName: 'Amal Perera',
      description: 'Fix leaking tap in kitchen. Water is dripping constantly.',
      jobType: 'Plumbing',
      location: 'Peradeniya Rd, Kandy',
      isEmergency: true,
      createdTime: DateTime.now().subtract(const Duration(hours: 2)),
      deadline: DateTime.now().add(const Duration(hours: 6)),
      status: 'Open',
      offeredPrice: 1500,
    ),
    JobRequest(
      id: 2,
      customerName: 'Kamal Fernando',
      description: 'Repair broken chair leg, need wood work',
      jobType: 'Carpentry',
      location: 'Temple St, Kandy',
      isEmergency: false,
      createdTime: DateTime.now().subtract(const Duration(hours: 5)),
      deadline: DateTime.now().add(const Duration(days: 2)),
      status: 'Open',
      offeredPrice: 1200,
    ),
    JobRequest(
      id: 3,
      customerName: 'Chathura Dissanayake',
      description: 'Install new light fixtures in living room',
      jobType: 'Electrical',
      location: 'Ampitiya Rd, Kandy',
      isEmergency: false,
      createdTime: DateTime.now().subtract(const Duration(hours: 8)),
      deadline: DateTime.now().add(const Duration(days: 3)),
      status: 'Open',
      offeredPrice: 2000,
    ),
  ];

  final List<Booking> _upcomingBookings = [
    Booking(
      id: 1,
      customerName: 'Shanika Weerasinghe',
      jobDescription: 'Deep clean apartment',
      location: 'Kundasale Rd, Kandy',
      scheduledStartTime: DateTime.now().add(const Duration(hours: 3)),
      estimatedEndTime: DateTime.now().add(const Duration(hours: 6)),
      status: 'Confirmed',
      amount: 1200,
    ),
    Booking(
      id: 2,
      customerName: 'Harsha Bandara',
      jobDescription: 'Paint living room walls',
      location: 'Tennekumbura Rd, Kandy',
      scheduledStartTime: DateTime.now().add(const Duration(days: 1)),
      estimatedEndTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
      status: 'Confirmed',
      amount: 3500,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildHomeTab()
            : _selectedIndex == 1
            ? _buildJobsTab()
            : _selectedIndex == 2
            ? _buildMessagesTab()
            : _buildProfileTab(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back! 👋',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ready to help customers today?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Availability Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAvailable ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Work Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: (value) {
                          setState(() => _isAvailable = value);
                        },
                        activeColor: AppColors.success,
                        inactiveThumbColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStatCard(
                  '15',
                  'Jobs Done',
                  Icons.check_circle,
                  AppColors.success,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Rs 45,000',
                  'This Month',
                  Icons.attach_money,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  '4.8',
                  'Rating',
                  Icons.star,
                  AppColors.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upcoming Bookings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedIndex = 1);
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _upcomingBookings.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No upcoming bookings',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _upcomingBookings.length > 2 ? 2 : _upcomingBookings.length,
            itemBuilder: (context, index) {
              return BookingCard(
                booking: _upcomingBookings[index],
                onTap: () {
                  // Navigate to booking details
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // New Job Requests
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Job Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_jobRequests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _jobRequests.length > 3 ? 3 : _jobRequests.length,
            itemBuilder: (context, index) {
              return JobRequestCard(
                jobRequest: _jobRequests[index],
                onTap: () {
                  _showJobRequestDetails(context, _jobRequests[index]);
                },
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildJobsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'My Jobs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming soon...',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Messages',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming soon...',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming soon...',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        backgroundColor: Colors.transparent,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showJobRequestDetails(BuildContext context, JobRequest jobRequest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => JobRequestDetailsBottomSheet(jobRequest: jobRequest),
    );
  }
}


/*


// ==========================================
// FILE: lib/screens/home/handyman_home_screen.dart
// FINAL COMPLETE VERSION WITH ALL FEATURES
// ==========================================
import 'package:flutter/material.dart';
import '../../models/job_request_model.dart';
import '../../models/booking_model.dart';
import '../../widgets/job_request_card.dart';
import '../../widgets/booking_card.dart';
import '../../utils/colors.dart';
import '../profile/profile_screen.dart';
import '../bookings/handyman_bookings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../search/handyman_search_screen.dart';
import '../../widgets/job_request_details_bottom_sheet.dart';

class HandymanHomeScreen extends StatefulWidget {
  const HandymanHomeScreen({Key? key}) : super(key: key);

  @override
  State<HandymanHomeScreen> createState() => _HandymanHomeScreenState();
}

class _HandymanHomeScreenState extends State<HandymanHomeScreen> {
  int _selectedIndex = 0;
  bool _isAvailable = true;

  // Mock notification count
  int _unreadNotificationCount = 5;
  int _unreadMessagesCount = 2;

  // Mock data - Replace with API calls
  final List<JobRequest> _jobRequests = [
    JobRequest(
      id: 1,
      customerName: 'Amal Perera',
      description: 'Fix leaking tap in kitchen. Water is dripping constantly.',
      jobType: 'Plumbing',
      location: 'Peradeniya Rd, Kandy',
      isEmergency: true,
      createdTime: DateTime.now().subtract(const Duration(hours: 2)),
      deadline: DateTime.now().add(const Duration(hours: 6)),
      status: 'Open',
      offeredPrice: 1500,
    ),
    JobRequest(
      id: 2,
      customerName: 'Kamal Fernando',
      description: 'Repair broken chair leg, need wood work',
      jobType: 'Carpentry',
      location: 'Temple St, Kandy',
      isEmergency: false,
      createdTime: DateTime.now().subtract(const Duration(hours: 5)),
      deadline: DateTime.now().add(const Duration(days: 2)),
      status: 'Open',
      offeredPrice: 1200,
    ),
    JobRequest(
      id: 3,
      customerName: 'Chathura Dissanayake',
      description: 'Install new light fixtures in living room',
      jobType: 'Electrical',
      location: 'Ampitiya Rd, Kandy',
      isEmergency: false,
      createdTime: DateTime.now().subtract(const Duration(hours: 8)),
      deadline: DateTime.now().add(const Duration(days: 3)),
      status: 'Open',
      offeredPrice: 2000,
    ),
  ];

  final List<Booking> _upcomingBookings = [
    Booking(
      id: 1,
      customerName: 'Shanika Weerasinghe',
      jobDescription: 'Deep clean apartment',
      location: 'Kundasale Rd, Kandy',
      scheduledStartTime: DateTime.now().add(const Duration(hours: 3)),
      estimatedEndTime: DateTime.now().add(const Duration(hours: 6)),
      status: 'Confirmed',
      amount: 1200,
    ),
    Booking(
      id: 2,
      customerName: 'Harsha Bandara',
      jobDescription: 'Paint living room walls',
      location: 'Tennekumbura Rd, Kandy',
      scheduledStartTime: DateTime.now().add(const Duration(days: 1)),
      estimatedEndTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
      status: 'Confirmed',
      amount: 3500,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildHomeTab()
            : _selectedIndex == 1
            ? const HandymanBookingsScreen()
            : _selectedIndex == 2
            ? const NotificationsScreen()
            : const ProfileScreen(isHandyman: true),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back! 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ready to help customers today?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HandymanSearchScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() => _selectedIndex = 2);
                                },
                              ),
                            ),
                            if (_unreadNotificationCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$_unreadNotificationCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Availability Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAvailable ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Work Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: (value) {
                          setState(() => _isAvailable = value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? '✅ You are now available for jobs'
                                    : '⛔ You are now unavailable',
                              ),
                              backgroundColor: value
                                  ? AppColors.success
                                  : AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        activeColor: AppColors.success,
                        inactiveThumbColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStatCard(
                  '15',
                  'Jobs Done',
                  Icons.check_circle,
                  AppColors.success,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Rs 45,000',
                  'This Month',
                  Icons.attach_money,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  '4.8',
                  'Rating',
                  Icons.star,
                  AppColors.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upcoming Bookings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedIndex = 1);
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _upcomingBookings.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No upcoming bookings',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _upcomingBookings.length > 2 ? 2 : _upcomingBookings.length,
            itemBuilder: (context, index) {
              return BookingCard(
                booking: _upcomingBookings[index],
                onTap: () {
                  // Navigate to booking details
                  setState(() => _selectedIndex = 1);
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // New Job Requests
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Job Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_jobRequests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _jobRequests.length > 3 ? 3 : _jobRequests.length,
            itemBuilder: (context, index) {
              return JobRequestCard(
                jobRequest: _jobRequests[index],
                onTap: () {
                  _showJobRequestDetails(context, _jobRequests[index]);
                },
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        backgroundColor: Colors.transparent,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showJobRequestDetails(BuildContext context, JobRequest jobRequest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => JobRequestDetailsBottomSheet(jobRequest: jobRequest),
    );
  }
}*/
