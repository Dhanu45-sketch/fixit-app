import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isHandyman;

  const EditProfileScreen({
    Key? key,
    this.isHandyman = false,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _picker = ImagePicker();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;
  File? _imageFile;
  String? _existingProfileUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _cityController.text = data['city'] ?? '';
          _provinceController.text = data['province'] ?? '';
          _existingProfileUrl = data['profile_image'];
        });
      }

      if (widget.isHandyman && mounted) {
        final hpDoc = await FirebaseFirestore.instance.collection('handymanProfiles').doc(userId).get();
        if (hpDoc.exists) {
          final hpData = hpDoc.data()!;
          setState(() {
            _experienceController.text = hpData['experience']?.toString() ?? '0';
            _hourlyRateController.text = hpData['hourly_rate']?.toString() ?? '0';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      batch.set(userRef, {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (widget.isHandyman) {
        final hpRef = FirebaseFirestore.instance.collection('handymanProfiles').doc(userId);
        batch.set(hpRef, {
          'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
          'hourly_rate': double.tryParse(_hourlyRateController.text.trim()) ?? 0.0,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildPhotoPicker(),
              const SizedBox(height: 32),
              _buildPersonalFields(),
              const SizedBox(height: 32),
              _buildAddressFields(),
              if (widget.isHandyman) ...[
                const SizedBox(height: 32),
                _buildProfessionalFields(),
              ],
              const SizedBox(height: 40),

              CustomButton(
                text: 'Save Changes',
                onPressed: _isLoading ? () {} : _saveProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : (_existingProfileUrl != null ? NetworkImage(_existingProfileUrl!) as ImageProvider : null),
              child: (_imageFile == null && _existingProfileUrl == null)
                  ? Text(
                _firstNameController.text.isNotEmpty ? _firstNameController.text[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
              )
                  : null,
            ),
            const Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 18,
                child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'First Name',
          hint: 'Enter first name',
          prefixIcon: Icons.person_outline,
          controller: _firstNameController,
          validator: (value) => value!.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Last Name',
          hint: 'Enter last name',
          prefixIcon: Icons.person_outline,
          controller: _lastNameController,
          validator: (value) => value!.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Phone',
          hint: '07X XXX XXXX',
          prefixIcon: Icons.phone_android,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Location Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Street Address',
          hint: '123 Main St',
          prefixIcon: Icons.location_on_outlined,
          controller: _addressController,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'City',
                hint: 'Kandy',
                prefixIcon: Icons.location_city,
                controller: _cityController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Province',
                hint: 'Central',
                prefixIcon: Icons.map_outlined,
                controller: _provinceController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Work Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Experience',
                hint: 'Years',
                prefixIcon: Icons.timeline,
                controller: _experienceController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Rate',
                hint: 'Rs/Hr',
                prefixIcon: Icons.payments_outlined,
                controller: _hourlyRateController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}