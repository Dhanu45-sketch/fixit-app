// lib/screens/settings/handyman_privacy_registration.dart
// Allow handymen to control their location privacy during registration

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../handyman/location_setup_screen.dart'; // Import this

class HandymanPrivacySettings extends StatefulWidget {
  const HandymanPrivacySettings({Key? key}) : super(key: key);

  @override
  State<HandymanPrivacySettings> createState() => _HandymanPrivacySettingsState();
}

class _HandymanPrivacySettingsState extends State<HandymanPrivacySettings> {
  final _authService = AuthService();
  bool _locationSharingEnabled = true;
  bool _showOnMap = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('handymanProfiles')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _locationSharingEnabled = data?['location_sharing_enabled'] ?? true;
          _showOnMap = data?['show_on_map'] ?? true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePrivacySetting(String field, bool value) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('handymanProfiles')
          .doc(userId)
          .update({
        field: value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 3: Privacy Control'),
        automaticallyImplyLeading: false, // Prevent going back to register form
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.privacy_tip_outlined, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Your Privacy, Your Control',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Control how and when your location is shared with customers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),

          const SizedBox(height: 32),

          Card(
            child: SwitchListTile(
              value: _locationSharingEnabled,
              onChanged: (value) {
                setState(() => _locationSharingEnabled = value);
                _updatePrivacySetting('location_sharing_enabled', value);
              },
              activeColor: AppColors.primary,
              title: const Text('Location Sharing', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _locationSharingEnabled
                    ? 'Your approximate location is visible to customers'
                    : 'You will not appear on the map',
                style: const TextStyle(fontSize: 12),
              ),
              secondary: Icon(
                _locationSharingEnabled ? Icons.location_on : Icons.location_off,
                color: _locationSharingEnabled ? AppColors.primary : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: SwitchListTile(
              value: _showOnMap,
              onChanged: (value) {
                setState(() => _showOnMap = value);
                _updatePrivacySetting('show_on_map', value);
              },
              activeColor: AppColors.primary,
              title: const Text('Visible on Map', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Allow customers to see you on the map screen', style: TextStyle(fontSize: 12)),
              secondary: Icon(
                _showOnMap ? Icons.map : Icons.map_outlined,
                color: _showOnMap ? AppColors.primary : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Privacy Protection Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('How We Protect You', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoPoint('Your exact home address is never shown'),
                _buildInfoPoint('Location is "fuzzed" to ~1-2 km radius'),
                _buildInfoPoint('Exact location only during active service'),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // ✅ NEXT BUTTON: Moves to Step 4 (Location Area)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LocationSetupScreen(isRegistrationFlow: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Next: Set Service Area',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
