import 'package:flutter/material.dart';
import '../../models/service_category_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/handyman_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../utils/colors.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceCategory category;
  final bool isEmergencyMode; // NEW: Emergency mode indicator

  const ServiceDetailScreen({
    Key? key,
    required this.category,
    this.isEmergencyMode = false, // NEW: Default to false
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
            backgroundColor: widget.isEmergencyMode ? Colors.red.shade700 : AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (widget.isEmergencyMode) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'EMERGENCY',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isEmergencyMode 
                        ? [Colors.red.shade700, Colors.red.shade900]
                        : [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.category.icon,
                        style: const TextStyle(fontSize: 64),
                      ),
                      if (widget.isEmergencyMode) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emergency, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                '+15% Emergency Fee',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
                        Text(
                          widget.isEmergencyMode ? 'Emergency Sort:' : 'Sort by:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
            stream: _firestoreService.getHandymenByCategory(
              widget.category.id, 
              _sortBy,
              emergencyOnly: widget.isEmergencyMode, // NEW: Filter by emergency availability
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
              }

              final handymen = snapshot.data ?? [];

              if (handymen.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isEmergencyMode ? Icons.emergency : Icons.person_search,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.isEmergencyMode
                                ? 'No emergency specialists available'
                                : 'No specialists available in this category.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.isEmergencyMode) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Try switching to standard service mode',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = handymen[index];

                      return HandymanCard(
                        handymanId: data['id'] ?? '',
                        rating: (data['rating_avg'] ?? 0.0).toDouble(),
                        jobsCompleted: data['jobs_completed'] ?? 0,
                        hourlyRate: (data['hourly_rate'] ?? 0.0).toDouble(),
                        categoryName: widget.category.name,
                        isEmergencyMode: widget.isEmergencyMode, // NEW: Pass emergency state
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
        selectedColor: widget.isEmergencyMode ? Colors.red.shade700 : AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontSize: 12,
        ),
      ),
    );
  }
}
