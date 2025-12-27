import 'package:flutter/material.dart';
import '../../models/service_category_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/handyman_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../utils/colors.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceCategory category;

  const ServiceDetailScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _sortBy = 'rating_avg';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header: Category Icon & Name
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.category.name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.category.icon,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
            ),
          ),

          // Search & Filter UI
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SearchBarWidget(
                    controller: _searchController,
                    hint: 'Search specialists...',
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        _buildSortChip('Rating', 'rating_avg'),
                        _buildSortChip('Price', 'hourly_rate'),
                        _buildSortChip('Experience', 'experience'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // The List of Handymen
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getHandymenByCategory(widget.category.id, _sortBy),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
              }

              final handymen = snapshot.data ?? [];

              if (handymen.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No specialists available in this category.')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final data = handymen[index];

                      // FIX: Passing only required parameters to match the updated HandymanCard
                      return HandymanCard(
                        handymanId: data['id'] ?? '', // Uses document ID
                        rating: (data['rating_avg'] ?? 0.0).toDouble(),
                        jobsCompleted: data['jobs_completed'] ?? 0, // Synced field name
                        hourlyRate: (data['hourly_rate'] ?? 0.0).toDouble(),
                        categoryName: widget.category.name,
                      );
                    },
                    childCount: handymen.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) setState(() => _sortBy = value);
        },
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontSize: 12,
        ),
      ),
    );
  }
}