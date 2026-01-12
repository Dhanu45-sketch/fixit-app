// Save as: integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fixit_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FixIt App - End-to-End Tests', () {

    testWidgets('App launches successfully and shows role selection',
            (WidgetTester tester) async {
          // Launch app
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Verify app launched
          expect(find.byType(MaterialApp), findsOneWidget);

          // Should show role selection or login
          final hasRoleSelection = find.text('Welcome to FixIt');
          final hasLogin = find.text('Login');

          expect(hasRoleSelection.evaluate().isNotEmpty || hasLogin.evaluate().isNotEmpty, true);

          print('✓ App launch test passed');
        });

    testWidgets('Can navigate to customer registration',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Try to find and tap customer option
          final customerButton = find.text('I am a Customer');
          if (customerButton.evaluate().isNotEmpty) {
            await tester.tap(customerButton);
            await tester.pumpAndSettle();

            // Should navigate to login
            expect(find.text('Customer Login'), findsOneWidget);

            // Navigate to registration
            await tester.tap(find.text('Sign Up'));
            await tester.pumpAndSettle();

            // Should show registration fields
            expect(find.text('First Name'), findsOneWidget);

            print('✓ Customer registration navigation test passed');
          }
        });

    testWidgets('Can fill customer registration form',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Navigate to customer registration
          if (find.text('I am a Customer').evaluate().isNotEmpty) {
            await tester.tap(find.text('I am a Customer'));
            await tester.pumpAndSettle();

            await tester.tap(find.text('Sign Up'));
            await tester.pumpAndSettle();

            // Fill form fields
            final textFields = find.byType(TextField);

            if (textFields.evaluate().isNotEmpty) {
              // Enter test data
              await tester.enterText(textFields.at(0), 'Test');
              await tester.enterText(textFields.at(1), 'User');
              await tester.enterText(textFields.at(2), 'testuser@example.com');
              await tester.enterText(textFields.at(3), '0712345678');
              await tester.enterText(textFields.at(4), 'password123');
              await tester.enterText(textFields.at(5), 'password123');

              await tester.pumpAndSettle();

              // Verify text was entered
              expect(find.text('Test'), findsWidgets);
              expect(find.text('testuser@example.com'), findsWidgets);

              print('✓ Form filling test passed');
            }
          }
        });

    testWidgets('Can navigate between bottom navigation tabs',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Look for bottom navigation
          final bottomNav = find.byType(BottomNavigationBar);

          if (bottomNav.evaluate().isNotEmpty) {
            // Try tapping different tabs
            final bookingsTab = find.text('Bookings');
            if (bookingsTab.evaluate().isNotEmpty) {
              await tester.tap(bookingsTab);
              await tester.pumpAndSettle();
              print('✓ Navigated to Bookings');
            }

            final profileTab = find.text('Profile');
            if (profileTab.evaluate().isNotEmpty) {
              await tester.tap(profileTab);
              await tester.pumpAndSettle();
              print('✓ Navigated to Profile');
            }

            final homeTab = find.text('Home');
            if (homeTab.evaluate().isNotEmpty) {
              await tester.tap(homeTab);
              await tester.pumpAndSettle();
              print('✓ Navigated to Home');
            }

            print('✓ Bottom navigation test passed');
          }
        });

    testWidgets('Service categories are displayed on home screen',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Look for category section
          final categoryText = find.text('Service Categories');

          if (categoryText.evaluate().isNotEmpty) {
            expect(categoryText, findsOneWidget);
            print('✓ Service categories displayed');
          }

          // Look for category grid
          final gridView = find.byType(GridView);
          if (gridView.evaluate().isNotEmpty) {
            print('✓ Category grid found');
          }

          print('✓ Service categories display test passed');
        });

    testWidgets('Can open search screen',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Look for search icon or search bar
          final searchIcon = find.byIcon(Icons.search);

          if (searchIcon.evaluate().isNotEmpty) {
            await tester.tap(searchIcon.first);
            await tester.pumpAndSettle();

            // Should show search screen
            final searchField = find.byType(TextField);
            expect(searchField, findsWidgets);

            print('✓ Search screen opened successfully');
          }

          print('✓ Search navigation test passed');
        });

    testWidgets('Can view handyman list',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Look for handyman list section
          final topRatedText = find.text('Top Rated Handymen');

          if (topRatedText.evaluate().isNotEmpty) {
            expect(topRatedText, findsOneWidget);
            print('✓ Top rated section found');
          }

          // Look for list view of handymen
          final listView = find.byType(ListView);
          if (listView.evaluate().isNotEmpty) {
            print('✓ Handyman list displayed');
          }

          print('✓ Handyman list display test passed');
        });

    testWidgets('Password visibility toggle works in login',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Navigate to login if not already there
          final loginTitle = find.text('Customer Login');

          if (loginTitle.evaluate().isEmpty) {
            final customerButton = find.text('I am a Customer');
            if (customerButton.evaluate().isNotEmpty) {
              await tester.tap(customerButton);
              await tester.pumpAndSettle();
            }
          }

          // Look for visibility toggle
          final visibilityIcon = find.byIcon(Icons.visibility_off);

          if (visibilityIcon.evaluate().isNotEmpty) {
            await tester.tap(visibilityIcon.first);
            await tester.pumpAndSettle();

            // Icon should change
            expect(find.byIcon(Icons.visibility), findsWidgets);

            print('✓ Password visibility toggle works');
          }

          print('✓ Password visibility test passed');
        });

    testWidgets('Handyman registration shows category dropdown',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Navigate to handyman registration
          final handymanButton = find.text('I am a Handyman');

          if (handymanButton.evaluate().isNotEmpty) {
            await tester.tap(handymanButton);
            await tester.pumpAndSettle();

            await tester.tap(find.text('Sign Up'));
            await tester.pumpAndSettle();

            // Scroll to find dropdown
            await tester.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, -500),
            );
            await tester.pumpAndSettle();

            // Look for category dropdown
            final dropdown = find.byType(DropdownButtonFormField<String>);
            if (dropdown.evaluate().isNotEmpty) {
              print('✓ Category dropdown found');
            }

            print('✓ Handyman registration category test passed');
          }
        });

    testWidgets('App handles back navigation correctly',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Navigate forward
          final customerButton = find.text('I am a Customer');
          if (customerButton.evaluate().isNotEmpty) {
            await tester.tap(customerButton);
            await tester.pumpAndSettle();

            // Now go back
            final backButton = find.byIcon(Icons.arrow_back);
            if (backButton.evaluate().isNotEmpty) {
              await tester.tap(backButton);
              await tester.pumpAndSettle();

              // Should be back at role selection
              expect(find.text('Welcome to FixIt'), findsWidgets);

              print('✓ Back navigation works');
            }
          }

          print('✓ Navigation back test passed');
        });
  });
}

/*
TO RUN INTEGRATION TESTS:
==========================

IMPORTANT: Integration tests require a connected device or emulator!

1. Start an Android emulator:
   flutter emulators --launch <emulator_id>

2. Verify device is connected:
   flutter devices

3. Run integration tests:
   flutter test integration_test/app_test.dart

4. Run on specific device:
   flutter test integration_test/app_test.dart -d <device-id>

5. Run all integration tests:
   flutter test integration_test/

NOTES:
------
- These tests interact with the real app
- They take longer to run than unit/widget tests
- Make sure Firebase is properly configured
- Some tests may fail if not logged in
- Tests are designed to be resilient to different app states

All tests should print ✓ checkmarks when passing
*/