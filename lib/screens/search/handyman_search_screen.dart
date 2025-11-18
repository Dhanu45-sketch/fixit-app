// ==========================================
// FILE: lib/screens/search/handyman_search_screen.dart
// Search screen for handymen to find specific job requests
// ==========================================
import 'package:flutter/material.dart';
import '../../models/job_request_model.dart';
import '../../widgets/job_request_card.dart';
import '../../utils/colors.dart';
import '../../widgets/job_request_details_bottom_sheet.dart';

class HandymanSearchScreen extends StatefulWidget {
  const HandymanSearchScreen({Key? key}) : super(key: key);

  @override
  State<HandymanSearchScreen> createState() => _HandymanSearchScreenState();
}

class _HandymanSearchScreenState extends State<HandymanSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _recentSearches = [
    'Plumbing',
    'Emergency',
    'Electrical',
  ];

  List<String> _popularSearches = [
    'Emergency plumbing',
    'Electrical repair',
    'Carpentry',
    'Painting',
    'AC repair',
    'Cleaning',
  ];

  List<JobRequest> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _searchQuery = '';

  // Filters
  bool _emergencyOnly = false;
  String? _selectedJobType;
  String? _selectedLocation;

  // Mock data - Replace with API call
  final List<JobRequest> _allJobRequests = [
    JobRequest(
      id: 1,
      customerName: 'Amal Perera',
      description: 'Fix leaking tap in kitchen. Water is dripping constantly.',
      jobType: 'Plumbing',
      location: 'Peradeniya Rd, Kandy',
      isEmergency: true,
      createdTime: DateTime.now().subtract(const Duration(hours: 2)),
      deadline: DateTime.now().add(const Duration(hours: 6)),
      status: 'Open',
      offeredPrice: 1500,
    ),
    JobRequest(
      id: 2,
      customerName: 'Kamal Fernando',
      description: 'Repair broken chair leg, need wood work',
      jobType: 'Carpentry',
      location: 'Temple St, Kandy',
      isEmergency: false,
      createdTime: DateTime.now().subtract(const Duration(hours: 5)),
      deadline: DateTime.now().add(const Duration(days: 2)),
      status: 'Open',
      offeredPrice: 1200,
    ),
    JobRequest(
      id: 3,
      customerName: 'Chathura Dissanayake',
      description: 'Install new light fixtures in living room',
      jobType: 'Electrical',
      location: 'Ampitiya Rd, Kandy',
      isEmergency: false,
      createdTime: DateTime.now().subtract(const Duration(hours: 8)),
      deadline: DateTime.now().add(const Duration(days: 3)),
      status: 'Open',
      offeredPrice: 2000,
    ),
    JobRequest(
      id: 4,
      customerName: 'Ruwan Perera',
      description: 'Emergency electrical short circuit repair',
      jobType: 'Electrical',
      location: 'Katugastota Rd, Kandy',
      isEmergency: true,
      createdTime: DateTime.now().subtract(const Duration(minutes: 30)),
      deadline: DateTime.now().add(const Duration(hours: 2)),
      status: 'Open',
      offeredPrice: 2500,
    ),
    JobRequest(
      id: 5,
      customerName: 'Shanika Silva',
      description: 'Paint bedroom walls - white color',
      jobType: 'Painting',
      location: 'Kundasale Rd, Kandy',
      isEmergency: false,
      createdTime: DateTime.now().subtract(const Duration(hours: 12)),
      deadline: DateTime.now().add(const Duration(days: 5)),
      status: 'Open',
      offeredPrice: 3500,
    ),
  ];

  final List<String> _jobTypes = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'AC Repair',
    'Cleaning',
    'Landscaping',
  ];

  @override
  void initState() {
    super.initState();
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
    if (query.isEmpty && !_emergencyOnly && _selectedJobType == null) {
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
      var results = _allJobRequests.where((job) {
        final queryLower = query.toLowerCase();
        final matchesQuery = query.isEmpty ||
            job.description.toLowerCase().contains(queryLower) ||
            job.jobType.toLowerCase().contains(queryLower) ||
            job.location.toLowerCase().contains(queryLower);

        final matchesEmergency = !_emergencyOnly || job.isEmergency;
        final matchesJobType = _selectedJobType == null || job.jobType == _selectedJobType;

        return matchesQuery && matchesEmergency && matchesJobType;
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
      _emergencyOnly = false;
      _selectedJobType = null;
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
              hintText: 'Search job requests...',
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
              setState(() {});
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          if (_hasSearched || _emergencyOnly || _selectedJobType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emergency, size: 16),
                          SizedBox(width: 4),
                          Text('Emergency'),
                        ],
                      ),
                      selected: _emergencyOnly,
                      onSelected: (value) {
                        setState(() {
                          _emergencyOnly = value;
                        });
                        _performSearch(_searchController.text);
                      },
                      selectedColor: AppColors.error.withOpacity(0.2),
                      checkmarkColor: AppColors.error,
                      labelStyle: TextStyle(
                        color: _emergencyOnly ? AppColors.error : AppColors.textDark,
                        fontWeight: _emergencyOnly ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...(_selectedJobType != null
                        ? [
                      Chip(
                        label: Text(_selectedJobType!),
                        onDeleted: () {
                          setState(() {
                            _selectedJobType = null;
                          });
                          _performSearch(_searchController.text);
                        },
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        deleteIconColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                    ]
                        : []),
                    TextButton.icon(
                      onPressed: _showFilterBottomSheet,
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('More Filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content
          Expanded(
            child: _isSearching
                ? _buildLoadingState()
                : _hasSearched
                ? _buildSearchResults()
                : _buildSearchSuggestions(),
          ),
        ],
      ),
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
            'Searching job requests...',
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
                '${_searchResults.length} job${_searchResults.length != 1 ? 's' : ''} found',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              if (_emergencyOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'EMERGENCY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
              _performSearch(_searchController.text);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return JobRequestCard(
                  jobRequest: _searchResults[index],
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => JobRequestDetailsBottomSheet(
                        jobRequest: _searchResults[index],
                      ),
                    );
                  },
                );
              },
            ),
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
              'No job requests found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or search terms',
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
                'Clear Filters',
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _emergencyOnly = false;
                        _selectedJobType = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Job Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _jobTypes.map((type) {
                  return FilterChip(
                    label: Text(type),
                    selected: _selectedJobType == type,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedJobType = selected ? type : null;
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _selectedJobType == type
                          ? AppColors.primary
                          : AppColors.textDark,
                      fontWeight: _selectedJobType == type
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _emergencyOnly = _emergencyOnly;
                      _selectedJobType = _selectedJobType;
                    });
                    Navigator.pop(context);
                    _performSearch(_searchController.text);
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
      ),
    );
  }
}