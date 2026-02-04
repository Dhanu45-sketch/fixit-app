import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../home/customer_home_screen.dart';
import '../home/handyman_home_screen.dart';
import 'role_selection_screen.dart';
import 'approval_pending_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final String uid = snapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final bool isHandyman = userData['is_handyman'] ?? false;

                if (isHandyman) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('handymanProfiles')
                        .doc(uid)
                        .get(),
                    builder: (context, handymanSnapshot) {
                      if (handymanSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (handymanSnapshot.hasData && handymanSnapshot.data!.exists) {
                        final handymanData = handymanSnapshot.data!.data() as Map<String, dynamic>;
                        final String approvalStatus = handymanData['approval_status'] ?? 'pending';

                        switch (approvalStatus) {
                          case 'approved':
                            return const HandymanHomeScreen();
                          case 'pending':
                          case 'rejected':
                          case 'suspended':
                            return const ApprovalPendingScreen();
                          default:
                            return const ApprovalPendingScreen();
                        }
                      }

                      return const ApprovalPendingScreen();
                    },
                  );
                } else {
                  return const CustomerHomeScreen();
                }
              }

              return const CustomerHomeScreen();
            },
          );
        }

        return const RoleSelectionScreen();
      },
    );
  }
}
