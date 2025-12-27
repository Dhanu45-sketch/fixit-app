import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final VoidCallback? onFilterTap; // Added this to fix the undefined error

  const SearchBarWidget({
    Key? key,
    required this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onFilterTap, // Allow the screen to handle filter button taps
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged, // FIX: This connects the UI to your logic
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          // FIX: Only show the filter icon if a function is provided
          if (onFilterTap != null)
            IconButton(
              icon: const Icon(Icons.tune, color: AppColors.primary),
              onPressed: onFilterTap,
            ),
        ],
      ),
    );
  }
}