import 'package:flutter/material.dart';
import '../../models/service_category_model.dart';
import '../../widgets/category_card.dart';
import '../../utils/colors.dart';
import '../services/service_detail_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  // We keep this as a list for initial display,
  // but we will use a model-based navigation approach.
  final List<ServiceCategory> categories;

  const AllCategoriesScreen({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Categories'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9, // Adjusted for better text fit
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return CategoryCard(
            icon: category.icon,
            name: category.name,
            count: category.handymenCount,
            onTap: () {
              // FIXED: Pass the WHOLE category object to match
              // the constructor of ServiceDetailScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(category: category),
                ),
              );
            },
          );
        },
      ),
    );
  }
}