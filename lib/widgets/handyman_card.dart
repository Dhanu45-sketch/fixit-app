// lib/widgets/handyman_card.dart
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../screens/handyman/handyman_detail_screen.dart'; // Ensure this path is correct

class HandymanCard extends StatelessWidget {
  final String handymanId; // This is the UID from Firestore
  final double rating;
  final int jobsCompleted;
  final double hourlyRate;
  final String categoryName;
  final bool isEmergencyMode; // NEW: Added emergency mode flag

  const HandymanCard({
    Key? key,
    required this.handymanId,
    required this.rating,
    required this.jobsCompleted,
    required this.hourlyRate,
    required this.categoryName,
    this.isEmergencyMode = false, // Default to false
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
        // FIX: Only pass handymanId as per our updated Detail Screen constructor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HandymanDetailScreen(
              handymanId: handymanId,
              isEmergency: isEmergencyMode, // Pass emergency state to detail
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
          // Fetch user details once for the whole card
          future: firestoreService.getUserProfile(handymanId),
          builder: (context, snapshot) {
            final userData = snapshot.data;
            final firstName = userData?['first_name'] ?? '';
            final lastName = userData?['last_name'] ?? '';
            final fullName = firstName.isEmpty ? "Handyman" : "$firstName $lastName";
            final String initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'H';
            final String? profileImage = userData?['profile_image'];

            return Row(
              children: [
                // PROFILE IMAGE / INITIALS
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isEmergencyMode 
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                  child: profileImage == null
                      ? (snapshot.connectionState == ConnectionState.waiting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    initial,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isEmergencyMode ? Colors.red.shade700 : AppColors.primary,
                    ),
                  ))
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
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "$jobsCompleted jobs",
                            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
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
                        color: isEmergencyMode ? Colors.red.shade700 : AppColors.textLight,
                        fontWeight: isEmergencyMode ? FontWeight.bold : FontWeight.normal,
                      )
                    ),
                    Text(
                      "Rs ${displayRate.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEmergencyMode ? Colors.red.shade700 : AppColors.primary,
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
}
