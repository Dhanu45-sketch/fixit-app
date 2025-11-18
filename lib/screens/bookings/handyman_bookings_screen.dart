// ==========================================
// FILE: lib/screens/bookings/handyman_bookings_screen.dart
// Complete implementation for handymen to manage their bookings
// ==========================================
import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../widgets/booking_card.dart';
import '../../utils/colors.dart';

class HandymanBookingsScreen extends StatefulWidget {
  const HandymanBookingsScreen({Key? key}) : super(key: key);

  @override
  State<HandymanBookingsScreen> createState() => _HandymanBookingsScreenState();
}

class _HandymanBookingsScreenState extends State<HandymanBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data - Replace with API calls
  final List<Booking> _upcomingBookings = [
    Booking(
      id: 1,
      customerName: 'Shanika Weerasinghe',
      jobDescription: 'Deep clean apartment - 3 bedrooms',
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
    Booking(
      id: 3,
      customerName: 'Nimal Perera',
      jobDescription: 'Fix kitchen sink leak',
      location: 'Peradeniya Rd, Kandy',
      scheduledStartTime: DateTime.now().add(const Duration(days: 2)),
      estimatedEndTime: DateTime.now().add(const Duration(days: 2, hours: 2)),
      status: 'Confirmed',
      amount: 1500,
    ),
  ];

  final List<Booking> _ongoingBookings = [
    Booking(
      id: 4,
      customerName: 'Kumari Silva',
      jobDescription: 'Electrical wiring repair',
      location: 'Ampitiya Rd, Kandy',
      scheduledStartTime: DateTime.now().subtract(const Duration(hours: 1)),
      estimatedEndTime: DateTime.now().add(const Duration(hours: 2)),
      status: 'In Progress',
      amount: 2500,
    ),
  ];

  final List<Booking> _completedBookings = [
    Booking(
      id: 5,
      customerName: 'Sunil Fernando',
      jobDescription: 'AC maintenance and cleaning',
      location: 'Temple St, Kandy',
      scheduledStartTime: DateTime.now().subtract(const Duration(days: 2)),
      estimatedEndTime: DateTime.now().subtract(const Duration(days: 2, hours: -3)),
      status: 'Completed',
      amount: 2000,
    ),
    Booking(
      id: 6,
      customerName: 'Chamari Jayasinghe',
      jobDescription: 'Furniture assembly',
      location: 'Katugastota Rd, Kandy',
      scheduledStartTime: DateTime.now().subtract(const Duration(days: 5)),
      estimatedEndTime: DateTime.now().subtract(const Duration(days: 5, hours: -2)),
      status: 'Completed',
      amount: 1800,
    ),
    Booking(
      id: 7,
      customerName: 'Ruwan Wickramasinghe',
      jobDescription: 'Garden landscaping',
      location: 'Kengalla Rd, Kandy',
      scheduledStartTime: DateTime.now().subtract(const Duration(days: 7)),
      estimatedEndTime: DateTime.now().subtract(const Duration(days: 7, hours: -5)),
      status: 'Completed',
      amount: 4500,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Jobs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Upcoming'),
                  if (_upcomingBookings.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${_upcomingBookings.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ongoing'),
                  if (_ongoingBookings.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${_ongoingBookings.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(_upcomingBookings, 'upcoming'),
          _buildBookingList(_ongoingBookings, 'ongoing'),
          _buildBookingList(_completedBookings, 'completed'),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String type) {
    if (bookings.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement API refresh
        await Future.delayed(const Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookings refreshed'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return BookingCard(
            booking: bookings[index],
            onTap: () => _showBookingDetails(bookings[index], type),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'upcoming':
        message = 'No upcoming bookings';
        subtitle = 'Accepted jobs will appear here';
        icon = Icons.calendar_today_outlined;
        break;
      case 'ongoing':
        message = 'No ongoing jobs';
        subtitle = 'Jobs in progress will appear here';
        icon = Icons.work_outline;
        break;
      case 'completed':
        message = 'No completed jobs yet';
        subtitle = 'Your work history will appear here';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No bookings';
        subtitle = 'Pull down to refresh';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textLight.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Booking booking, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBookingDetailsSheet(booking, type),
    );
  }

  Widget _buildBookingDetailsSheet(Booking booking, String type) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  _buildStatusBadge(booking.status),
                  const SizedBox(height: 16),

                  // Customer info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          booking.customerName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: AppColors.textLight),
                                SizedBox(width: 4),
                                Text(
                                  '+94 77 123 4567',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, color: AppColors.primary),
                        onPressed: () {
                          // TODO: Make phone call
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Calling customer...')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.message, color: AppColors.primary),
                        onPressed: () {
                          // TODO: Open chat
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening chat...')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Job description
                  const Text(
                    'Job Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.jobDescription,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    booking.location,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    booking.scheduledStartTime != null
                        ? '${booking.scheduledStartTime!.day}/${booking.scheduledStartTime!.month}/${booking.scheduledStartTime!.year}'
                        : 'Date not set',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.access_time,
                    'Time',
                    booking.scheduledStartTime != null && booking.estimatedEndTime != null
                        ? '${_formatTime(booking.scheduledStartTime!)} - ${_formatTime(booking.estimatedEndTime!)}'
                        : 'Time not set',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.attach_money,
                    'Amount',
                    'Rs ${booking.amount.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  if (type == 'upcoming')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _startJob(booking);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Start Job',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _cancelJob(booking);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel Job',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (type == 'ongoing')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _completeJob(booking);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Mark as Complete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppColors.success;
        break;
      case 'in progress':
        color = AppColors.primary;
        break;
      case 'completed':
        color = AppColors.success;
        break;
      default:
        color = AppColors.textLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
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
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
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

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _startJob(Booking booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started job for ${booking.customerName}'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Update booking status in backend
  }

  void _completeJob(Booking booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job completed for ${booking.customerName}'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Update booking status and move to completed
  }

  void _cancelJob(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Job?'),
        content: const Text(
          'Are you sure you want to cancel this job? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Job cancelled'),
                  backgroundColor: AppColors.error,
                ),
              );
              // TODO: Cancel booking in backend
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}