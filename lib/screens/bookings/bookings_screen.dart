import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/booking_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/colors.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/loading_indicator.dart';
import 'booking_detail_screen.dart'; // Import the detail screen

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: const Center(child: Text('Please login to view bookings')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _firestoreService.getCustomerBookings(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allBookings = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(
                allBookings.where((b) => ['Pending', 'Confirmed', 'Accepted'].contains(b.status)).toList(),
                'No upcoming bookings',
                'Your new service requests will appear here.',
              ),
              _buildBookingList(
                allBookings.where((b) => b.status == 'In Progress').toList(),
                'No active bookings',
                'Jobs currently being worked on will show here.',
              ),
              _buildBookingList(
                allBookings.where((b) => b.status == 'Completed').toList(),
                'No past bookings',
                'Your finished jobs will be listed here.',
              ),
              _buildBookingList(
                allBookings.where((b) => ['Cancelled', 'Rejected'].contains(b.status)).toList(),
                'No cancelled bookings',
                'Cancelled or rejected requests are stored here.',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String emptyTitle, String emptySubtitle) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(emptyTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(emptySubtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          onTap: () {
            // Navigate to detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailScreen(booking: booking),
              ),
            );
          },
        );
      },
    );
  }
}
