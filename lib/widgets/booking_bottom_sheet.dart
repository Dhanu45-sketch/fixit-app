// lib/widgets/booking_bottom_sheet.dart
// UPDATED - Using ServiceAddressPicker widget

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'custom_button.dart';
import 'service_address_picker.dart';  // ✅ NEW IMPORT

class BookingBottomSheet extends StatefulWidget {
  final String handymanId;
  final String handymanName;
  final double hourlyRate;
  final String serviceName;
  final bool isEmergency;

  const BookingBottomSheet({
    Key? key,
    required this.handymanId,
    required this.handymanName,
    required this.hourlyRate,
    required this.serviceName,
    this.isEmergency = false,
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

  // ✅ NEW: Location data from picker
  String _serviceAddress = '';
  LatLng? _serviceLocation;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

            // Header
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
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emergency, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'EMERGENCY',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),

            // ✅ NEW: Service Address Picker Widget
            ServiceAddressPicker(
              onAddressSelected: (address, location) {
                setState(() {
                  _serviceAddress = address;
                  _serviceLocation = location;
                });
              },
            ),

            const SizedBox(height: 16),

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

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: widget.isEmergency ? 'Describe your emergency...' : 'Specific instructions?',
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
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Rate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isEmergency ? Colors.red.shade900 : AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Rs. ${widget.hourlyRate.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: widget.isEmergency ? Colors.red.shade700 : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: widget.isEmergency ? 'Request Emergency Service' : 'Confirm Booking',
              isLoading: _isLoading,
              onPressed: _handleBooking,
              backgroundColor: widget.isEmergency ? Colors.red.shade700 : null,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

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
    // ✅ NEW: Validation for address
    if (_serviceAddress.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter your service address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    try {
      await _firestoreService.createBooking(
        handymanId: widget.handymanId,
        serviceName: widget.serviceName,
        scheduledTime: scheduledDateTime,
        hourlyRate: widget.hourlyRate,
        notes: _notesController.text.trim(),
        address: _serviceAddress.trim(),  // ✅ Use from picker
        isEmergency: widget.isEmergency,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEmergency
                  ? '🚨 Emergency Request Sent!'
                  : '✅ Booking Request Sent!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}