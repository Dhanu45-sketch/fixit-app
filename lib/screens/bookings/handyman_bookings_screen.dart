// lib/screens/bookings/handyman_bookings_screen.dart
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
        title: const Text(
          'Job Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(
                all.where((b) => b.status == 'Pending').toList(),
                'requests',
              ),
              _buildBookingList(
                all.where((b) => b.status == 'Confirmed').toList(),
                'upcoming',
              ),
              _buildBookingList(
                all.where((b) => b.status == 'In Progress').toList(),
                'ongoing',
              ),
              _buildBookingList(
                all.where((b) =>
                b.status == 'Completed' ||
                    b.status == 'Cancelled' ||
                    b.status == 'Rejected').toList(),
                'history',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No $type found',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    booking.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (booking.isEmergency)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  booking.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, hh:mm a').format(booking.scheduledStartTime),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${booking.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Job Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (booking.isEmergency)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'URGENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Service Info
              _buildInfoRow(Icons.build, 'Service', booking.serviceName),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.person, 'Customer', booking.customerName),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on, 'Location', booking.address),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                'Scheduled',
                DateFormat('MMM dd, yyyy at hh:mm a').format(booking.scheduledStartTime),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.attach_money,
                'Amount',
                'Rs ${booking.totalPrice.toStringAsFixed(0)}',
              ),

              if (booking.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.note, 'Notes', booking.notes),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              if (booking.status == 'Pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        'Reject',
                        AppColors.error,
                            () => _updateBookingStatus(modalContext, booking, 'Rejected'),
                        true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        'Accept',
                        AppColors.success,
                            () => _updateBookingStatus(modalContext, booking, 'Confirmed'),
                        false,
                      ),
                    ),
                  ],
                ),
              ] else if (booking.status == 'Confirmed') ...[
                _actionButton(
                  'Start Job',
                  AppColors.primary,
                      () => _updateBookingStatus(modalContext, booking, 'In Progress'),
                  false,
                ),
              ] else if (booking.status == 'In Progress') ...[
                _actionButton(
                  'Complete Job',
                  AppColors.success,
                      () => _updateBookingStatus(modalContext, booking, 'Completed'),
                  false,
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }

  Widget _actionButton(String text, Color color, VoidCallback onTap, bool outlined) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      )
          : ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _updateBookingStatus(
      BuildContext modalContext,
      Booking booking,
      String status,
      ) async {
    // Close the modal first
    Navigator.pop(modalContext);

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    try {
      // Update booking status
      await _firestoreService.updateBookingStatus(booking.id, status);

      // Prepare notification
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

      // Send notification
      await _firestoreService.addNotification(
        recipientId: booking.customerId,
        title: title,
        message: message,
        type: type,
        bookingId: booking.id,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking updated to $status'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint("Error updating booking/notification: $e");
    }
  }
}