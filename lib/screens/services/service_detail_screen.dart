// ==========================================
// FILE: lib/screens/services/service_detail_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import '../../models/service_category_model.dart';
import '../../models/handyman_model.dart';
import '../../widgets/handyman_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../utils/colors.dart';
import '../handyman/handyman_detail_screen.dart';

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
  final _searchController = TextEditingController();
  String _sortBy = 'rating';

  List<Handyman> _handymen = [];

  @override
  void initState() {
    super.initState();
    _loadHandymen();
  }

  void _loadHandymen() {
    _handymen = [
      Handyman(
        id: 1,
        firstName: 'Samantha',
        lastName: 'Silva',
        categoryName: widget.category.name,
        experience: 5,
        hourlyRate: 1500,
        rating: 4.8,
        totalJobs: 45,
        workStatus: 'Available',
        city: 'Kandy',
      ),
      Handyman(
        id: 2,
        firstName: 'Nimal',
        lastName: 'Jayasinghe',
        categoryName: widget.category.name,
        experience: 3,
        hourlyRate: 2000,
        rating: 4.6,
        totalJobs: 32,
        workStatus: 'Available',
        city: 'Kandy',
      ),
      Handyman(
        id: 3,
        firstName: 'Ruwan',
        lastName: 'Ekanayake',
        categoryName: widget.category.name,
        experience: 7,
        hourlyRate: 1800,
        rating: 4.9,
        totalJobs: 67,
        workStatus: 'Busy',
        city: 'Kandy',
      ),
      Handyman(
        id: 4,
        firstName: 'Pasan',
        lastName: 'Ranasinghe',
        categoryName: widget.category.name,
        experience: 4,
        hourlyRate: 1700,
        rating: 4.5,
        totalJobs: 28,
        workStatus: 'Available',
        city: 'Kandy',
      ),
    ];
  }

  void _sortHandymen() {
    setState(() {
      if (_sortBy == 'rating') {
        _handymen.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (_sortBy == 'price') {
        _handymen.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
      } else if (_sortBy == 'experience') {
        _handymen.sort((a, b) => b.experience.compareTo(a.experience));
      }
    });
  }

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
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.category.name),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        _getIconForCategory(widget.category.name),
                        style: const TextStyle(fontSize: 64),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SearchBarWidget(
                    controller: _searchController,
                    hint: 'Search ${widget.category.name.toLowerCase()} specialists...',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Sort by:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildSortChip('Rating', 'rating'),
                      _buildSortChip('Price', 'price'),
                      _buildSortChip('Experience', 'experience'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStatCard(
                    '${widget.category.handymenCount}',
                    'Available',
                    Icons.people,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Rs ${widget.category.avgRate.toStringAsFixed(0)}',
                    'Avg Rate/hr',
                    Icons.attach_money,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return HandymanCard(
                    handyman: _handymen[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HandymanDetailScreen(
                            handyman: _handymen[index],
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: _handymen.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _sortHandymen();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
}
