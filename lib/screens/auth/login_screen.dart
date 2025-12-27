import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../home/customer_home_screen.dart';
import '../home/handyman_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isHandyman;

  const LoginScreen({Key? key, required this.isHandyman}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Firebase Auth Sign In
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Profile and Role Verification
      final userProfile = await _authService.getCurrentUserProfile();

      if (userProfile == null) {
        await _authService.signOut(); // Sign out to prevent inconsistent state
        if (mounted) {
          setState(() => _errorMessage = "User profile not found. Please register.");
        }
        return;
      }

      final bool isHandymanProfile = userProfile['is_handyman'] ?? false;
      if (isHandymanProfile != widget.isHandyman) {
        await _authService.signOut();
        final portalType = isHandymanProfile ? 'Handyman' : 'Customer';
        if (mounted) {
          setState(() => _errorMessage = "Incorrect login portal. Use the $portalType login.");
        }
        return;
      }

      // 3. Navigate to the correct home screen
      if (mounted) {
        final homeScreen =
        isHandymanProfile ? const HandymanHomeScreen() : const CustomerHomeScreen();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => homeScreen),
              (route) => false, // Clears the navigation stack
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          message = 'Invalid email or password.';
          break;
        default:
          message = 'Login failed. Please try again.';
      }
      if (mounted) {
        setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isHandyman ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Icon(
                  widget.isHandyman ? Icons.handyman : Icons.person,
                  size: 64,
                  color: themeColor,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isHandyman ? 'Handyman Login' : 'Customer Login',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your ${widget.isHandyman ? 'pro' : ''} account',
                  style: const TextStyle(fontSize: 16, color: AppColors.textLight),
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null) _buildErrorBox(),

                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter your password' : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textLight),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 32),

                // FIXED SECTION: Correctly handling the loading state for the button
                CustomButton(
                  text: 'Sign In',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? () {} : _handleLogin,
                ),

                const SizedBox(height: 24),
                _buildSignUpRow(themeColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
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
          Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSignUpRow(Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ", style: TextStyle(color: AppColors.textLight)),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RegisterScreen(isHandyman: widget.isHandyman)),
          ),
          child: Text('Sign Up', style: TextStyle(color: themeColor, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}