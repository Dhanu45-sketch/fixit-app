import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'custom_button.dart';

class BookingBottomSheet extends StatefulWidget {
  final String handymanId;
  final String handymanName;
  final double hourlyRate;
  final String serviceName; // Standardized name

  const BookingBottomSheet({
    Key? key,
    required this.handymanId,
    required this.handymanName,
    required this.hourlyRate,
    required this.serviceName,
  }) : super(key: key);

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _notesController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SizedBox(width: 40, child: Divider(thickness: 4))),
            const SizedBox(height: 20),
            Text('Book ${widget.handymanName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(widget.serviceName, style: const TextStyle(color: AppColors.textLight)),
            const Divider(height: 32),

            // Date Selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: Text(DateFormat('EEEE, MMM dd').format(selectedDate)),
              trailing: TextButton(onPressed: _selectDate, child: const Text('Change')),
            ),

            // Time Selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time, color: AppColors.primary),
              title: Text(selectedTime.format(context)),
              trailing: TextButton(onPressed: _selectTime, child: const Text('Change')),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Any specific instructions?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Est. Hourly Rate', style: TextStyle(color: AppColors.textLight)),
                Text('Rs. ${widget.hourlyRate.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),

            const SizedBox(height: 24),

              CustomButton(
                text: 'Confirm Booking',
                isLoading: _isLoading, // Use the boolean here
                onPressed: _handleBooking, // Pass the function reference directly
              ),


            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Logic Methods ---

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _handleBooking() async {
    setState(() => _isLoading = true);

    final scheduledDateTime = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedTime.hour, selectedTime.minute,
    );

    try {
      await _firestoreService.createBooking(
        handymanId: widget.handymanId,
        serviceName: widget.serviceName,
        scheduledTime: scheduledDateTime,
        hourlyRate: widget.hourlyRate,
        notes: _notesController.text,
      );

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking Request Sent!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}