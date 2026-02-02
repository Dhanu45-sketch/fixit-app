import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/booking_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/colors.dart';
import 'package:intl/intl.dart';
import 'booking_detail_screen.dart';

class HandymanBookingsScreen extends StatefulWidget {
  const HandymanBookingsScreen({Key? key}) : super(key: key);

  @override
  State<HandymanBookingsScreen> createState() => _HandymanBookingsScreenState();
}

class _HandymanBookingsScreenState extends State<HandymanBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Job Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _firestoreService.getHandymanBookings(currentUserId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final all = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: [
              // Requests: New bookings
              _buildBookingList(all.where((b) => b.status == 'Pending').toList(), 'requests'),
              
              // Upcoming: Confirmed or Accepted bookings
              _buildBookingList(all.where((b) => b.status == 'Confirmed' || b.status == 'Accepted').toList(), 'upcoming'),
              
              // Ongoing: Currently traveling or working
              _buildBookingList(all.where((b) => b.status == 'On The Way' || b.status == 'In Progress').toList(), 'ongoing'),
              
              // History: Finished or closed bookings
              _buildBookingList(all.where((b) => b.status == 'Completed' || b.status == 'Cancelled' || b.status == 'Rejected').toList(), 'history'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String type) {
    if (bookings.isEmpty) return Center(child: Text('No $type found'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (booking.isEmergency)
                  const Icon(Icons.bolt, color: Colors.red, size: 20),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.serviceName),
                const SizedBox(height: 4),
                Text(DateFormat('MMM dd, hh:mm a').format(booking.scheduledStartTime)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(booking: booking),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.green;
      case 'on the way':
        return Colors.blueAccent;
      case 'in progress':
        return AppColors.primary;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.textLight;
    }
  }
}
