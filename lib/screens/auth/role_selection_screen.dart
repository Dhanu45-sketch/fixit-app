// ==========================================
// 8. screens/auth/role_selection_screen.dart
// ==========================================
import 'package:fixit_app/screens/home/customer_home_screen.dart';
import 'package:flutter/material.dart';
import '../../models/handyman_model.dart';
import '../../widgets/custom_button.dart';
import '../../utils/colors.dart';
import '../../widgets/booking_bottom_sheet.dart';
import 'package:flutter/material.dart';
import '../../models/service_category_model.dart';
import '../../models/handyman_model.dart';
import '../../widgets/category_card.dart';
import '../../widgets/handyman_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../utils/colors.dart';
import 'package:fixit_app/screens/auth/role_selection_screen.dart';
import 'package:fixit_app/screens/auth/register_screen.dart';
import 'package:fixit_app/screens/auth/login_screen.dart';
import '../services/service_detail_screen.dart';
import '../handyman/handyman_detail_screen.dart';
import '../../widgets/custom_textfield.dart';
import 'package:fixit_app/screens/home/customer_home_screen.dart';
import 'package:fixit_app/screens/home/handyman_home_screen.dart';
import '../services/service_detail_screen.dart';
import '../handyman/handyman_detail_screen.dart';



// ==========================================
// FILE: lib/screens/auth/role_selection_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../home/customer_home_screen.dart';
import '../home/handyman_home_screen.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Choose Your Role',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How would you like to use FixIt?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoleCard(
                        icon: Icons.person_outline,
                        title: 'I need services',
                        subtitle: 'Find and book handymen for your needs',
                        color: Colors.white,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _RoleCard(
                        icon: Icons.build_outlined,
                        title: 'I provide services',
                        subtitle: 'Offer your skills and get hired',
                        color: Colors.white,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HandymanHomeScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}