// lib/widgets/category_card.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CategoryCard extends StatelessWidget {
  final String icon;
  final String name;
  final int count;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.icon,
    required this.name,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        // Added padding to ensure internal elements don't touch the edges
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
            // Using a Flexible wrapper for the icon/emoji
            Text(icon, style: const TextStyle(fontSize: 32)), // Reduced slightly from 40 to save space
            const SizedBox(height: 8),

            // FIX: Use Flexible to prevent the Name from causing overflow
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Reduced slightly from 16 to fit constraints
                  color: AppColors.textDark,
                ),
              ),
            ),

            const SizedBox(height: 2),

            // FIX: Keep the count text small and single-line
            Text(
              '$count Specialists',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11, // Reduced slightly from 12
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}