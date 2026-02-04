// test/unit/firestore_service_test_updated.dart
// UPDATED: Handyman tests moved to end

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ============================================
  // CUSTOMER TESTS - RUN FIRST
  // ============================================

  group('Firestore - Customer Profile Operations', () {
    test('create customer profile stores correct data', () async {
      // Arrange
      const userId = 'customer123';
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

      print('✓ Customer profile creation test passed');
    });

    test('update customer profile modifies existing data', () async {
      // Arrange - Create initial document
      const userId = 'customer123';
      await fakeFirestore.collection('users').doc(userId).set({
        'first_name': 'John',
        'phone': '0712345678',
        'is_handyman': false,
      });

      // Act - Update phone number
      await fakeFirestore.collection('users').doc(userId).update({
        'phone': '0771234567',
      });

      // Assert
      final doc = await fakeFirestore.collection('users').doc(userId).get();
      expect(doc.data()?['phone'], '0771234567');
      expect(doc.data()?['first_name'], 'John'); // Unchanged

      print('✓ Customer profile update test passed');
    });

    test('get customer profile retrieves correct data', () async {
      // Arrange
      const userId = 'customer456';
      await fakeFirestore.collection('users').doc(userId).set({
        'first_name': 'Jane',
        'last_name': 'Smith',
        'email': 'jane@example.com',
        'is_handyman': false,
      });

      // Act
      final doc = await fakeFirestore.collection('users').doc(userId).get();

      // Assert
      expect(doc.exists, true);
      final data = doc.data();
      expect(data?['first_name'], 'Jane');
      expect(data?['email'], 'jane@example.com');
      expect(data?['is_handyman'], false);

      print('✓ Get customer profile test passed');
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
        'has_review': false,
      };

      // Act
      final docRef = await fakeFirestore.collection('bookings').add(bookingData);

      // Assert
      final doc = await fakeFirestore.collection('bookings').doc(docRef.id).get();
      expect(doc.exists, true);
      expect(doc.data()?['customer_name'], 'John Doe');
      expect(doc.data()?['status'], 'Pending');
      expect(doc.data()?['total_price'], 1500.0);
      expect(doc.data()?['has_review'], false);

      print('✓ Booking creation test passed');
    });

    test('update booking status', () async {
      // Arrange
      final docRef = await fakeFirestore.collection('bookings').add({
        'status': 'Pending',
        'customer_id': 'cust123',
        'has_review': false,
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

    test('mark booking as reviewed', () async {
      // Arrange
      final docRef = await fakeFirestore.collection('bookings').add({
        'customer_id': 'cust123',
        'status': 'Completed',
        'has_review': false,
      });

      // Act - Customer submits review
      await fakeFirestore.collection('bookings').doc(docRef.id).update({
        'has_review': true,
      });

      // Assert
      final doc = await fakeFirestore.collection('bookings').doc(docRef.id).get();
      expect(doc.data()?['has_review'], true);

      print('✓ Mark booking as reviewed test passed');
    });
  });

  group('Firestore - Review Operations', () {
    test('create review', () async {
      // Arrange
      final reviewData = {
        'booking_id': 'booking123',
        'customer_id': 'cust123',
        'handyman_id': 'hand123',
        'customer_name': 'John Doe',
        'rating': 5.0,
        'comment': 'Excellent service!',
        'created_at': FieldValue.serverTimestamp(),
      };

      // Act
      final docRef = await fakeFirestore.collection('reviews').add(reviewData);

      // Assert
      final doc = await fakeFirestore.collection('reviews').doc(docRef.id).get();
      expect(doc.exists, true);
      expect(doc.data()?['rating'], 5.0);
      expect(doc.data()?['comment'], 'Excellent service!');

      print('✓ Create review test passed');
    });

    test('query reviews for handyman', () async {
      // Arrange
      const handymanId = 'hand123';
      await fakeFirestore.collection('reviews').add({
        'handyman_id': handymanId,
        'rating': 5.0,
        'comment': 'Great!',
      });

      await fakeFirestore.collection('reviews').add({
        'handyman_id': handymanId,
        'rating': 4.0,
        'comment': 'Good',
      });

      await fakeFirestore.collection('reviews').add({
        'handyman_id': 'other_handyman',
        'rating': 3.0,
        'comment': 'OK',
      });

      // Act
      final snapshot = await fakeFirestore
          .collection('reviews')
          .where('handyman_id', isEqualTo: handymanId)
          .get();

      // Assert
      expect(snapshot.docs.length, 2);

      print('✓ Query handyman reviews test passed');
    });

    test('calculate average rating from reviews', () async {
      // Arrange
      const handymanId = 'hand123';
      await fakeFirestore.collection('reviews').add({
        'handyman_id': handymanId,
        'rating': 5.0,
      });

      await fakeFirestore.collection('reviews').add({
        'handyman_id': handymanId,
        'rating': 4.0,
      });

      await fakeFirestore.collection('reviews').add({
        'handyman_id': handymanId,
        'rating': 3.0,
      });

      // Act
      final snapshot = await fakeFirestore
          .collection('reviews')
          .where('handyman_id', isEqualTo: handymanId)
          .get();

      double totalRating = 0.0;
      for (var doc in snapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }
      final avgRating = totalRating / snapshot.docs.length;

      // Assert
      expect(avgRating, 4.0); // (5+4+3)/3 = 4.0

      print('✓ Calculate average rating test passed');
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

    test('query unread notifications', () async {
      // Arrange
      const userId = 'user123';
      await fakeFirestore.collection('notifications').add({
        'recipientId': userId,
        'isRead': false,
        'title': 'Unread 1',
      });

      await fakeFirestore.collection('notifications').add({
        'recipientId': userId,
        'isRead': false,
        'title': 'Unread 2',
      });

      await fakeFirestore.collection('notifications').add({
        'recipientId': userId,
        'isRead': true,
        'title': 'Read',
      });

      // Act
      final snapshot = await fakeFirestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Assert
      expect(snapshot.docs.length, 2);

      print('✓ Query unread notifications test passed');
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

    test('count handymen per category', () async {
      // Arrange
      await fakeFirestore.collection('serviceCategories').doc('plumbing').set({
        'name': 'Plumbing',
        'handyman_count': 15,
      });

      // Act
      final doc = await fakeFirestore.collection('serviceCategories').doc('plumbing').get();

      // Assert
      expect(doc.data()?['handyman_count'], 15);

      print('✓ Count handymen per category test passed');
    });
  });

  // ============================================
  // HANDYMAN TESTS - RUN LAST (Needs Approval)
  // ============================================

  group('Firestore - Handyman Profile Operations (RUN LAST)', () {
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
        'location': GeoPoint(7.2906, 80.6337),  // NEW
        'service_radius_km': 10,  // NEW
      };

      // Act
      await fakeFirestore.collection('handymanProfiles').doc(handymanId).set(handymanData);

      // Assert
      final doc = await fakeFirestore.collection('handymanProfiles').doc(handymanId).get();
      expect(doc.exists, true);
      expect(doc.data()?['category_id'], 'plumbing');
      expect(doc.data()?['hourly_rate'], 1500.0);
      expect(doc.data()?['work_status'], 'Available');
      expect(doc.data()?['location'], isA<GeoPoint>());

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

    test('update handyman work status', () async {
      // Arrange
      const handymanId = 'handyman123';
      await fakeFirestore.collection('handymanProfiles').doc(handymanId).set({
        'work_status': 'Available',
      });

      // Act
      await fakeFirestore.collection('handymanProfiles').doc(handymanId).update({
        'work_status': 'Unavailable',
      });

      // Assert
      final doc = await fakeFirestore.collection('handymanProfiles').doc(handymanId).get();
      expect(doc.data()?['work_status'], 'Unavailable');

      print('✓ Update work status test passed');
    });

    test('update handyman rating after review', () async {
      // Arrange
      const handymanId = 'handyman123';
      await fakeFirestore.collection('handymanProfiles').doc(handymanId).set({
        'rating_avg': 4.0,
        'review_count': 2,
      });

      // Act - New review with rating 5
      final newRatingAvg = ((4.0 * 2) + 5.0) / 3; // (8 + 5) / 3 = 4.33
      await fakeFirestore.collection('handymanProfiles').doc(handymanId).update({
        'rating_avg': newRatingAvg,
        'review_count': 3,
      });

      // Assert
      final doc = await fakeFirestore.collection('handymanProfiles').doc(handymanId).get();
      expect(doc.data()?['rating_avg'], closeTo(4.33, 0.01));
      expect(doc.data()?['review_count'], 3);

      print('✓ Update rating after review test passed');
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

    test('increment jobs completed after booking completion', () async {
      // Arrange
      const handymanId = 'handyman123';
      await fakeFirestore.collection('handymanProfiles').doc(handymanId).set({
        'jobs_completed': 10,
      });

      // Act - Complete a booking
      await fakeFirestore.collection('handymanProfiles').doc(handymanId).update({
        'jobs_completed': FieldValue.increment(1),
      });

      // Assert
      final doc = await fakeFirestore.collection('handymanProfiles').doc(handymanId).get();
      expect(doc.data()?['jobs_completed'], 11);

      print('✓ Increment jobs completed test passed');
    });

    test('handyman location data stored correctly', () async {
      // Arrange
      const handymanId = 'handyman123';
      final location = GeoPoint(7.2906, 80.6337);

      // Act
      await fakeFirestore.collection('handymanProfiles').doc(handymanId).set({
        'location': location,
        'location_address': 'Kandy, Sri Lanka',
        'service_radius_km': 10,
      });

      // Assert
      final doc = await fakeFirestore.collection('handymanProfiles').doc(handymanId).get();
      final storedLocation = doc.data()?['location'] as GeoPoint;
      expect(storedLocation.latitude, 7.2906);
      expect(storedLocation.longitude, 80.6337);
      expect(doc.data()?['service_radius_km'], 10);

      print('✓ Handyman location storage test passed');
    });
  });

  group('Firestore - Document Verification Operations (RUN LAST)', () {
    test('upload verification documents metadata', () async {
      // Arrange
      const userId = 'handyman123';
      final docData = {
        'user_id': userId,
        'id_card_front': 'https://storage.googleapis.com/bucket/id_front.jpg',
        'id_card_back': 'https://storage.googleapis.com/bucket/id_back.jpg',
        'certificate': 'https://storage.googleapis.com/bucket/cert.jpg',
        'status': 'pending',
        'uploaded_at': FieldValue.serverTimestamp(),
      };

      // Act
      await fakeFirestore.collection('verificationDocuments').doc(userId).set(docData);

      // Assert
      final doc = await fakeFirestore.collection('verificationDocuments').doc(userId).get();
      expect(doc.exists, true);
      expect(doc.data()?['status'], 'pending');
      expect(doc.data()?['id_card_front'], isNotNull);
      expect(doc.data()?['id_card_back'], isNotNull);

      print('✓ Upload verification documents test passed');
    });

    test('approve handyman documents', () async {
      // Arrange
      const userId = 'handyman123';
      await fakeFirestore.collection('verificationDocuments').doc(userId).set({
        'status': 'pending',
      });

      // Act - Admin approves
      await fakeFirestore.collection('verificationDocuments').doc(userId).update({
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
      });

      // Also activate user
      await fakeFirestore.collection('users').doc(userId).update({
        'is_active': true,
      });

      // Assert
      final docStatus = await fakeFirestore.collection('verificationDocuments').doc(userId).get();
      expect(docStatus.data()?['status'], 'approved');

      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      expect(userDoc.data()?['is_active'], true);

      print('✓ Approve handyman documents test passed');
    });
  });
}

/*
TO RUN THESE TESTS:
===================

1. Run all tests:
   flutter test test/unit/firestore_service_test_updated.dart

2. Run with coverage:
   flutter test test/unit/firestore_service_test_updated.dart --coverage

3. Run only customer tests (skip handyman):
   flutter test test/unit/firestore_service_test_updated.dart --name "Customer|Booking|Review|Notification|Service Category"

4. Run only handyman tests:
   flutter test test/unit/firestore_service_test_updated.dart --name "Handyman|Document Verification"

All tests should show green checkmarks ✓
*/