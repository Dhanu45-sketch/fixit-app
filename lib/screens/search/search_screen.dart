// ==========================================
// FILE: lib/screens/search/search_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import '../../models/handyman_model.dart';
import '../../models/service_category_model.dart';
import '../../widgets/handyman_card.dart';
import '../../utils/colors.dart';
import '../handyman/handyman_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _recentSearches = [
    'Plumbing',
    'Electrical repair',
    'Painting',
  ];

  List<String> _popularSearches = [
    'Emergency plumber',
    'AC repair',
    'Electrician',
    'Carpenter',
    'House painting',
    'Roof repair',
  ];

  List<Handyman> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _searchQuery = '';

  // Mock data - Replace with API call
  final List<Handyman> _allHandymen = [
    Handyman(
      id: 1,
      firstName: 'Samantha',
      lastName: 'Silva',
      categoryName: 'Plumbing',
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
      categoryName: 'Electrical',
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
      categoryName: 'Carpentry',
      experience: 7,
      hourlyRate: 1800,
      rating: 4.9,
      totalJobs: 67,
      workStatus: 'Available',
      city: 'Kandy',
    ),
    Handyman(
      id: 4,
      firstName: 'Pasan',
      lastName: 'Ranasinghe',
      categoryName: 'Painting',
      experience: 4,
      hourlyRate: 1700,
      rating: 4.5,
      totalJobs: 28,
      workStatus: 'Busy',
      city: 'Kandy',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus search bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _hasSearched = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      final results = _allHandymen.where((handyman) {
        final nameLower = '${handyman.firstName} ${handyman.lastName}'.toLowerCase();
        final categoryLower = handyman.categoryName.toLowerCase();
        final queryLower = query.toLowerCase();

        return nameLower.contains(queryLower) || categoryLower.contains(queryLower);
      }).toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
        _searchQuery = query;
      });

      // Add to recent searches
      if (query.isNotEmpty && !_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
      _searchQuery = '';
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: 'Search services or handymen...',
              hintStyle: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textLight,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: AppColors.textLight,
                ),
                onPressed: _clearSearch,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {}); // Update UI for clear button
            },
          ),
        ),
      ),
      body: _isSearching
          ? _buildLoadingState()
          : _hasSearched
          ? _buildSearchResults()
          : _buildSearchSuggestions(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _recentSearches.clear();
                    });
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._recentSearches.map((search) => _buildSearchItem(
              search,
              Icons.history,
                  () {
                _searchController.text = search;
                _performSearch(search);
              },
              onDelete: () {
                setState(() {
                  _recentSearches.remove(search);
                });
              },
            )),
            const SizedBox(height: 24),
          ],
          const Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._popularSearches.map((search) => _buildSearchItem(
            search,
            Icons.trending_up,
                () {
              _searchController.text = search;
              _performSearch(search);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildSearchItem(
      String text,
      IconData icon,
      VoidCallback onTap, {
        VoidCallback? onDelete,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textLight,
                onPressed: onDelete,
              )
            else
              const Icon(
                Icons.north_west,
                size: 18,
                color: AppColors.textLight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''} for "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _showFilterBottomSheet();
                },
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Filter'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return HandymanCard(
                handyman: _searchResults[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HandymanDetailScreen(
                        handyman: _searchResults[index],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.textLight.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear Search',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('Rating', true),
                _buildFilterChip('Price: Low to High', false),
                _buildFilterChip('Experience', false),
                _buildFilterChip('Distance', false),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Availability',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('Available Now', false),
                _buildFilterChip('Today', false),
                _buildFilterChip('This Week', false),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filters applied!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {},
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textDark,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

