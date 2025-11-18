// ==========================================
// FILE: lib/screens/bookings/bookings_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import '../../models/booking_detail_model.dart';
import '../../utils/colors.dart';
import 'booking_detail_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data - Replace with API calls
  final List<BookingDetail> _allBookings = [
    BookingDetail(
      id: 1,
      handymanName: 'Samantha Silva',
      serviceType: 'Plumbing',
      description: 'Fix leaking tap in kitchen',
      location: 'Peradeniya Rd, Kandy',
      scheduledDate: DateTime.now().add(const Duration(days: 2)),
      scheduledTime: '10:00 AM',
      estimatedHours: 2,
      amount: 3000,
      status: 'Confirmed',
      isEmergency: false,
    ),
    BookingDetail(
      id: 2,
      handymanName: 'Nimal Jayasinghe',
      serviceType: 'Electrical',
      description: 'Install new light fixtures',
      location: 'Temple St, Kandy',
      scheduledDate: DateTime.now().add(const Duration(days: 5)),
      scheduledTime: '02:00 PM',
      estimatedHours: 3,
      amount: 6000,
      status: 'Pending',
      isEmergency: false,
    ),
    BookingDetail(
      id: 3,
      handymanName: 'Ruwan Ekanayake',
      serviceType: 'Carpentry',
      description: 'Repair broken cabinet door',
      location: 'Ampitiya Rd, Kandy',
      scheduledDate: DateTime.now().subtract(const Duration(days: 3)),
      scheduledTime: '09:00 AM',
      estimatedHours: 2,
      amount: 3600,
      status: 'Completed',
      isEmergency: false,
      completedDate: DateTime.now().subtract(const Duration(days: 3)),
      rating: 4.5,
    ),
    BookingDetail(
      id: 4,
      handymanName: 'Pasan Ranasinghe',
      serviceType: 'Plumbing',
      description: 'Emergency pipe burst repair',
      location: 'Lake Rd, Kandy',
      scheduledDate: DateTime.now(),
      scheduledTime: '11:00 AM',
      estimatedHours: 1,
      amount: 2500,
      status: 'In Progress',
      isEmergency: true,
    ),
    BookingDetail(
      id: 5,
      handymanName: 'Harsha Bandara',
      serviceType: 'Painting',
      description: 'Paint living room walls',
      location: 'Tennekumbura Rd, Kandy',
      scheduledDate: DateTime.now().subtract(const Duration(days: 10)),
      scheduledTime: '08:00 AM',
      estimatedHours: 8,
      amount: 15000,
      status: 'Cancelled',
      isEmergency: false,
    ),
  ];

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

  List<BookingDetail> _getFilteredBookings(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'upcoming':
        return _allBookings.where((b) =>
        (b.status == 'Confirmed' || b.status == 'Pending') &&
            b.scheduledDate.isAfter(now)
        ).toList();
      case 'active':
        return _allBookings.where((b) =>
        b.status == 'In Progress' || b.status == 'Confirmed'
        ).toList();
      case 'completed':
        return _allBookings.where((b) => b.status == 'Completed').toList();
      case 'cancelled':
        return _allBookings.where((b) => b.status == 'Cancelled').toList();
      default:
        return _allBookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(_getFilteredBookings('upcoming')),
          _buildBookingList(_getFilteredBookings('active')),
          _buildBookingList(_getFilteredBookings('completed')),
          _buildBookingList(_getFilteredBookings('cancelled')),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<BookingDetail> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: AppColors.textLight.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your bookings will appear here',
              style: TextStyle(
                fontSize: 14,
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
        return _buildBookingCard(bookings[index]);
      },
    );
  }

  Widget _buildBookingCard(BookingDetail booking) {
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: booking.isEmergency
              ? Border.all(color: AppColors.error, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    booking.handymanName[0],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.handymanName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        booking.serviceType,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  booking.scheduledTime,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
                const Spacer(),
                if (booking.isEmergency)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        booking.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rs ${booking.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (booking.status == 'Completed' && booking.rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < booking.rating!.floor()
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    booking.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppColors.success;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'in progress':
        color = AppColors.primary;
        break;
      case 'completed':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
