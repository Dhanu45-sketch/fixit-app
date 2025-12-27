import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/booking_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/colors.dart';
import 'package:intl/intl.dart';

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
              _buildBookingList(all.where((b) => b.status == 'Pending').toList(), 'requests'),
              _buildBookingList(all.where((b) => b.status == 'Confirmed').toList(), 'upcoming'),
              _buildBookingList(all.where((b) => b.status == 'In Progress').toList(), 'ongoing'),
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
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBookingDetails(booking),
          ),
        );
      },
    );
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job Details', style: Theme.of(context).textTheme.headlineSmall),
            if (booking.isEmergency)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('EMERGENCY REQUEST', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text('Location: ${booking.address}'),
            const SizedBox(height: 8),
            Text('Notes: ${booking.notes}'),
            const SizedBox(height: 24),

            if (booking.status == 'Pending') ...[
              Row(
                children: [
                  Expanded(child: _actionButton('Reject', AppColors.error, () => _update(booking, 'Rejected'), true)),
                  const SizedBox(width: 12),
                  Expanded(child: _actionButton('Accept', AppColors.success, () => _update(booking, 'Confirmed'), false)),
                ],
              )
            ] else if (booking.status == 'Confirmed') ...[
              _actionButton('Start Job', AppColors.primary, () => _update(booking, 'In Progress'), false)
            ] else if (booking.status == 'In Progress') ...[
              _actionButton('Complete Job', AppColors.success, () => _update(booking, 'Completed'), false)
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String text, Color color, VoidCallback onTap, bool outlined) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: color), child: Text(text))
          : ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: color), child: Text(text)),
    );
  }

  // UPDATED LOGIC TO INCLUDE NOTIFICATIONS
  Future<void> _update(Booking booking, String status) async {
    try {
      // 1. Update the status in Firestore
      await _firestoreService.updateBookingStatus(booking.id, status);

      // 2. Map status to a user-friendly notification message
      String title = "Booking Update";
      String message = "Your booking status is now $status";
      String type = "booking";

      if (status == 'Confirmed') {
        title = "Booking Accepted! ✅";
        message = "A handyman has accepted your ${booking.serviceName} request.";
      } else if (status == 'Rejected') {
        title = "Booking Rejected ❌";
        message = "The handyman cannot fulfill your request at this time.";
      } else if (status == 'In Progress') {
        title = "Job Started 🛠️";
        message = "The handyman has started the work at your location.";
      } else if (status == 'Completed') {
        title = "Job Completed! ⭐";
        message = "Please rate your experience with the service.";
        type = "payment";
      }

      // 3. Send the notification to the Customer (using customerId from booking)
      await _firestoreService.addNotification(
        recipientId: booking.customerId,
        title: title,
        message: message,
        type: type,
        bookingId: booking.id,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error updating booking/notification: $e");
    }
  }
}