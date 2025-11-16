// ==========================================
// FILE: lib/screens/profile/edit_profile_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

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
  final _firstNameController = TextEditingController(text: 'Amal');
  final _lastNameController = TextEditingController(text: 'Perera');
  final _emailController = TextEditingController(text: 'amal.perera@email.com');
  final _phoneController = TextEditingController(text: '0771234567');
  final _addressController = TextEditingController(text: '12 Lake Rd');
  final _cityController = TextEditingController(text: 'Kandy');
  final _provinceController = TextEditingController(text: 'Central');

  // Handyman specific
  final _experienceController = TextEditingController(text: '5');
  final _hourlyRateController = TextEditingController(text: '1500');

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Text(
                        'AP',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'First Name',
                      hint: 'John',
                      prefixIcon: Icons.person_outline,
                      controller: _firstNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Last Name',
                      hint: 'Doe',
                      prefixIcon: Icons.person_outline,
                      controller: _lastNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Email',
                hint: 'john.doe@email.com',
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Phone',
                hint: '077 123 4567',
                prefixIcon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Address Information
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Address Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Address',
                hint: '123 Main Street',
                prefixIcon: Icons.home_outlined,
                controller: _addressController,
              ),
              const SizedBox(height: 20),
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
                  const SizedBox(width: 16),
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

              // Handyman Specific Fields
              if (widget.isHandyman) ...[
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Professional Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Experience (Years)',
                        hint: '5',
                        prefixIcon: Icons.work_outline,
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Hourly Rate (Rs)',
                        hint: '1500',
                        prefixIcon: Icons.attach_money,
                        controller: _hourlyRateController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),
              CustomButton(
                text: 'Save Changes',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
