import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/handyman_card.dart';
import '../../utils/colors.dart';

class SearchScreen extends StatefulWidget {
  final bool isEmergencyMode; // NEW: Emergency mode indicator

  const SearchScreen({
    Key? key,
    this.isEmergencyMode = false, // NEW: Default to false
  }) : super(key: key);

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
      final results = await _firestoreService.searchHandymen(
        trimmedQuery,
        emergencyOnly: widget.isEmergencyMode, // NEW: Filter by emergency availability
      );

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
        backgroundColor: widget.isEmergencyMode ? Colors.red.shade700 : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: widget.isEmergencyMode ? Colors.white : AppColors.textDark,
        ),
        title: _buildSearchField(),
      ),
      body: Column(
        children: [
          // Emergency Mode Banner
          if (widget.isEmergencyMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.red.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.emergency, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Emergency Mode Active - Showing 24/7 available handymen (+15% fee)',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched
                ? _buildSearchResults()
                : _buildSearchSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: widget.isEmergencyMode ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: _performSearch,
        onChanged: (value) {
          setState(() {});
        },
        style: TextStyle(
          color: widget.isEmergencyMode ? Colors.red.shade700 : AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: widget.isEmergencyMode 
              ? 'Search emergency specialists...'
              : 'Search categories...',
          hintStyle: TextStyle(
            fontSize: 14, 
            color: widget.isEmergencyMode ? Colors.red.shade300 : Colors.grey,
          ),
          prefixIcon: Icon(
            Icons.search, 
            size: 20,
            color: widget.isEmergencyMode ? Colors.red.shade700 : AppColors.textLight,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.cancel, 
              size: 20,
              color: widget.isEmergencyMode ? Colors.red.shade700 : AppColors.textLight,
            ),
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
          isEmergencyMode: widget.isEmergencyMode, // NEW: Pass emergency state
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
            const Text(
              'Recent Searches', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _recentSearches.map((s) => ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 13)),
                backgroundColor: widget.isEmergencyMode 
                    ? Colors.red.shade50 
                    : AppColors.background,
                side: BorderSide(
                  color: widget.isEmergencyMode 
                      ? Colors.red.shade200 
                      : Colors.grey.shade300,
                ),
                onPressed: () {
                  _searchController.text = s;
                  _performSearch(s);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            widget.isEmergencyMode 
                ? 'Emergency Categories'
                : 'Popular Categories',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _popularSearches.map((s) => ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 13)),
              backgroundColor: widget.isEmergencyMode 
                  ? Colors.red.shade50 
                  : AppColors.background,
              side: BorderSide(
                color: widget.isEmergencyMode 
                    ? Colors.red.shade200 
                    : Colors.grey.shade300,
              ),
              avatar: widget.isEmergencyMode 
                  ? Icon(Icons.emergency, size: 16, color: Colors.red.shade700)
                  : null,
              onPressed: () {
                _searchController.text = s;
                _performSearch(s);
              },
            )).toList(),
          ),
          
          if (widget.isEmergencyMode) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Emergency Service Info',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 24/7 availability\n'
                    '• Priority response time\n'
                    '• 15% emergency surcharge\n'
                    '• Immediate assistance',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isEmergencyMode ? Icons.emergency_share : Icons.search_off,
            size: 64,
            color: widget.isEmergencyMode ? Colors.red.shade200 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isEmergencyMode 
                ? "No emergency specialists found for '$_searchQuery'"
                : "No results for '$_searchQuery'",
            style: const TextStyle(color: AppColors.textLight, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isEmergencyMode
                ? "Try searching for common services like 'Plumbing' or 'Electrical'"
                : "Try searching for 'Plumbing' or 'Electrical'",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
