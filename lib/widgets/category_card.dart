// ==========================================
// FILE: lib/widgets/category_card.dart
// ==========================================
import 'package:flutter/material.dart';
import '../models/service_category_model.dart';
import '../utils/colors.dart';

class CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  String _getIconForCategory(String categoryName) {
    final icons = {
      'Plumbing': '🔧',
      'Electrical': '⚡',
      'Carpentry': '🪚',
      'Painting': '🎨',
      'Masonry': '🧱',
      'AC Repair': '❄️',
      'Cleaning': '🧹',
      'Roof Repair': '🏠',
      'Landscaping': '🌳',
      'IT Support': '💻',
    };
    return icons[categoryName] ?? '🔧';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                _getIconForCategory(category.name),
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${category.handymenCount} available',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
