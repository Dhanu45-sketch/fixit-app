// lib/widgets/booking_card.dart
// FIXED VERSION - Added proper handling for review feature
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../utils/colors.dart';
import 'package:intl/intl.dart';
import '../widgets/review_bottom_sheet.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const BookingCard({
    Key? key,
    required this.booking,
    required this.onTap,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.green;
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

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd MMM yyyy').format(booking.scheduledStartTime);
    final String formattedTime = DateFormat('hh:mm a').format(booking.scheduledStartTime);

    // FIX: Check if booking has hasReview property, otherwise default to false
    // This prevents runtime errors if the property is missing
    final bool hasReview = booking.hasReview ?? false;
    final bool canReview = booking.status == 'Completed' && !hasReview;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (booking.isEmergency)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.bolt, color: Colors.red, size: 20),
                        ),
                      Expanded(
                        child: Text(
                          booking.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textLight),
                const SizedBox(width: 8),
                Text(
                  booking.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (booking.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.notes,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
                Text(
                  'Rs ${booking.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            // Review Button for Completed Jobs
            if (canReview) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (sheetContext) => ReviewBottomSheet(
                        handymanId: booking.handymanId,
                        handymanName: 'Handyman', // You can fetch this if needed
                        bookingId: booking.id,
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Rate this Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // Show if already reviewed
            if (hasReview) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'You reviewed this service',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
}