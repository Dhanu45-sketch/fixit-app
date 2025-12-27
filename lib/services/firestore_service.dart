import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // USER PROFILE METHODS
  // ==========================================

  Future<void> createUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required bool isHandyman,
    GeoPoint? location,
  }) async {
    await _db.collection('users').doc(userId).set({
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'is_handyman': isHandyman,
      'location': location,
      'is_active': true,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // HANDYMAN PROFILE METHODS
  // ==========================================

  Future<String> createHandymanProfile({
    required String userId,
    required String categoryId,
    required String categoryName,
    required int experience,
    required double hourlyRate,
    String? bio,
    String? workStatus,
  }) async {
    await _db.collection('handymanProfiles').doc(userId).set({
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'experience': experience,
      'hourly_rate': hourlyRate,
      'bio': bio ?? '',
      'work_status': workStatus ?? 'Available',
      'rating_avg': 0.0,
      'jobs_completed': 0,
      'updated_at': FieldValue.serverTimestamp(),
    });
    return userId;
  }

  Future<Map<String, dynamic>?> getHandymanProfileByUserId(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('handymanProfiles').doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print("Error getting handyman profile: $e");
      return null;
    }
  }

  Future<void> updateHandymanProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('handymanProfiles').doc(userId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getHandymenByCategory(String categoryId, String sortBy) {
    return _db.collection('handymanProfiles')
        .where('category_id', isEqualTo: categoryId)
        .orderBy(sortBy, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getTopRatedHandymen({int limit = 5}) {
    return _db.collection('handymanProfiles')
        .orderBy('rating_avg', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<List<Map<String, dynamic>>> searchHandymen(String query) async {
    try {
      String searchKey = query.trim();
      if (searchKey.isNotEmpty) {
        searchKey = searchKey[0].toUpperCase() + searchKey.substring(1).toLowerCase();
      }
      final snapshot = await _db.collection('handymanProfiles')
          .where('category_name', isGreaterThanOrEqualTo: searchKey)
          .where('category_name', isLessThanOrEqualTo: '$searchKey\uf8ff')
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // BOOKING METHODS
  // ==========================================

  Future<void> createBooking({
    required String handymanId,
    required String serviceName,
    required DateTime scheduledTime,
    required double hourlyRate,
    required String notes,
    bool isEmergency = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    final userDoc = await _db.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data() ?? {};
    final String customerName = "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim();

    final docRef = await _db.collection('bookings').add({
      'handyman_id': handymanId,
      'customer_id': currentUser.uid,
      'customer_name': customerName,
      'service_name': serviceName,
      'status': 'Pending',
      'scheduled_start_time': Timestamp.fromDate(scheduledTime),
      'total_price': isEmergency ? (hourlyRate * 1.5) : hourlyRate,
      'notes': notes,
      'is_emergency': isEmergency,
      'address': userData['address'] ?? 'No address provided',
      'created_at': FieldValue.serverTimestamp(),
    });

    await addNotification(
      recipientId: handymanId,
      title: isEmergency ? "🚨 Emergency Job!" : "New Job Request",
      message: "$customerName needs help with $serviceName",
      type: "booking",
      bookingId: docRef.id,
    );
  }

  Stream<List<Booking>> getCustomerBookings(String userId) {
    return _db.collection('bookings')
        .where('customer_id', isEqualTo: userId)
        .orderBy('scheduled_start_time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Stream<List<Booking>> getHandymanBookings(String handymanId) {
    return _db.collection('bookings')
        .where('handyman_id', isEqualTo: handymanId)
        .orderBy('scheduled_start_time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'Confirmed');
  }

  Future<void> rejectBooking(String bookingId, String reason) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'Rejected',
      'rejection_reason': reason,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // NOTIFICATION & CATEGORY METHODS
  // ==========================================

  Future<void> addNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
  }) async {
    await _db.collection('notifications').add({
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'type': type,
      'bookingId': bookingId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Stream<List<Map<String, dynamic>>> getServiceCategories() {
    return _db.collection('serviceCategories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }
}