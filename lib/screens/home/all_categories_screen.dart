// ==========================================
// FILE: lib/screens/home/all_categories_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import '../../models/service_category_model.dart';
import '../../widgets/category_card.dart';
import '../../utils/colors.dart';
import '../services/service_detail_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  final List<ServiceCategory> categories;

  const AllCategoriesScreen({
    Key? key,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Categories'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryCard(
            category: categories[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(
                    category: categories[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}