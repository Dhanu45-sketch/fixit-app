import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fixit_app/screens/home/customer_home_screen.dart';
import 'package:fixit_app/screens/home/handyman_home_screen.dart';
import 'package:fixit_app/screens/auth/role_selection_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Listen to Firebase Auth state (Logged in vs Logged out)
    return StreamBuilder<User?>(
      // Using standard Firebase stream directly to avoid errors with custom service names
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If user is logged in (snapshot has data)
        if (snapshot.hasData && snapshot.data != null) {
          final String uid = snapshot.data!.uid;

          // Fetch the user's profile from Firestore to check their role
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnapshot) {
              // Show loading while fetching Firestore document
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Check if the document actually exists in Firestore
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;

                // Matches your Firestore field: 'is_handyman' (boolean)
                if (userData['is_handyman'] == true) {
                  return const HandymanHomeScreen();
                } else {
                  return const CustomerHomeScreen();
                }
              }

              // If user is logged in but no Firestore document found yet,
              // it usually means they are in the middle of registration.
              // Defaulting to CustomerHomeScreen, but you can change this to a setup screen.
              return const CustomerHomeScreen();
            },
          );
        }

        // 3. If user is NOT logged in, show the initial Role Selection screen
        return const RoleSelectionScreen();
      },
    );
  }
}