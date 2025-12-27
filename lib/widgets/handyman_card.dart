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

  const HandymanCard({
    Key? key,
    required this.handymanId,
    required this.rating,
    required this.jobsCompleted,
    required this.hourlyRate,
    required this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return GestureDetector(
      onTap: () {
        // FIX: Only pass handymanId as per our updated Detail Screen constructor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HandymanDetailScreen(
              handymanId: handymanId,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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

            return Row(
              children: [
                // PROFILE IMAGE / INITIALS
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // HANDYMAN INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                    const Text("Hourly", style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Text(
                      "Rs ${hourlyRate.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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