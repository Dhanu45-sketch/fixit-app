// lib/widgets/handyman_card.dart
// FIXED VERSION - Added proper error handling and loading states
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../screens/handyman/handyman_detail_screen.dart';

class HandymanCard extends StatelessWidget {
  final String handymanId;
  final double rating;
  final int jobsCompleted;
  final double hourlyRate;
  final String categoryName;
  final bool isEmergencyMode;

  const HandymanCard({
    Key? key,
    required this.handymanId,
    required this.rating,
    required this.jobsCompleted,
    required this.hourlyRate,
    required this.categoryName,
    this.isEmergencyMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    // Calculate display rate based on mode
    final double displayRate = isEmergencyMode
        ? FirestoreService.calculateEmergencyPrice(hourlyRate)
        : hourlyRate;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HandymanDetailScreen(
              handymanId: handymanId,
              isEmergency: isEmergencyMode,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isEmergencyMode
              ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: isEmergencyMode
                  ? Colors.red.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: firestoreService.getUserProfile(handymanId),
          builder: (context, snapshot) {
            // FIX: Add proper error handling
            if (snapshot.hasError) {
              return _buildErrorState();
            }

            // FIX: Show loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            // FIX: Handle null data
            final userData = snapshot.data;
            if (userData == null) {
              return _buildErrorState(message: 'User data not found');
            }

            final firstName = userData['first_name'] ?? '';
            final lastName = userData['last_name'] ?? '';
            final fullName = firstName.isEmpty ? "Handyman" : "$firstName $lastName";
            final String initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'H';
            final String? profileImage = userData['profile_image'];

            return Row(
              children: [
                // PROFILE IMAGE / INITIALS
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isEmergencyMode
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  backgroundImage: profileImage != null && profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  onBackgroundImageError: profileImage != null
                      ? (exception, stackTrace) {
                    debugPrint('Error loading profile image: $exception');
                  }
                      : null,
                  child: profileImage == null || profileImage.isEmpty
                      ? Text(
                    initial,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isEmergencyMode
                          ? Colors.red.shade700
                          : AppColors.primary,
                    ),
                  )
                      : null,
                ),

                const SizedBox(width: 16),

                // HANDYMAN INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isEmergencyMode) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.flash_on, color: Colors.orange, size: 16),
                          ],
                        ],
                      ),
                      Text(
                        categoryName,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "$jobsCompleted jobs",
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // PRICE TAG
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isEmergencyMode ? "Urgent Rate" : "Hourly",
                      style: TextStyle(
                        fontSize: 10,
                        color: isEmergencyMode
                            ? Colors.red.shade700
                            : AppColors.textLight,
                        fontWeight: isEmergencyMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      "Rs ${displayRate.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEmergencyMode
                            ? Colors.red.shade700
                            : AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // FIX: Added loading state widget
  Widget _buildLoadingState() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // FIX: Added error state widget
  Widget _buildErrorState({String message = 'Failed to load handyman data'}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.red.withOpacity(0.1),
          child: const Icon(Icons.error_outline, color: Colors.red),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}