
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixit_app/services/firestore_service.dart';
import 'package:fixit_app/services/storage_service.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isHandyman;

  const RegisterScreen({Key? key, this.isHandyman = false}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  File? _profileImageFile;
  final List<File> _certificateFiles = [];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final file = await _storageService.pickImageFromGallery();
    if (file != null) setState(() => _profileImageFile = file);
  }

  Future<void> _pickCertificates() async {
    final files = await _storageService.pickMultipleImages();
    setState(() => _certificateFiles.addAll(files));
  }

  void _removeCertificate(int index) {
    setState(() => _certificateFiles.removeAt(index));
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isHandyman && _selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select a service category');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential? userCredential;
      if (widget.isHandyman) {
        userCredential = await _authService.registerHandyman(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          categoryId: _selectedCategoryId!,
          categoryName: _selectedCategoryName!,
          experience: int.parse(_experienceController.text.trim()),
          hourlyRate: double.parse(_hourlyRateController.text.trim()),
          bio: _bioController.text.trim(),
        );
      } else {
        userCredential = await _authService.registerCustomer(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (userCredential == null) throw Exception("User creation failed.");
      final userId = userCredential.user!.uid;

      final profilePicFuture = _profileImageFile != null
          ? _storageService.uploadProfilePicture(userId: userId, imageFile: _profileImageFile!)
          : Future.value(null);

      final certificatesFuture = (widget.isHandyman && _certificateFiles.isNotEmpty)
          ? _storageService.uploadMultipleCertificates(userId: userId, imageFiles: _certificateFiles)
          : Future.value(<String>[]);
      
      final results = await Future.wait([profilePicFuture, certificatesFuture]);
      final profileImageUrl = results[0] as String?;
      final certificateUrls = results[1] as List<String>;

      final List<Future<void>> updateFutures = [];
      if (profileImageUrl != null) {
        updateFutures.add(_firestoreService.updateUserProfile(userId, {'profile_image': profileImageUrl}));
      }
      if (certificateUrls.isNotEmpty) {
        updateFutures.add(_firestoreService.updateHandymanProfile(userId, {'certificates': certificateUrls}));
      }
      if (updateFutures.isNotEmpty) {
        await Future.wait(updateFutures);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen(isHandyman: widget.isHandyman)),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = "Registration failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isHandyman ? 'Handyman Registration' : 'Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ),
              _buildProfilePicturePicker(),
              const SizedBox(height: 20),
              ..._buildCommonFields(),
              if (widget.isHandyman) ..._buildHandymanFields(),
              const SizedBox(height: 30),
              CustomButton(
                text: 'Register',
                onPressed: _handleRegister,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicturePicker() {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
        child: _profileImageFile == null 
            ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade500) 
            : null,
      ),
    );
  }

  List<Widget> _buildCommonFields() {
    return [
      CustomTextField(
        label: 'First Name', hint: 'John', prefixIcon: Icons.person,
        controller: _firstNameController,
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Last Name', hint: 'Doe', prefixIcon: Icons.person_outline,
        controller: _lastNameController,
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Email', hint: 'you@example.com', prefixIcon: Icons.email_outlined,
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Phone', hint: '07...', prefixIcon: Icons.phone,
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Password', hint: '********', prefixIcon: Icons.lock_outline,
        controller: _passwordController,
        obscureText: _obscurePassword,
        validator: (v) => v!.length < 6 ? '6+ characters required' : null,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Confirm Password', hint: '********', prefixIcon: Icons.lock,
        controller: _confirmPasswordController,
        obscureText: true,
        validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
      ),
    ];
  }

  List<Widget> _buildHandymanFields() {
    return [
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 20),
      _buildCategoryDropdown(),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: CustomTextField(
              label: 'Experience (Years)', hint: '5', prefixIcon: Icons.star,
              controller: _experienceController,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomTextField(
              label: 'Hourly Rate (Rs)', hint: '1500', prefixIcon: Icons.attach_money,
              controller: _hourlyRateController,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Bio', hint: 'Skills, work history...', prefixIcon: Icons.description,
        controller: _bioController,
        maxLines: 3,
      ),
      const SizedBox(height: 20),
      _buildCertificatesSection(),
    ];
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getServiceCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          hint: const Text('Select Service Category'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.category)
          ),
          items: snapshot.data!.map<DropdownMenuItem<String>>((category) {
            return DropdownMenuItem<String>(
              value: category['id'].toString(), 
              child: Text(category['name'])
            );
          }).toList(),
          onChanged: (value) {
            final selected = snapshot.data!.firstWhere((c) => c['id'] == value, orElse: () => {});
            if (selected.isNotEmpty) {
              setState(() {
                _selectedCategoryId = value;
                _selectedCategoryName = selected['name'];
              });
            }
          },
          validator: (v) => v == null ? 'Category is required' : null,
        );
      },
    );
  }

  Widget _buildCertificatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Certificates (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300)
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._certificateFiles.map((file) {
                return Chip(
                  label: Text(file.path.split('/').last, overflow: TextOverflow.ellipsis), 
                  onDeleted: () => _removeCertificate(_certificateFiles.indexOf(file)),
                  deleteIconColor: AppColors.error,
                  );
              }).toList(),
              ActionChip(
                avatar: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Add Files'),
                onPressed: _pickCertificates,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
