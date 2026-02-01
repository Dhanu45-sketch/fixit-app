import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';

class CancelBookingSheet extends StatefulWidget {
  final Booking booking;
  final Function(String reason, String? notes) onConfirmCancel;

  const CancelBookingSheet({
    Key? key,
    required this.booking,
    required this.onConfirmCancel,
  }) : super(key: key);

  @override
  State<CancelBookingSheet> createState() => _CancelBookingSheetState();
}

class _CancelBookingSheetState extends State<CancelBookingSheet> {
  String? _selectedReason;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  final List<String> _cancellationReasons = [
    'Emergency came up',
    'Found another handyman',
    'Problem already fixed',
    'Changed my mind',
    'Schedule conflict',
    'Price too high',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _canCancel() {
    final now = DateTime.now();
    final scheduledTime = widget.booking.scheduledStartTime;
    final hoursUntilBooking = scheduledTime.difference(now).inHours;

    // Can cancel if more than 12 hours before booking
    return hoursUntilBooking > 12;
  }

  int _getHoursUntilBooking() {
    final now = DateTime.now();
    final scheduledTime = widget.booking.scheduledStartTime;
    return scheduledTime.difference(now).inHours;
  }

  Future<void> _handleCancel() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cancellation reason'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onConfirmCancel(_selectedReason!, _notesController.text.trim());
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = _canCancel();
    final hoursUntil = _getHoursUntilBooking();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Icon(
                  canCancel ? Icons.cancel_outlined : Icons.block,
                  color: canCancel ? AppColors.error : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    canCancel ? 'Cancel Booking' : 'Cannot Cancel',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Policy Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: canCancel ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: canCancel ? Colors.blue.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        canCancel ? Icons.info_outline : Icons.warning_amber,
                        color: canCancel ? Colors.blue.shade700 : Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cancellation Policy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: canCancel ? Colors.blue.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    canCancel
                        ? 'You can cancel this booking for FREE as it\'s more than 12 hours away.'
                        : 'Bookings cannot be cancelled within 12 hours of the scheduled time.',
                    style: TextStyle(
                      fontSize: 13,
                      color: canCancel ? Colors.blue.shade900 : Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: canCancel ? Colors.blue.shade700 : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Time until booking: $hoursUntil hours',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: canCancel ? Colors.blue.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!canCancel) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'What you can do:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Contact the handyman to reschedule',
                      style: TextStyle(fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Complete the service as scheduled',
                      style: TextStyle(fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Use the chat feature to communicate',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            if (canCancel) ...[
              const SizedBox(height: 24),
              const Text(
                'Why are you cancelling?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Cancellation Reasons
              ..._cancellationReasons.map((reason) {
                return RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),

              const SizedBox(height: 16),

              // Additional Notes
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Additional notes (optional)',
                  hintText: 'Let us know more details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.textLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel Booking',
                      onPressed: _handleCancel,
                      isLoading: _isLoading,
                      backgroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}