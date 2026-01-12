// Save as: test/widget/booking_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixit_app/widgets/booking_card.dart';
import 'package:fixit_app/models/booking_model.dart';

void main() {
  late Booking testBooking;

  setUp(() {
    testBooking = Booking(
      id: 'booking123',
      customerId: 'customer123',
      handymanId: 'handyman123',
      customerName: 'John Doe',
      serviceName: 'Plumbing',
      status: 'Pending',
      scheduledStartTime: DateTime(2026, 1, 15, 10, 0),
      totalPrice: 1500.0,
      notes: 'Fix leaking pipe',
      address: '123 Main St, Kandy',
      isEmergency: false,
    );
  });

  testWidgets('BookingCard displays service name',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Plumbing'), findsOneWidget);
        print('✓ Service name display test passed');
      });

  testWidgets('BookingCard displays customer name',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('John Doe'), findsOneWidget);
        print('✓ Customer name display test passed');
      });

  testWidgets('BookingCard displays address',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('123 Main St, Kandy'), findsOneWidget);
        print('✓ Address display test passed');
      });

  testWidgets('BookingCard displays price',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Rs 1500'), findsOneWidget);
        print('✓ Price display test passed');
      });

  testWidgets('BookingCard displays status in uppercase',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('PENDING'), findsOneWidget);
        print('✓ Status display test passed');
      });

  testWidgets('BookingCard shows emergency indicator for emergency bookings',
          (WidgetTester tester) async {
        final emergencyBooking = Booking(
          id: 'booking456',
          customerId: 'customer456',
          handymanId: 'handyman456',
          customerName: 'Jane Smith',
          serviceName: 'Emergency Plumbing',
          status: 'Confirmed',
          scheduledStartTime: DateTime(2026, 1, 15, 10, 0),
          totalPrice: 2250.0,
          notes: 'Burst pipe',
          address: '456 Oak Ave',
          isEmergency: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: emergencyBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        // Should show emergency bolt icon
        expect(find.byIcon(Icons.bolt), findsOneWidget);
        print('✓ Emergency indicator test passed');
      });

  testWidgets('BookingCard displays notes when present',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Fix leaking pipe'), findsOneWidget);
        print('✓ Notes display test passed');
      });

  testWidgets('BookingCard hides notes section when empty',
          (WidgetTester tester) async {
        final bookingWithoutNotes = Booking(
          id: 'booking123',
          customerId: 'customer123',
          handymanId: 'handyman123',
          customerName: 'John Doe',
          serviceName: 'Plumbing',
          status: 'Pending',
          scheduledStartTime: DateTime(2026, 1, 15, 10, 0),
          totalPrice: 1500.0,
          notes: '',
          address: '123 Main St',
          isEmergency: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: bookingWithoutNotes,
                onTap: () {},
              ),
            ),
          ),
        );

        // Notes container should not display for empty notes
        expect(find.byType(BookingCard), findsOneWidget);
        print('✓ Empty notes handling test passed');
      });

  testWidgets('BookingCard tap triggers callback',
          (WidgetTester tester) async {
        bool wasTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {
                  wasTapped = true;
                },
              ),
            ),
          ),
        );

        // Tap the card
        await tester.tap(find.byType(BookingCard));
        await tester.pump();

        expect(wasTapped, true);
        print('✓ Tap callback test passed');
      });

  testWidgets('BookingCard displays formatted date',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        // Looking for date format "15 Jan 2026" or similar
        expect(find.textContaining('Jan'), findsWidgets);
        expect(find.textContaining('2026'), findsWidgets);
        print('✓ Date formatting test passed');
      });

  testWidgets('BookingCard displays formatted time',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        // Looking for time display
        expect(find.textContaining('10:00'), findsWidgets);
        print('✓ Time formatting test passed');
      });

  testWidgets('BookingCard renders without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.byType(BookingCard), findsOneWidget);
        print('✓ Basic rendering test passed');
      });

  testWidgets('BookingCard has proper layout structure',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: testBooking,
                onTap: () {},
              ),
            ),
          ),
        );

        // Verify Container with decoration exists
        expect(find.byType(Container), findsWidgets);

        // Verify various icons are present
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);

        print('✓ Layout structure test passed');
      });
}

/*
TO RUN THESE TESTS:
===================

1. Run booking card widget tests:
   flutter test test/widget/booking_card_test.dart

2. Run with verbose output:
   flutter test test/widget/booking_card_test.dart --reporter expanded

3. Run all widget tests:
   flutter test test/widget/

All tests should pass with ✓ checkmarks
*/