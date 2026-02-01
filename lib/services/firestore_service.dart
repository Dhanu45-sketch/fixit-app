// lib/services/firestore_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Emergency surcharge rate (industry standard: 15%)
  static const double emergencySurchargeRate = 0.15; // 15% increase

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
    bool acceptsEmergencies = true, // New field
  }) async {
    await _db.collection('handymanProfiles').doc(userId).set({
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'experience': experience,
      'hourly_rate': hourlyRate,
      'bio': bio ?? '',
      'work_status': workStatus ?? 'Available',
      'accepts_emergencies': acceptsEmergencies, // New field
      'rating_avg': 0.0,
      'rating_count': 0, // ADDED: Track total review count
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

  // UPDATED: Added emergency filter
  Stream<List<Map<String, dynamic>>> getHandymenByCategory(
    String categoryId, 
    String sortBy,
    {bool emergencyOnly = false}
  ) {
    Query query = _db.collection('handymanProfiles')
        .where('category_id', isEqualTo: categoryId);
    
    // Filter for emergency-accepting handymen if emergency mode is on
    if (emergencyOnly) {
      query = query.where('accepts_emergencies', isEqualTo: true);
    }
    
    query = query.orderBy(sortBy, descending: true);
    
    return query.snapshots().map((snap) => 
      snap.docs.map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)}).toList()
    );
  }

  // UPDATED: Added emergency filter
  Stream<List<Map<String, dynamic>>> getTopRatedHandymen({
    int limit = 5, 
    bool emergencyOnly = false
  }) {
    Query query = _db.collection('handymanProfiles');
    
    // Filter for emergency-accepting handymen if emergency mode is on
    if (emergencyOnly) {
      query = query.where('accepts_emergencies', isEqualTo: true);
    }
    
    return query
        .orderBy('rating_avg', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
          {'id': doc.id, ...(doc.data() as Map<String, dynamic>)}
        ).toList());
  }

  // UPDATED: Added emergency filter
  Future<List<Map<String, dynamic>>> searchHandymen(
    String query, 
    {bool emergencyOnly = false}
  ) async {
    try {
      String searchKey = query.trim();
      if (searchKey.isNotEmpty) {
        searchKey = searchKey[0].toUpperCase() + searchKey.substring(1).toLowerCase();
      }
      
      Query firestoreQuery = _db.collection('handymanProfiles')
          .where('category_name', isGreaterThanOrEqualTo: searchKey)
          .where('category_name', isLessThanOrEqualTo: '$searchKey\uf8ff');
      
      // Filter for emergency-accepting handymen if emergency mode is on
      if (emergencyOnly) {
        firestoreQuery = firestoreQuery.where('accepts_emergencies', isEqualTo: true);
      }
      
      final snapshot = await firestoreQuery.get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)}).toList();
    } catch (e) {
      return [];
    }
  }

  // Helper method to calculate emergency price
  static double calculateEmergencyPrice(double basePrice) {
    return basePrice * (1 + emergencySurchargeRate);
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

    // Calculate total price with emergency surcharge if applicable
    final double totalPrice = isEmergency 
        ? calculateEmergencyPrice(hourlyRate)
        : hourlyRate;

    final docRef = await _db.collection('bookings').add({
      'handyman_id': handymanId,
      'customer_id': currentUser.uid,
      'customer_name': customerName,
      'service_name': serviceName,
      'status': 'Pending',
      'scheduled_start_time': Timestamp.fromDate(scheduledTime),
      'total_price': totalPrice,
      'base_price': hourlyRate, // Store base price for reference
      'notes': notes,
      'is_emergency': isEmergency,
      'address': userData['address'] ?? 'No address provided',
      'has_review': false,  // ADDED: Track if booking has been reviewed
      'review_id': null,    // ADDED: Link to review document
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
  // CANCELLATION METHODS
  // ==========================================

  /// Cancel a booking (12-hour policy)
  Future<void> cancelBooking({
    required String bookingId,
    required String cancelledBy, // userId
    required String cancelledByType, // "customer" or "handyman"
    required String reason,
    String? notes,
  }) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final scheduledTime = (bookingData['scheduled_start_time'] as Timestamp).toDate();
      final now = DateTime.now();
      final hoursUntilBooking = scheduledTime.difference(now).inHours;

      // Check 12-hour policy
      if (hoursUntilBooking <= 12) {
        throw Exception('Cannot cancel within 12 hours of booking');
      }

      // Update booking with cancellation info
      await _db.collection('bookings').doc(bookingId).update({
        'status': 'Cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancelled_by': cancelledBy,
        'cancelled_by_type': cancelledByType,
        'cancellation_reason': reason,
        'cancellation_notes': notes,
        'hours_before_cancellation': hoursUntilBooking,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Create cancellation record for tracking
      await _db.collection('cancellations').add({
        'booking_id': bookingId,
        'cancelled_by_id': cancelledBy,
        'cancelled_by_type': cancelledByType,
        'cancelled_at': FieldValue.serverTimestamp(),
        'reason': reason,
        'notes': notes,
        'hours_before_booking': hoursUntilBooking,
        'scheduled_time': Timestamp.fromDate(scheduledTime),
        'service_name': bookingData['service_name'],
        'customer_id': bookingData['customer_id'],
        'handyman_id': bookingData['handyman_id'],
      });

      // Send notification to the other party
      final recipientId = cancelledByType == 'customer'
          ? bookingData['handyman_id']
          : bookingData['customer_id'];
      
      final userData = await getUserProfile(cancelledBy);
      final cancellerName = userData != null 
          ? "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim()
          : (cancelledByType == 'customer' ? 'Customer' : 'Handyman');

      await addNotification(
        recipientId: recipientId,
        title: 'Booking Cancelled',
        message: '$cancellerName cancelled the ${bookingData['service_name']} booking',
        type: 'booking_cancelled',
        bookingId: bookingId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check if booking can be cancelled (12-hour policy)
  Future<bool> canCancelBooking(String bookingId) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      
      if (!bookingDoc.exists) return false;

      final bookingData = bookingDoc.data()!;
      final status = bookingData['status'];
      
      // Cannot cancel completed, in progress, or already cancelled bookings
      if (status == 'Completed' || status == 'In Progress' || status == 'Cancelled') {
        return false;
      }

      final scheduledTime = (bookingData['scheduled_start_time'] as Timestamp).toDate();
      final now = DateTime.now();
      final hoursUntilBooking = scheduledTime.difference(now).inHours;

      return hoursUntilBooking > 12;
    } catch (e) {
      return false;
    }
  }

  /// Get hours until booking
  Future<int> getHoursUntilBooking(String bookingId) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      
      if (!bookingDoc.exists) return 0;

      final bookingData = bookingDoc.data()!;
      final scheduledTime = (bookingData['scheduled_start_time'] as Timestamp).toDate();
      final now = DateTime.now();
      
      return scheduledTime.difference(now).inHours;
    } catch (e) {
      return 0;
    }
  }

  /// Get cancellation statistics for a user
  Future<Map<String, dynamic>> getCancellationStats(String userId) async {
    try {
      final cancellations = await _db
          .collection('cancellations')
          .where('cancelled_by_id', isEqualTo: userId)
          .get();

      final total = cancellations.docs.length;
      final last30Days = cancellations.docs.where((doc) {
        final data = doc.data();
        final cancelledAt = (data['cancelled_at'] as Timestamp).toDate();
        return DateTime.now().difference(cancelledAt).inDays <= 30;
      }).length;

      return {
        'total_cancellations': total,
        'last_30_days': last30Days,
      };
    } catch (e) {
      return {
        'total_cancellations': 0,
        'last_30_days': 0,
      };
    }
  }

  // ==========================================
  // REVIEW METHODS
  // ==========================================

  /// Submit a review for a completed booking
  Future<void> submitReview({
    required String handymanId,
    required String customerId,
    required String customerName,
    required String bookingId,
    required int rating,
    required String comment,
    String? customerPhoto,
  }) async {
    // Validation
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    // Check if review already exists for this booking
    final existingReview = await _db
        .collection('reviews')
        .where('booking_id', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (existingReview.docs.isNotEmpty) {
      throw Exception('You have already reviewed this booking');
    }

    // Use a batch write to ensure atomicity
    final batch = _db.batch();

    // 1. Add the review
    final reviewRef = _db.collection('reviews').doc();
    batch.set(reviewRef, {
      'handyman_id': handymanId,
      'customer_id': customerId,
      'customer_name': customerName,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'customer_photo': customerPhoto,
      'created_at': FieldValue.serverTimestamp(),
    });

    // 2. Get current handyman stats
    final handymanDoc = await _db.collection('handymanProfiles').doc(handymanId).get();
    final handymanData = handymanDoc.data() ?? {};

    final double currentAvg = (handymanData['rating_avg'] ?? 0.0).toDouble();
    final int currentCount = (handymanData['rating_count'] ?? 0);

    // 3. Calculate new average
    final double newAvg = ((currentAvg * currentCount) + rating) / (currentCount + 1);

    // 4. Update handyman profile with new stats
    final handymanRef = _db.collection('handymanProfiles').doc(handymanId);
    batch.update(handymanRef, {
      'rating_avg': newAvg,
      'rating_count': currentCount + 1,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 5. Mark booking as reviewed
    final bookingRef = _db.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'has_review': true,
      'review_id': reviewRef.id,
    });

    // Commit all changes atomically
    await batch.commit();
  }

  /// Get reviews for a specific handyman
  Stream<List<Review>> getHandymanReviews(String handymanId, {int limit = 10}) {
    return _db
        .collection('reviews')
        .where('handyman_id', isEqualTo: handymanId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  /// Get rating breakdown (number of 1-star, 2-star, etc.)
  Future<Map<int, int>> getRatingBreakdown(String handymanId) async {
    final snapshot = await _db
        .collection('reviews')
        .where('handyman_id', isEqualTo: handymanId)
        .get();

    final Map<int, int> breakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var doc in snapshot.docs) {
      final rating = doc.data()['rating'] as int;
      breakdown[rating] = (breakdown[rating] ?? 0) + 1;
    }

    return breakdown;
  }

  /// Check if a booking can be reviewed
  Future<bool> canReviewBooking(String bookingId) async {
    final bookingDoc = await _db.collection('bookings').doc(bookingId).get();

    if (!bookingDoc.exists) return false;

    final data = bookingDoc.data()!;
    final status = data['status'] as String;
    final hasReview = data['has_review'] ?? false;

    return status == 'Completed' && !hasReview;
  }

  /// Get review for a specific booking
  Future<Review?> getReviewByBookingId(String bookingId) async {
    final snapshot = await _db
        .collection('reviews')
        .where('booking_id', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Review.fromFirestore(snapshot.docs.first);
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
      return snapshot.docs.map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)}).toList();
    });
  }
}
