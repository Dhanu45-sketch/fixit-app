import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/colors.dart';
import '../auth/role_selection_screen.dart';
import 'edit_profile_screen.dart'; // Import the edit screen

class ProfileScreen extends StatefulWidget {
  final bool isHandyman;

  const ProfileScreen({
    Key? key,
    this.isHandyman = false,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Reloads data from Firestore
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUserId;
    if (userId != null) {
      final data = await _firestoreService.getUserProfile(userId);
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    }
  }

  // Navigates to edit screen and refreshes on return
  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(isHandyman: widget.isHandyman),
      ),
    );

    if (result == true) {
      _loadProfileData(); // Refresh UI if data was saved
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _navigateToEdit,
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 15,
                      child: Icon(Icons.edit, size: 15, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_userData?['first_name'] ?? 'User'} ${_userData?['last_name'] ?? ''}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(_userData?['email'] ?? 'No email provided'),
            const SizedBox(height: 30),

            // Conditional UI based on Role
            if (widget.isHandyman) ...[
              _buildProfileItem(Icons.work, 'Business Settings', 'Update rates & category', () {}),
              _buildProfileItem(Icons.history, 'Earnings History', 'View your income', () {}),
            ] else ...[
              _buildProfileItem(Icons.favorite, 'Saved Handymen', 'Your favorite pros', () {}),
              _buildProfileItem(Icons.location_on, 'My Addresses', 'Manage service locations', () {}),
            ],

            _buildProfileItem(
              Icons.settings,
              'Account Settings',
              'Privacy and security',
              _navigateToEdit, // Link to Edit Profile
            ),
            _buildProfileItem(Icons.help_outline, 'Support', 'Get help with FixIt', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}