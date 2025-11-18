// ==========================================
// FILE: lib/widgets/job_request_card.dart
// ==========================================
import 'package:flutter/material.dart';
import '../models/job_request_model.dart';
import '../utils/colors.dart';
import 'package:fixit_app/screens/home/customer_home_screen.dart';
import 'package:fixit_app/screens/home/handyman_home_screen.dart';
import 'package:flutter/material.dart';
import '../models/job_request_model.dart';
import '../utils/colors.dart';
import '../../widgets/custom_button.dart';

import 'package:flutter/material.dart';
import '../models/job_request_model.dart';
import '../utils/colors.dart';

class JobRequestCard extends StatelessWidget {
  final JobRequest jobRequest;
  final VoidCallback onTap;

  const JobRequestCard({
    Key? key,
    required this.jobRequest,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: jobRequest.isEmergency
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    jobRequest.jobType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (jobRequest.isEmergency)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 8),
            Text(
              jobRequest.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.person_outline, 'Customer', jobRequest.customerName),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, 'Location', jobRequest.location),
            const SizedBox(height: 12),
            if (jobRequest.deadline != null)
              _buildInfoRow(
                Icons.schedule,
                'Deadline',
                '${jobRequest.deadline!.day}/${jobRequest.deadline!.month}/${jobRequest.deadline!.year} at ${jobRequest.deadline!.hour}:${jobRequest.deadline!.minute.toString().padLeft(2, '0')}',
              ),
            if (jobRequest.offeredPrice != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.attach_money,
                'Offered Price',
                'Rs ${jobRequest.offeredPrice!.toStringAsFixed(0)}',
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Accept Job',
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job accepted successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
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
                ),
              ),
              const SizedBox(height: 4),
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
}
