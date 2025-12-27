import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/handyman_card.dart';
import '../../utils/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _recentSearches = ['Plumbing', 'Electrical', 'Painting'];
  final List<String> _popularSearches = ['AC Repair', 'Electrician', 'Carpenter'];

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchQuery = trimmedQuery;
    });

    try {
      final results = await _firestoreService.searchHandymen(trimmedQuery);

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });

      if (!_recentSearches.contains(trimmedQuery)) {
        setState(() {
          _recentSearches.insert(0, trimmedQuery);
          if (_recentSearches.length > 5) _recentSearches.removeLast();
        });
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: _buildSearchField(),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _hasSearched
          ? _buildSearchResults()
          : _buildSearchSuggestions(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: _performSearch,
        onChanged: (value) {
          // Re-render to show/hide the clear button
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search categories...',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.cancel, size: 20),
            onPressed: _clearSearch,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final data = _searchResults[index];
        return HandymanCard(
          handymanId: data['id'] ?? '',
          categoryName: data['category_name'] ?? 'Specialist',
          rating: (data['rating_avg'] ?? 0.0).toDouble(),
          jobsCompleted: data['jobs_completed'] ?? 0,
          hourlyRate: (data['hourly_rate'] ?? 0.0).toDouble(),
        );
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _recentSearches.map((s) => ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 13)),
                onPressed: () {
                  _searchController.text = s;
                  _performSearch(s);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          const Text('Popular Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _popularSearches.map((s) => ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 13)),
              onPressed: () {
                _searchController.text = s;
                _performSearch(s);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No results for '$_searchQuery'",
            style: const TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text("Try searching for 'Plumbing' or 'Electrical'", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}