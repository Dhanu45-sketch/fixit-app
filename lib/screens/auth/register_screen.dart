// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/document_upload_widget.dart';
import '../home/customer_home_screen.dart';
import '../settings/handyman_privacy_registration.dart'; // Import this
import 'approval_pending_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isHandyman;

  const RegisterScreen({super.key, this.isHandyman = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Handyman Specific Fields
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _bioController = TextEditingController();

  bool _acceptsEmergencies = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  int _currentStep = 0; 
  String? _registeredUserId;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (widget.isHandyman && _selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select a service category');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isHandyman) {
        final result = await _authService.registerHandyman(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          categoryId: _selectedCategoryId!,
          categoryName: _selectedCategoryName!,
          experience: int.tryParse(_experienceController.text) ?? 0,
          hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0.0,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          acceptsEmergencies: _acceptsEmergencies,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _currentStep = 1; // Move to Documents
            _registeredUserId = result?.user?.uid;
          });
        }
      } else {
        await _authService.registerCustomer(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isHandyman ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHandyman ? 'Handyman Registration' : 'Customer Registration'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: widget.isHandyman && _currentStep == 1 
            ? _buildDocumentStep() 
            : _buildRegistrationForm(),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) _buildErrorWidget(),

          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildBasicFields(),

          if (widget.isHandyman) ...[
            const SizedBox(height: 32),
            const Text(
              'Professional Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildProfessionalFields(),
            const SizedBox(height: 32),
            _buildEmergencySection(),
          ],

          const SizedBox(height: 32),

          CustomButton(
            text: widget.isHandyman ? 'Continue to Verification' : 'Register as Customer',
            onPressed: _handleRegister,
            isLoading: _isLoading,
          ),

          const SizedBox(height: 16),
          _buildLoginRedirect(),
        ],
      ),
    );
  }

  Widget _buildDocumentStep() {
    return Column(
      children: [
        _buildProgressHeader('Step 2/4', 'Identity Verification'),
        const SizedBox(height: 24),
        
        DocumentUploadWidget(
          userId: _registeredUserId!,
          onUploadComplete: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HandymanPrivacySettings(),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HandymanPrivacySettings(),
              ),
            );
          },
          child: const Text('Upload Later', style: TextStyle(color: AppColors.textLight)),
        ),
      ],
    );
  }

  Widget _buildProgressHeader(String stepText, String title) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(stepText, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _acceptsEmergencies ? Colors.red.shade50 : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _acceptsEmergencies ? Colors.red.shade300 : Colors.grey.shade300,
          width: _acceptsEmergencies ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emergency,
                color: _acceptsEmergencies ? Colors.red.shade700 : AppColors.textLight,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Emergency Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: _acceptsEmergencies,
                onChanged: (value) => setState(() => _acceptsEmergencies = value),
                activeColor: Colors.red.shade700,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _acceptsEmergencies
                ? '✅ You will receive emergency job requests'
                : 'Offer 24/7 emergency services to customers',
            style: TextStyle(
              fontSize: 13,
              color: _acceptsEmergencies ? Colors.red.shade700 : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicFields() {
    return Column(
      children: [
        CustomTextField(
          label: 'First Name',
          hint: 'Enter your first name',
          prefixIcon: Icons.person_outline,
          controller: _firstNameController,
          validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Last Name',
          hint: 'Enter your last name',
          prefixIcon: Icons.person_outline,
          controller: _lastNameController,
          validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Email',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) return 'Required';
            if (!value!.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Phone Number',
          hint: '07XXXXXXXX',
          prefixIcon: Icons.phone_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Password',
          hint: 'Min 8 characters',
          prefixIcon: Icons.lock_outline,
          controller: _passwordController,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) => (value?.length ?? 0) < 8 ? 'Min 8 characters' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Confirm Password',
          hint: 'Re-enter password',
          prefixIcon: Icons.lock_outline,
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getServiceCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No categories found.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          );
        }

        final categories = snapshot.data!;

        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Service Category',
            prefixIcon: const Icon(Icons.category_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          value: _selectedCategoryId,
          items: categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['id'],
              child: Text('${cat['icon'] ?? '🔧'} ${cat['name'].toString().replaceAll('_', ' ')}'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCategoryId = val;
              _selectedCategoryName = categories.firstWhere((c) => c['id'] == val)['name'];
            });
          },
          validator: (value) => value == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildProfessionalFields() {
    return Column(
      children: [
        CustomTextField(
          label: 'Years of Experience',
          hint: 'e.g., 5',
          prefixIcon: Icons.work_outline,
          controller: _experienceController,
          keyboardType: TextInputType.number,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Hourly Rate (LKR)',
          hint: 'e.g., 1500',
          prefixIcon: Icons.payments_outlined,
          controller: _hourlyRateController,
          keyboardType: TextInputType.number,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Bio',
          hint: 'Tell customers about your expertise...',
          prefixIcon: Icons.info_outline,
          controller: _bioController,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildLoginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ', style: TextStyle(color: AppColors.textLight)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
