
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fixit_app/services/auth_service.dart';
import 'package:fixit_app/services/firestore_service.dart';
import 'package:fixit_app/services/storage_service.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isHandyman;

  const EditProfileScreen({super.key, this.isHandyman = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  // Common controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Handyman specific controllers
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  String? _profileImageUrl;
  File? _newProfileImage;
  bool _isLoading = true;
  bool _isUploading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUserData() async {
    setState(() => _isLoading = true);
    _userId = _authService.currentUserId;
    if (_userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _firestoreService.getUserProfile(_userId!),
        if (widget.isHandyman) _firestoreService.getHandymanProfileByUserId(_userId!)
      ]);

      final user = results[0] as Map<String, dynamic>?;
      final handymanProfile = widget.isHandyman ? results[1] as Map<String, dynamic>? : null;

      if (user != null && mounted) {
        setState(() {
          _firstNameController.text = user['first_name'] ?? '';
          _lastNameController.text = user['last_name'] ?? '';
          _phoneController.text = user['phone'] ?? '';
          _addressController.text = user['address'] ?? '';
          _profileImageUrl = user['profile_image'];

          if (widget.isHandyman && handymanProfile != null) {
            _bioController.text = handymanProfile['bio'] ?? '';
            _experienceController.text = (handymanProfile['experience'] ?? 0).toString();
            _hourlyRateController.text = (handymanProfile['hourly_rate'] ?? 0.0).toString();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    File? imageFile;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source == null) return;

    if (source == ImageSource.camera) {
      imageFile = await _storageService.pickImageFromCamera();
    } else {
      imageFile = await _storageService.pickImageFromGallery();
    }

    if (imageFile != null) {
      setState(() => _newProfileImage = imageFile);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _profileImageUrl;
      if (_newProfileImage != null) {
        final uploadedUrl = await _storageService.uploadProfilePicture(
          userId: _userId!,
          imageFile: _newProfileImage!,
        );
        imageUrl = uploadedUrl ?? imageUrl;
      }

      final userData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        if (imageUrl != null) 'profile_image': imageUrl,
      };

      final handymanData = {
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'hourly_rate': double.tryParse(_hourlyRateController.text) ?? 0.0,
        'bio': _bioController.text.trim(),
      };

      await Future.wait([
        _firestoreService.updateUserProfile(_userId!, userData),
        if (widget.isHandyman) _firestoreService.updateHandymanProfile(_userId!, handymanData),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 24),
                  ..._buildCommonFields(),
                  if (widget.isHandyman) ..._buildHandymanFields(),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: _isUploading ? 'Saving...' : 'Save Changes',
                    onPressed: _saveProfile,
                    isLoading: _isUploading,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: _newProfileImage != null
                ? FileImage(_newProfileImage!)
                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(_profileImageUrl!)
                    : null) as ImageProvider?,
            child: _newProfileImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: const CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.edit, size: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCommonFields() {
    return [
      CustomTextField(
        label: 'First Name', hint: 'John', prefixIcon: Icons.person, 
        controller: _firstNameController, validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Last Name', hint: 'Doe', prefixIcon: Icons.person_outline,
        controller: _lastNameController, validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Phone', hint: '07...', prefixIcon: Icons.phone,
        controller: _phoneController, keyboardType: TextInputType.phone,
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Address', hint: '123 Main St...', prefixIcon: Icons.location_on,
        controller: _addressController, maxLines: 3,
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    ];
  }

  List<Widget> _buildHandymanFields() {
    return [
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: CustomTextField(
              label: 'Experience (Years)', hint: '5', prefixIcon: Icons.star,
              controller: _experienceController, keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomTextField(
              label: 'Hourly Rate (Rs)', hint: '1500', prefixIcon: Icons.attach_money,
              controller: _hourlyRateController, keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Bio / About Me', hint: 'Skills, work history...', prefixIcon: Icons.description,
        controller: _bioController, maxLines: 4,
      ),
    ];
  }
}
