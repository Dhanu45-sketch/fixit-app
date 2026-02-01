import 'package:flutter/material.dart';
import '../../models/service_category_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/colors.dart';
import '../../widgets/category_card.dart';
import '../../widgets/handyman_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../bookings/bookings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../services/service_detail_screen.dart';
import '../map/map_screen.dart';
import 'all_categories_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _searchController = TextEditingController();

  String _userName = 'Customer';
  int _selectedIndex = 0;
  bool _isEmergencyMode = false; // Emergency toggle state

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (user != null && mounted) {
        setState(() {
          _userName = user['first_name'] ?? 'Customer';
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _getSelectedScreen(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return const BookingsScreen();
      case 2:
        return MapScreen(isEmergencyMode: _isEmergencyMode); // Pass emergency state
      case 3:
        return const NotificationsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadUserData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildEmergencyToggle(), // Emergency toggle
                    const SizedBox(height: 24),
                    _buildCategoryHeader(),
                    const SizedBox(height: 12),
                    _buildCategoriesGrid(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isEmergencyMode ? 'Emergency Specialists' : 'Top Rated Handymen',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (_isEmergencyMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+15% Fee',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHandymenList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
                  Text(_userName, style: const TextStyle(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark),
                onPressed: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SearchScreen(isEmergencyMode: _isEmergencyMode)),
      ),
      child: AbsorbPointer(child: SearchBarWidget(controller: _searchController)),
    );
  }

  // Emergency Toggle Widget
  Widget _buildEmergencyToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEmergencyMode ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEmergencyMode ? Colors.red.shade300 : Colors.grey.shade300,
          width: _isEmergencyMode ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isEmergencyMode ? 0.1 : 0.05),
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
              color: _isEmergencyMode ? Colors.red.shade100 : AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.emergency,
              color: _isEmergencyMode ? Colors.red.shade700 : AppColors.textLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergency Services',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEmergencyMode
                      ? 'Showing 24/7 available specialists (+15% fee)'
                      : 'Get urgent help from available specialists',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isEmergencyMode ? Colors.red.shade700 : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEmergencyMode,
            onChanged: (value) {
              setState(() => _isEmergencyMode = value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? '🚨 Emergency mode enabled - Showing specialists with +15% surcharge'
                        : 'Emergency mode disabled',
                  ),
                  backgroundColor: value ? Colors.red.shade700 : AppColors.textLight,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Service Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        TextButton(
          onPressed: () async {
            final categoriesData = await _firestoreService.getServiceCategories().first;
            final categories = categoriesData.map((e) => ServiceCategory.fromMap(e, e['id'])).toList();
            if (mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AllCategoriesScreen(categories: categories)));
            }
          },
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getServiceCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final categories = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: categories.length > 8 ? 8 : categories.length,
          itemBuilder: (context, index) {
            final data = categories[index];
            final category = ServiceCategory.fromMap(data, data['id']);
            return CategoryCard(
              icon: category.icon,
              name: category.name,
              count: category.handymenCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailScreen(
                      category: category,
                      isEmergencyMode: _isEmergencyMode, // Pass emergency state
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHandymenList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getTopRatedHandymen(
        limit: 5,
        emergencyOnly: _isEmergencyMode,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final handymen = snapshot.data ?? [];
        if (handymen.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    _isEmergencyMode ? Icons.emergency : Icons.person_search,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isEmergencyMode
                        ? "No emergency specialists available right now"
                        : "No top rated specialists found.",
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: handymen.length,
          itemBuilder: (context, index) {
            final h = handymen[index];
            return HandymanCard(
              handymanId: h['id'] ?? h['user_id'] ?? '',
              categoryName: h['category_name'] ?? 'Specialist',
              rating: (h['rating_avg'] ?? 0.0).toDouble(),
              jobsCompleted: h['jobs_completed'] ?? 0,
              hourlyRate: (h['hourly_rate'] ?? 0.0).toDouble(),
              isEmergencyMode: _isEmergencyMode, // Pass emergency state to card
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textLight,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
