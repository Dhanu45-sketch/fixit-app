// ==========================================
// FILE: lib/widgets/booking_bottom_sheet.dart
// COMPLETE VERSION (was cut off before)
// ==========================================
import 'package:flutter/material.dart';
import '../models/handyman_model.dart';
import '../utils/colors.dart';
import 'custom_button.dart';

class BookingBottomSheet extends StatefulWidget {
  final Handyman handyman;

  const BookingBottomSheet({
    Key? key,
    required this.handyman,
  }) : super(key: key);

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isEmergency = false;
  int _estimatedHours = 2;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  double get _totalCost {
    return widget.handyman.hourlyRate * _estimatedHours;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Book Service',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Describe the job',
                  hintText: 'Tell us what needs to be done...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeCard(
                      'Date',
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Select Date',
                      Icons.calendar_today,
                          () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTimeCard(
                      'Time',
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Select Time',
                      Icons.access_time,
                          () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Estimated Duration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_estimatedHours > 1) {
                        setState(() => _estimatedHours--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: Text(
                      '$_estimatedHours hour${_estimatedHours > 1 ? 's' : ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _estimatedHours++);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isEmergency
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: _isEmergency ? AppColors.error : AppColors.textLight,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Emergency Service',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isEmergency,
                      onChanged: (value) {
                        setState(() => _isEmergency = value);
                      },
                      activeColor: AppColors.error,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hourly Rate:'),
                        Text('Rs ${widget.handyman.hourlyRate.toStringAsFixed(0)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration:'),
                        Text('$_estimatedHours hour${_estimatedHours > 1 ? 's' : ''}'),
                      ],
                    ),
                    if (_isEmergency)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Emergency Fee:'),
                          Text('Rs 500'),
                        ],
                      ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs ${(_totalCost + (_isEmergency ? 500 : 0)).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Confirm Booking',
                onPressed: () {
                  if (_selectedDate == null || _selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select date and time'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking request sent!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(
      String label,
      String value,
      IconData icon,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CHECKLIST - Make sure you have ALL these files:
// ==========================================
/*
MODELS (no imports needed):
✓ service_category_model.dart
✓ handyman_model.dart
✓ job_request_model.dart
✓ booking_model.dart

UTILS:
✓ colors.dart

WIDGETS (with proper imports):
✓ custom_button.dart
✓ custom_textfield.dart
✓ category_card.dart
✓ handyman_card.dart
✓ job_request_card.dart
✓ booking_card.dart
✓ search_bar_widget.dart
✓ booking_bottom_sheet.dart (THIS FILE - COMPLETE NOW)
✓ job_request_details_bottom_sheet.dart (THIS FILE - COMPLETE NOW)

SCREENS:
✓ splash_screen.dart
✓ login_screen.dart
✓ register_screen.dart
✓ role_selection_screen.dart
✓ customer_home_screen.dart
✓ handyman_home_screen.dart
✓ all_categories_screen.dart
✓ service_detail_screen.dart
✓ handyman_detail_screen.dart
✓ profile_screen.dart
✓ edit_profile_screen.dart
*/