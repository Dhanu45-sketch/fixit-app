// Save as: test/unit/firestore_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Firestore - User Profile Operations', () {
    test('create user profile stores correct data', () async {
      // Arrange
      const userId = 'user123';
      final userData = {
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john@example.com',
        'phone': '0712345678',
        'is_handyman': false,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      };

      // Act
      await fakeFirestore.collection('users').doc(userId).set(userData);

      // Assert
      final doc = await fakeFirestore.collection('users').doc(userId).get();
      expect(doc.exists, true);
      expect(doc.data()?['first_name'], 'John');
      expect(doc.data()?['is_handyman'], false);

      print('✓ User profile creation test passed');
    });

    test('update user profile modifies existing data', () async {
      // Arrange - Create initial document
      const userId = 'user123';
      await fakeFirestore.collection('users').doc(userId).set({
        'first_name': 'John',
        'phone': '0712345678',
      });

      // Act - Update phone number
      await fakeFirestore.collection('users').doc(userId).update({
        'phone': '0771234567',
      });

      // Assert
      final doc = await fakeFirestore.collection('users').doc(userId).get();
      expect(doc.data()?['phone'], '0771234567');
      expect(doc.data()?['first_name'], 'John'); // Unchanged

      print('✓ User profile update test passed');
    });

    test('get user profile retrieves correct data', () async {
      // Arrange
      const userId = 'user456';
      await fakeFirestore.collection('users').doc(userId).set({
        'first_name': 'Jane',
        'last_name': 'Smith',
        'email': 'jane@example.com',
      });

      // Act
      final doc = await fakeFirestore.collection('users').doc(userId).get();

      // Assert
      expect(doc.exists, true);
      final data = doc.data();
      expect(data?['first_name'], 'Jane');
      expect(data?['email'], 'jane@example.com');

      print('✓ Get user profile test passed');
    });
  });

  group('Firestore - Handyman Profile Operations', () {
    test('create handyman profile with all required fields', () async {
      // Arrange
      const handymanId = 'handyman123';
      final handymanData = {
        'user_id': handymanId,
        'category_id': 'plumbing',
        'category_name': 'Plumbing',
        'experience': 5,
        'hourly_rate': 1500.0,
        'bio': 'Expert plumber',
        'rating_avg': 0.0,
        'jobs_completed': 0,
        'work_status': 'Available',
      };

      // Act
      await fakeFirestore.collection('handymanProfiles').doc(handymanId).set(handymanData);

      // Assert
      final doc = await fakeFirestore.collection('handymanProfiles').doc(handymanId).get();
      expect(doc.exists, true);
      expect(doc.data()?['category_id'], 'plumbing');
      expect(doc.data()?['hourly_rate'], 1500.0);
      expect(doc.data()?['work_status'], 'Available');

      print('✓ Handyman profile creation test passed');
    });

    test('query handymen by category', () async {
      // Arrange - Create multiple handymen
      await fakeFirestore.collection('handymanProfiles').add({
        'category_id': 'plumbing',
        'category_name': 'Plumbing',
        'rating_avg': 4.5,
      });

      await fakeFirestore.collection('handymanProfiles').add({
        'category_id': 'electrical',
        'category_name': 'Electrical',
        'rating_avg': 4.8,
      });

      // Act
      final snapshot = await fakeFirestore
          .collection('handymanProfiles')
          .where('category_id', isEqualTo: 'plumbing')
          .get();

      // Assert
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['category_name'], 'Plumbing');

      print('✓ Query handymen by category test passed');
    });

    test('get top rated handymen ordered by rating', () async {
      // Arrange - Create handymen with different ratings
      await fakeFirestore.collection('handymanProfiles').add({
        'category_name': 'Plumber A',
        'rating_avg': 4.5,
      });

      await fakeFirestore.collection('handymanProfiles').add({
        'category_name': 'Plumber B',
        'rating_avg': 4.9,
      });

      await fakeFirestore.collection('handymanProfiles').add({
        'category_name': 'Plumber C',
        'rating_avg': 4.2,
      });

      // Act
      final snapshot = await fakeFirestore
          .collection('handymanProfiles')
          .orderBy('rating_avg', descending: true)
          .limit(2)
          .get();

      // Assert
      expect(snapshot.docs.length, 2);
      expect(snapshot.docs.first.data()['rating_avg'], 4.9);
      expect(snapshot.docs.last.data()['rating_avg'], 4.5);

      print('✓ Top rated handymen query test passed');
    });
  });

  group('Firestore - Booking Operations', () {
    test('create booking with all required fields', () async {
      // Arrange
      final bookingData = {
        'customer_id': 'cust123',
        'handyman_id': 'hand123',
        'customer_name': 'John Doe',
        'service_name': 'Plumbing',
        'status': 'Pending',
        'scheduled_start_time': Timestamp.fromDate(DateTime(2026, 1, 15, 10, 0)),
        'total_price': 1500.0,
        'notes': 'Fix leaking pipe',
        'address': '123 Main St',
        'is_emergency': false,
      };

      // Act
      final docRef = await fakeFirestore.collection('bookings').add(bookingData);

      // Assert
      final doc = await fakeFirestore.collection('bookings').doc(docRef.id).get();
      expect(doc.exists, true);
      expect(doc.data()?['customer_name'], 'John Doe');
      expect(doc.data()?['status'], 'Pending');
      expect(doc.data()?['total_price'], 1500.0);

      print('✓ Booking creation test passed');
    });

    test('update booking status', () async {
      // Arrange
      final docRef = await fakeFirestore.collection('bookings').add({
        'status': 'Pending',
        'customer_id': 'cust123',
      });

      // Act
      await fakeFirestore.collection('bookings').doc(docRef.id).update({
        'status': 'Confirmed',
      });

      // Assert
      final doc = await fakeFirestore.collection('bookings').doc(docRef.id).get();
      expect(doc.data()?['status'], 'Confirmed');

      print('✓ Booking status update test passed');
    });

    test('query customer bookings', () async {
      // Arrange
      const customerId = 'cust123';
      await fakeFirestore.collection('bookings').add({
        'customer_id': customerId,
        'service_name': 'Plumbing',
        'status': 'Pending',
      });

      await fakeFirestore.collection('bookings').add({
        'customer_id': 'other_customer',
        'service_name': 'Electrical',
        'status': 'Confirmed',
      });

      // Act
      final snapshot = await fakeFirestore
          .collection('bookings')
          .where('customer_id', isEqualTo: customerId)
          .get();

      // Assert
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['service_name'], 'Plumbing');

      print('✓ Query customer bookings test passed');
    });

    test('query handyman bookings by status', () async {
      // Arrange
      const handymanId = 'hand123';
      await fakeFirestore.collection('bookings').add({
        'handyman_id': handymanId,
        'status': 'Pending',
      });

      await fakeFirestore.collection('bookings').add({
        'handyman_id': handymanId,
        'status': 'Confirmed',
      });

      // Act - Get only pending bookings
      final snapshot = await fakeFirestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .where('status', isEqualTo: 'Pending')
          .get();

      // Assert
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['status'], 'Pending');

      print('✓ Query handyman bookings by status test passed');
    });
  });

  group('Firestore - Notification Operations', () {
    test('create notification', () async {
      // Arrange
      final notifData = {
        'recipientId': 'user123',
        'title': 'New Booking',
        'message': 'You have a new booking request',
        'type': 'booking',
        'bookingId': 'booking123',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Act
      await fakeFirestore.collection('notifications').add(notifData);

      // Assert
      final snapshot = await fakeFirestore.collection('notifications').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'New Booking');
      expect(snapshot.docs.first.data()['isRead'], false);

      print('✓ Notification creation test passed');
    });

    test('mark notification as read', () async {
      // Arrange
      final docRef = await fakeFirestore.collection('notifications').add({
        'recipientId': 'user123',
        'title': 'Test Notification',
        'isRead': false,
      });

      // Act
      await fakeFirestore.collection('notifications').doc(docRef.id).update({
        'isRead': true,
      });

      // Assert
      final doc = await fakeFirestore.collection('notifications').doc(docRef.id).get();
      expect(doc.data()?['isRead'], true);

      print('✓ Mark notification as read test passed');
    });
  });

  group('Firestore - Service Category Operations', () {
    test('get all active service categories', () async {
      // Arrange
      await fakeFirestore.collection('serviceCategories').add({
        'name': 'Plumbing',
        'icon': '🔧',
        'is_active': true,
      });

      await fakeFirestore.collection('serviceCategories').add({
        'name': 'Electrical',
        'icon': '⚡',
        'is_active': false,
      });

      // Act
      final snapshot = await fakeFirestore
          .collection('serviceCategories')
          .where('is_active', isEqualTo: true)
          .get();

      // Assert
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['name'], 'Plumbing');

      print('✓ Get active categories test passed');
    });
  });
}

/*
TO RUN THESE TESTS:
===================

1. Make sure you have the dependencies:
   flutter pub get

2. Run all Firestore tests:
   flutter test test/unit/firestore_service_test.dart

3. Run with coverage:
   flutter test test/unit/firestore_service_test.dart --coverage

4. All tests should show green checkmarks ✓
*/