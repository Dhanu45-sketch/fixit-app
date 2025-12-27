import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/job_request_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/job_request_card.dart';
import '../../utils/colors.dart';
import '../../widgets/job_request_details_bottom_sheet.dart';

class HandymanSearchScreen extends StatefulWidget {
  const HandymanSearchScreen({Key? key}) : super(key: key);

  @override
  State<HandymanSearchScreen> createState() => _HandymanSearchScreenState();
}

class _HandymanSearchScreenState extends State<HandymanSearchScreen> {
  final _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _recentSearches = ['Plumbing', 'Emergency', 'Electrical'];
  List<String> _popularSearches = ['Emergency plumbing', 'AC repair', 'Cleaning'];

  List<JobRequest> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // Filters
  bool _emergencyOnly = false;
  String? _selectedJobType;

  final List<String> _jobTypes = [
    'Plumbing', 'Electrical', 'Carpentry', 'Painting', 'AC Repair', 'Cleaning'
  ];

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

  // Bridging to Firestore Service
  void _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Query Firestore for Open jobs
      Query queryRef = FirebaseFirestore.instance
          .collection('job_requests')
          .where('status', isEqualTo: 'Open');

      // Filter by Emergency if toggled
      if (_emergencyOnly) {
        queryRef = queryRef.where('is_emergency', isEqualTo: true);
      }

      // Filter by Job Type if selected
      if (_selectedJobType != null) {
        queryRef = queryRef.where('job_type', isEqualTo: _selectedJobType);
      }

      final snapshot = await queryRef.get();

      final results = snapshot.docs.map((doc) {
        return JobRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Client-side text filtering for the description/location
      final filteredResults = results.where((job) {
        final searchLower = query.toLowerCase();
        return job.description.toLowerCase().contains(searchLower) ||
            job.location.toLowerCase().contains(searchLower);
      }).toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });

      if (query.isNotEmpty && !_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
      }
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching jobs: $e')),
      );
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
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
        title: _buildSearchField(),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
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
          hintText: 'Search jobs or locations...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Emergency'),
              selected: _emergencyOnly,
              onSelected: (val) {
                setState(() => _emergencyOnly = val);
                _performSearch(_searchController.text);
              },
              selectedColor: AppColors.error.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            if (_selectedJobType != null)
              Chip(
                label: Text(_selectedJobType!),
                onDeleted: () {
                  setState(() => _selectedJobType = null);
                  _performSearch(_searchController.text);
                },
              ),
            TextButton.icon(
              onPressed: _showFilterBottomSheet,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text("No jobs found matching your criteria."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return JobRequestCard(
          jobRequest: _searchResults[index],
          onTap: () => _showJobDetails(_searchResults[index]),
        );
      },
    );
  }

  void _showJobDetails(JobRequest job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => JobRequestDetailsBottomSheet(jobRequest: job),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Filter by Skill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _jobTypes.map((type) => ChoiceChip(
                  label: Text(type),
                  selected: _selectedJobType == type,
                  onSelected: (val) {
                    setModalState(() => _selectedJobType = val ? type : null);
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performSearch(_searchController.text);
                  },
                  child: const Text('Apply Filters'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Popular categories', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._popularSearches.map((s) => ListTile(
          title: Text(s),
          leading: const Icon(Icons.trending_up),
          onTap: () {
            _searchController.text = s;
            _performSearch(s);
          },
        )),
      ],
    );
  }
}