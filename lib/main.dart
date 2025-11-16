// ==========================================
// FIXIT APP - AUTHENTICATION SCREENS
// ==========================================
// NOTE: Add this import in your actual project:
// import 'package:fixit_app/screens/home/customer_home_screen.dart';

// ==========================================
// 1. main.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:fixit_app/screens/home/customer_home_screen.dart';
import 'package:fixit_app/screens/splash_screen.dart';
import '../../models/handyman_model.dart';
import '../../widgets/custom_button.dart';
import '../../utils/colors.dart';
import '../../widgets/booking_bottom_sheet.dart';

import '../../models/service_category_model.dart';

import '../../widgets/handyman_card.dart';
import '../../widgets/search_bar_widget.dart';
import 'package:fixit_app/screens/home/customer_home_screen.dart';
import 'package:fixit_app/screens/home/handyman_home_screen.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/colors.dart';

void main() {
  runApp(const FixItApp());
}

class FixItApp extends StatelessWidget {
  const FixItApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixIt - Handyman Services',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}