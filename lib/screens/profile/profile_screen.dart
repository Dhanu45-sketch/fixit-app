import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/colors.dart';
import '../auth/role_selection_screen.dart';
import 'edit_profile_screen.dart';

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

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(isHandyman: widget.isHandyman),
      ),
    );

    if (result == true) {
      _loadProfileData();
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.signOut();

        if (mounted) {
          // Clear the entire navigation stack and go to role selection
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: _handleLogout,
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
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: _userData?['profile_image'] != null
                      ? NetworkImage(_userData!['profile_image'])
                      : null,
                  child: _userData?['profile_image'] == null
                      ? Text(
                    _userData?['first_name']?.toString()[0].toUpperCase() ?? '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _navigateToEdit,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 16, color: Colors.white),
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
            const SizedBox(height: 4),
            Text(
              _userData?['email'] ?? 'No email provided',
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 30),

            if (widget.isHandyman) ...[
              _buildProfileItem(
                Icons.work,
                'Business Settings',
                'Update rates & category',
                _navigateToEdit,
              ),
              _buildProfileItem(
                Icons.verified,
                'My Certificates',
                'View uploaded documents',
                _navigateToEdit,
              ),
              _buildProfileItem(
                Icons.history,
                'Earnings History',
                'View your income',
                    () {},
              ),
            ] else ...[
              _buildProfileItem(
                Icons.favorite,
                'Saved Handymen',
                'Your favorite pros',
                    () {},
              ),
              _buildProfileItem(
                Icons.location_on,
                'My Addresses',
                'Manage service locations',
                    () {},
              ),
            ],

            _buildProfileItem(
              Icons.settings,
              'Account Settings',
              'Privacy and security',
              _navigateToEdit,
            ),
            _buildProfileItem(
              Icons.help_outline,
              'Support',
              'Get help with FixIt',
                  () {},
            ),

            const SizedBox(height: 20),

            // Logout Button as a list tile for consistency
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                ),
                subtitle: const Text('Sign out of your account'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.error),
                onTap: _handleLogout,
              ),
            ),
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