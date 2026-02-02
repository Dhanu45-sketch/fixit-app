// lib/widgets/category_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';

class CategoryCard extends StatelessWidget {
  final String categoryId; // Added categoryId to fetch real-time count
  final String icon;
  final String name;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.categoryId,
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8.0),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),

            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
            ),

            const SizedBox(height: 2),

            // Real-time calculation of specialists in this category
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('handymanProfiles')
                  .where('category_id', isEqualTo: categoryId)
                  .where('work_status', isEqualTo: 'Available')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                return Text(
                  '$count Available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: count > 0 ? AppColors.success : AppColors.textLight,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
