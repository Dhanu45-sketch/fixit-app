// integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fixit_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FixIt App - End-to-End Tests', () {

    testWidgets('App launch and Customer basic flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final bool hasRoleSelection = find.text('Welcome to FixIt').evaluate().isNotEmpty;
      
      if (hasRoleSelection) {
        await tester.tap(find.text('I am a Customer'));
        await tester.pumpAndSettle();
        expect(find.text('Customer Login'), findsOneWidget);

        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expect(find.text('Customer Registration'), findsOneWidget);
        
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Customer Login'), findsOneWidget);
      } else {
        print('Skipping role selection: App already logged in');
      }
      print('✓ Customer navigation testing finished');
    });

    testWidgets('Handyman Side Testing (Login with existing account)', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 1. Ensure we are at Role Selection (logout if needed)
      final bool isHome = find.text('Welcome Back! 👋').evaluate().isNotEmpty || 
                         find.text('Browse Categories').evaluate().isNotEmpty;
      
      if (isHome) {
        final profileIcon = find.byIcon(Icons.person);
        if (profileIcon.evaluate().isNotEmpty) {
          await tester.tap(profileIcon);
          await tester.pumpAndSettle();
          
          final logoutIcon = find.byIcon(Icons.logout);
          if (logoutIcon.evaluate().isNotEmpty) {
            await tester.tap(logoutIcon);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Logout'));
            await tester.pumpAndSettle(const Duration(seconds: 5));
          }
        }
      }

      // 2. Navigate to Handyman Login
      if (find.text('Welcome to FixIt').evaluate().isNotEmpty) {
        await tester.tap(find.text('I am a Handyman'));
        await tester.pumpAndSettle();
      }
      
      expect(find.text('Handyman Login'), findsOneWidget);

      // 3. Login with provided credentials - Updated to match Sign In button text
      await tester.enterText(find.byType(TextField).at(0), 'ww5@email.com');
      await tester.enterText(find.byType(TextField).at(1), '12345678');
      
      // The button text is actually "Sign In", not "Login"
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 4. Verify landing
      final bool atHome = find.text('Welcome Back! 👋').evaluate().isNotEmpty;
      final bool atPending = find.text('Approval Pending').evaluate().isNotEmpty;
      
      expect(atHome || atPending, true);
      print('✓ Handyman side testing finished');
    });

    /* 
    // TEMPORARILY DISABLED: Handyman Registration Flow
    testWidgets('Handyman Registration Flow (Full Step-by-Step)', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Ensure logged out
      final bool hasProfile = find.byIcon(Icons.person).evaluate().isNotEmpty || 
                             find.text('Welcome Back! 👋').evaluate().isNotEmpty;
      
      if (hasProfile) {
        final profileIcon = find.byIcon(Icons.person);
        if (profileIcon.evaluate().isNotEmpty) {
          await tester.tap(profileIcon);
          await tester.pumpAndSettle();
          final logout = find.byIcon(Icons.logout);
          if (logout.evaluate().isNotEmpty) {
            await tester.tap(logout);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Logout'));
            await tester.pumpAndSettle(const Duration(seconds: 5));
          }
        }
      }

      if (find.text('Welcome to FixIt').evaluate().isNotEmpty) {
        await tester.tap(find.text('I am a Handyman'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Step 1: Professional Info
        await tester.enterText(find.byType(TextField).at(0), 'Integrated');
        await tester.enterText(find.byType(TextField).at(1), 'Test');
        final testEmail = 'integration_${DateTime.now().millisecondsSinceEpoch}@test.com';
        await tester.enterText(find.byType(TextField).at(2), testEmail);
        await tester.enterText(find.byType(TextField).at(3), '0771234567');
        await tester.enterText(find.byType(TextField).at(4), 'password123');
        await tester.enterText(find.byType(TextField).at(5), 'password123');

        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(6), '5');
        await tester.enterText(find.byType(TextField).at(7), '1500');
        
        await tester.tap(find.text('Continue to Verification'));
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Step 2: Documents
        if (find.text('Step 2/4').evaluate().isNotEmpty) {
          await tester.tap(find.text('Upload Later'));
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Step 3: Privacy Control
          if (find.text('Step 3: Privacy Control').evaluate().isNotEmpty) {
            await tester.tap(find.text('Next: Set Service Area'));
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Step 4: Service Area (Map)
            expect(find.text('Step 4: Service Area'), findsOneWidget);
            print('✓ Handyman registration flow passed Step 4');
          }
        }
      }
      print('✓ Handyman registration flow testing finished');
    });
    */
  });
}
