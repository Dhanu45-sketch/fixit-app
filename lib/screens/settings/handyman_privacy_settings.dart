// lib/screens/settings/handyman_privacy_settings.dart
// Allow handymen to control their location privacy

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';

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
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
      setState(() => _isLoading = false);
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy settings updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          const Icon(
            Icons.privacy_tip_outlined,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Privacy, Your Control',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Control how and when your location is shared with customers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 32),

          // Location Sharing Toggle
          Card(
            child: SwitchListTile(
              value: _locationSharingEnabled,
              onChanged: (value) {
                setState(() => _locationSharingEnabled = value);
                _updatePrivacySetting('location_sharing_enabled', value);
              },
              activeColor: AppColors.primary,
              title: const Text(
                'Location Sharing',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _locationSharingEnabled
                    ? 'Your approximate location is visible to customers'
                    : 'You will not appear on the map',
                style: const TextStyle(fontSize: 12),
              ),
              secondary: Icon(
                _locationSharingEnabled
                    ? Icons.location_on
                    : Icons.location_off,
                color: _locationSharingEnabled
                    ? AppColors.primary
                    : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Show on Map Toggle
          Card(
            child: SwitchListTile(
              value: _showOnMap,
              onChanged: (value) {
                setState(() => _showOnMap = value);
                _updatePrivacySetting('show_on_map', value);
              },
              activeColor: AppColors.primary,
              title: const Text(
                'Visible on Map',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Allow customers to see you on the map screen',
                style: TextStyle(fontSize: 12),
              ),
              secondary: Icon(
                _showOnMap ? Icons.map : Icons.map_outlined,
                color: _showOnMap ? AppColors.primary : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Privacy Information
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
                Row(
                  children: [
                    Icon(Icons.shield, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'How We Protect You',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoPoint('Your exact home address is never shown'),
                _buildInfoPoint('Location is "fuzzed" to ~1-2 km radius'),
                _buildInfoPoint('More precise location only after booking confirmed'),
                _buildInfoPoint('Exact location only during active service'),
                _buildInfoPoint('Location hidden after job complete'),
                _buildInfoPoint('You control when you appear on map'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAQ Section
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildFAQ(
            'Can customers see my home address?',
            'No. We show an approximate area (~1-2 km radius) not your exact location. Your actual address is only shared after you accept a booking.',
          ),

          _buildFAQ(
            'What if I turn off location sharing?',
            'You won\'t appear on the map, but customers can still find you through search and categories. This may reduce your visibility.',
          ),

          _buildFAQ(
            'Can I temporarily hide my location?',
            'Yes! Just toggle "Location Sharing" off. Turn it back on when you\'re ready to accept bookings.',
          ),

          _buildFAQ(
            'When do customers see my exact location?',
            'Only during an active service (status: "In Progress") and only the customer you\'re serving. It\'s automatically hidden after completion.',
          ),

          const SizedBox(height: 32),

          // Contact Support
          OutlinedButton.icon(
            onPressed: () {
              // Open support/contact screen
            },
            icon: const Icon(Icons.help_outline),
            label: const Text('Contact Support'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }
}