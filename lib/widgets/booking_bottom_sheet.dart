import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'custom_button.dart';

class BookingBottomSheet extends StatefulWidget {
  final String handymanId;
  final String handymanName;
  final double hourlyRate;
  final String serviceName;
  final bool isEmergency; // NEW: Emergency flag

  const BookingBottomSheet({
    Key? key,
    required this.handymanId,
    required this.handymanName,
    required this.hourlyRate,
    required this.serviceName,
    this.isEmergency = false, // NEW: Default to false
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
    // Calculate base rate from emergency rate if applicable
    final double baseRate = widget.isEmergency 
        ? widget.hourlyRate / (1 + FirestoreService.emergencySurchargeRate)
        : widget.hourlyRate;
    final double emergencySurcharge = widget.isEmergency 
        ? widget.hourlyRate - baseRate
        : 0.0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: widget.isEmergency 
            ? Border(top: BorderSide(color: Colors.red.shade700, width: 3))
            : null,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SizedBox(width: 40, child: Divider(thickness: 4))),
            const SizedBox(height: 20),
            
            // Header with Emergency Badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book ${widget.handymanName}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.serviceName, 
                        style: const TextStyle(color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
                if (widget.isEmergency)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade700.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emergency, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'EMERGENCY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),

            // Emergency Notice
            if (widget.isEmergency)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This handyman will prioritize your emergency request and arrive as soon as possible.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Date Selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_today, 
                color: widget.isEmergency ? Colors.red.shade700 : AppColors.primary,
              ),
              title: Text(DateFormat('EEEE, MMM dd').format(selectedDate)),
              trailing: TextButton(onPressed: _selectDate, child: const Text('Change')),
            ),

            // Time Selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.access_time, 
                color: widget.isEmergency ? Colors.red.shade700 : AppColors.primary,
              ),
              title: Text(selectedTime.format(context)),
              trailing: TextButton(onPressed: _selectTime, child: const Text('Change')),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: widget.isEmergency 
                    ? 'Describe your emergency (optional)...'
                    : 'Any specific instructions?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isEmergency ? Colors.red.shade700 : AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // Pricing Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isEmergency ? Colors.red.shade50 : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: widget.isEmergency 
                    ? Border.all(color: Colors.red.shade200)
                    : null,
              ),
              child: Column(
                children: [
                  if (widget.isEmergency) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Base Rate:',
                          style: TextStyle(color: AppColors.textLight, fontSize: 13),
                        ),
                        Text(
                          'Rs. ${baseRate.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emergency, color: Colors.red.shade700, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Emergency Surcharge (15%):',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '+ Rs. ${emergencySurcharge.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isEmergency ? 'Total Emergency Rate' : 'Est. Hourly Rate',
                        style: TextStyle(
                          color: widget.isEmergency ? Colors.red.shade900 : AppColors.textLight,
                          fontWeight: widget.isEmergency ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        'Rs. ${widget.hourlyRate.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: widget.isEmergency ? Colors.red.shade700 : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: widget.isEmergency ? 'Confirm Emergency Booking' : 'Confirm Booking',
              isLoading: _isLoading,
              onPressed: _handleBooking,
              backgroundColor: widget.isEmergency ? Colors.red.shade700 : AppColors.primary,
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
      builder: (context, child) {
        if (widget.isEmergency) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.red.shade700,
              ),
            ),
            child: child!,
          );
        }
        return child!;
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        if (widget.isEmergency) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.red.shade700,
              ),
            ),
            child: child!,
          );
        }
        return child!;
      },
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
        hourlyRate: widget.isEmergency 
            ? widget.hourlyRate / (1 + FirestoreService.emergencySurchargeRate)
            : widget.hourlyRate,
        notes: _notesController.text,
        isEmergency: widget.isEmergency,
      );

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEmergency 
                  ? '🚨 Emergency Booking Request Sent!'
                  : 'Booking Request Sent!',
            ),
            backgroundColor: widget.isEmergency ? Colors.red.shade700 : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
