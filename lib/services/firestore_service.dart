// lib/services/firestore_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint("Error getting user profile: $e");
      return null;
    }
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
    bool acceptsEmergencies = true,
  }) async {
    await _db.collection('handymanProfiles').doc(userId).set({
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'experience': experience,
      'hourly_rate': hourlyRate,
      'bio': bio ?? '',
      'work_status': workStatus ?? 'Available',
      'accepts_emergencies': acceptsEmergencies,
      'rating_avg': 0.0,
      'rating_count': 0,
      'jobs_completed': 0,
      'total_earnings': 0.0,
      'emergency_earnings': 0.0,
      'emergency_jobs_count': 0,
      'updated_at': FieldValue.serverTimestamp(),
    });
    return userId;
  }

  Future<Map<String, dynamic>?> getHandymanProfileByUserId(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('handymanProfiles').doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      debugPrint("Error getting handyman profile: $e");
      return null;
    }
  }

  Stream<Map<String, dynamic>?> getHandymanProfileStream(String userId) {
    return _db.collection('handymanProfiles').doc(userId).snapshots().map((doc) => doc.data());
  }

  Future<void> updateHandymanProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('handymanProfiles').doc(userId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Update handyman work status (Available/Unavailable)
  Future<void> updateHandymanWorkStatus(String handymanId, String status) async {
    try {
      await _db.collection('handymanProfiles').doc(handymanId).update({
        'work_status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Work status updated to: $status');
    } catch (e) {
      debugPrint('❌ Error updating work status: $e');
      rethrow;
    }
  }

  /// Update handyman stats after job completion or review
  Future<void> updateHandymanStats(String handymanId) async {
    try {
      // Get all completed jobs
      final completedJobs = await _db
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .where('status', isEqualTo: 'Completed')
          .get();

      final jobCount = completedJobs.docs.length;

      // Get all reviews
      final reviews = await _db
          .collection('reviews')
          .where('handyman_id', isEqualTo: handymanId)
          .get();

      double avgRating = 0.0;
      if (reviews.docs.isNotEmpty) {
        final totalRating = reviews.docs.fold<double>(
          0.0,
          (sum, doc) => sum + ((doc.data()['rating'] ?? 0.0) as num).toDouble(),
        );
        avgRating = totalRating / reviews.docs.length;
      }

      // Calculate total earnings
      double earnings = completedJobs.docs.fold<double>(
        0.0,
        (sum, doc) => sum + ((doc.data()['total_price'] ?? 0.0) as num).toDouble(),
      );

      // Update profile
      await _db.collection('handymanProfiles').doc(handymanId).update({
        'jobs_completed': jobCount,
        'rating_avg': avgRating,
        'rating_count': reviews.docs.length,
        'total_earnings': earnings,
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Handyman stats updated - Jobs: $jobCount, Rating: ${avgRating.toStringAsFixed(1)}, Earned: $earnings');
    } catch (e) {
      debugPrint('❌ Error updating handyman stats: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getHandymenByCategory(
    String categoryId, 
    String sortBy,
    {bool emergencyOnly = false}
  ) {
    Query query = _db.collection('handymanProfiles')
        .where('category_id', isEqualTo: categoryId);
    
    if (emergencyOnly) {
      query = query.where('accepts_emergencies', isEqualTo: true);
    }
    
    query = query.orderBy(sortBy, descending: true);
    
    return query.snapshots().map((snap) => 
      snap.docs.map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)}).toList()
    );
  }

  Stream<List<Map<String, dynamic>>> getTopRatedHandymen({
    int limit = 5, 
    bool emergencyOnly = false
  }) {
    Query query = _db.collection('handymanProfiles');
    
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
      
      if (emergencyOnly) {
        firestoreQuery = firestoreQuery.where('accepts_emergencies', isEqualTo: true);
      }
      
      final snapshot = await firestoreQuery.get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)}).toList();
    } catch (e) {
      return [];
    }
  }

  static double calculateEmergencyPrice(double basePrice) {
    return basePrice * (1 + emergencySurchargeRate);
  }

  // ==========================================
  // VERIFICATION METHODS
  // ==========================================

  Future<void> uploadVerificationDocuments({
    required String userId,
    required String idFrontUrl,
    required String idBackUrl,
    String? certificateUrl,
  }) async {
    await _db.collection('verificationDocuments').doc(userId).set({
      'user_id': userId,
      'id_card_front': idFrontUrl,
      'id_card_back': idBackUrl,
      'certificate': certificateUrl,
      'status': 'pending',
      'uploaded_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getVerificationDocuments(String userId) async {
    final doc = await _db.collection('verificationDocuments').doc(userId).get();
    return doc.data();
  }

  Stream<Map<String, dynamic>?> getVerificationStatusStream(String userId) {
    return _db.collection('verificationDocuments').doc(userId).snapshots().map((doc) => doc.data());
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
    required String address,
    bool isEmergency = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    if (address.trim().isEmpty) {
      throw Exception("Service address is required");
    }

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
      'total_price': isEmergency ? (hourlyRate * 1.0) : hourlyRate,
      'notes': notes,
      'is_emergency': isEmergency,
      'address': address.trim(),
      'has_review': false,
      'review_id': null,
      'created_at': FieldValue.serverTimestamp(),
    });

    await addNotification(
      recipientId: handymanId,
      title: isEmergency ? "🚨 Emergency Job!" : "New Job Request",
      message: "$customerName needs help with $serviceName${isEmergency ? ' (URGENT)' : ''}",
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

  Future<void> completeBooking(String bookingId) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');

      final data = bookingDoc.data()!;
      final handymanId = data['handyman_id'];
      
      await _db.collection('bookings').doc(bookingId).update({
        'status': 'Completed',
        'completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update stats
      await updateHandymanStats(handymanId);

      await addNotification(
        recipientId: data['customer_id'],
        title: '🎉 Job Completed!',
        message: 'The service for ${data['service_name']} has been completed. Please leave a review!',
        type: 'completion',
        bookingId: bookingId,
      );
    } catch (e) {
      throw Exception('Failed to complete booking: $e');
    }
  }

  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _db.collection('bookings').doc(bookingId).get();
      if (!doc.exists) return null;
      return Booking.fromFirestore(doc);
    } catch (e) {
      debugPrint("Error getting booking by ID: $e");
      return null;
    }
  }

  // ==========================================
  // NAVIGATION METHODS
  // ==========================================

  /// Mark booking as "On The Way" when handyman starts navigation
  Future<void> startNavigation({
    required String bookingId,
    required String handymanId,
  }) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');
      final data = bookingDoc.data()!;
      if (data['handyman_id'] != handymanId) throw Exception('Unauthorized');
      if (data['status'] != 'Confirmed') throw Exception('Invalid status');

      if (data['address'] == null || data['address'].toString().trim().isEmpty) {
        throw Exception('No service address available for this booking');
      }

      await _db.collection('bookings').doc(bookingId).update({
        'status': 'On The Way',
        'navigation_started_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await addNotification(
        recipientId: data['customer_id'],
        title: '🚗 Handyman on the way!',
        message: 'Your handyman has started the journey to your location.',
        type: 'navigation',
        bookingId: bookingId,
      );
    } catch (e) {
      throw Exception('Failed to start navigation: $e');
    }
  }

  Future<void> markAsArrived({
    required String bookingId,
    required String handymanId,
  }) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');
      final data = bookingDoc.data()!;
      if (data['handyman_id'] != handymanId) throw Exception('Unauthorized');
      if (data['status'] != 'On The Way') throw Exception('Invalid status');

      await _db.collection('bookings').doc(bookingId).update({
        'status': 'In Progress',
        'arrived_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await addNotification(
        recipientId: data['customer_id'],
        title: '✅ Handyman has arrived!',
        message: 'Your handyman has arrived at your location.',
        type: 'arrival',
        bookingId: bookingId,
      );
    } catch (e) {
      throw Exception('Failed to mark as arrived: $e');
    }
  }

  Future<String?> getBookingAddress(String bookingId) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) return null;
      return bookingDoc.data()?['address']?.toString();
    } catch (e) {
      debugPrint('Error getting booking address: $e');
      return null;
    }
  }

  // ==========================================
  // CANCELLATION METHODS
  // ==========================================

  Future<void> cancelBooking({
    required String bookingId,
    required String cancelledBy,
    required String cancelledByType,
    required String reason,
    String? notes,
  }) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');
      final bookingData = bookingDoc.data()!;
      final scheduledTime = (bookingData['scheduled_start_time'] as Timestamp).toDate();
      final now = DateTime.now();
      final hoursUntilBooking = scheduledTime.difference(now).inHours;

      if (hoursUntilBooking <= 12) throw Exception('Cannot cancel within 12 hours');

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

      final recipientId = cancelledByType == 'customer' ? bookingData['handyman_id'] : bookingData['customer_id'];
      final userData = await getUserProfile(cancelledBy);
      final cancellerName = userData != null ? "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim() : 'User';

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

  Future<bool> canCancelBooking(String bookingId) async {
    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) return false;
      final bookingData = bookingDoc.data()!;
      if (bookingData['status'] == 'Completed' || bookingData['status'] == 'In Progress' || bookingData['status'] == 'Cancelled') return false;
      final scheduledTime = (bookingData['scheduled_start_time'] as Timestamp).toDate();
      return scheduledTime.difference(DateTime.now()).inHours > 12;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // REVIEW METHODS
  // ==========================================

  /// Create a new review for a completed booking
  Future<void> createReview({
    required String bookingId,
    required String handymanId,
    required double rating,
    required String comment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    // Validate rating
    if (rating < 1.0 || rating > 5.0) {
      throw Exception("Rating must be between 1.0 and 5.0");
    }

    try {
      // 1. Get booking to verify
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;

      // 2. Logic Validation
      if (bookingData['customer_id'] != currentUser.uid) {
        throw Exception('Only the customer can review this booking');
      }

      if (bookingData['status'] != 'Completed') {
        throw Exception('Can only review completed bookings');
      }

      // Check if review already exists
      final existingReview = await _db
          .collection('reviews')
          .where('booking_id', isEqualTo: bookingId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        throw Exception('Review already exists for this booking');
      }

      // 3. Prepare Batch for Atomic Update
      final WriteBatch batch = _db.batch();

      // Get customer name
      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() ?? {};
      final String customerName = "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim();

      // New Review Reference
      final DocumentReference reviewRef = _db.collection('reviews').doc();

      // Set Review Data
      batch.set(reviewRef, {
        'booking_id': bookingId,
        'customer_id': currentUser.uid,
        'customer_name': customerName,
        'handyman_id': handymanId,
        'rating': rating,
        'comment': comment,
        'service_name': bookingData['service_name'],
        'created_at': FieldValue.serverTimestamp(),
      });

      // Update Booking to mark as reviewed
      batch.update(_db.collection('bookings').doc(bookingId), {
        'has_review': true,
        'review_id': reviewRef.id,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      // 4. Update stats (Safe update)
      await updateHandymanStats(handymanId);

      await addNotification(
        recipientId: handymanId,
        title: '⭐ New Review!',
        message: '$customerName rated you ${rating.toStringAsFixed(1)} stars',
        type: 'review',
        bookingId: bookingId,
      );

    } catch (e) {
      debugPrint('Error creating review: $e');
      throw Exception('Failed to create review: $e');
    }
  }

  /// Update handyman's average rating based on all their reviews
  Future<void> _updateHandymanRating(String handymanId) async {
    try {
      final reviewsSnapshot = await _db
          .collection('reviews')
          .where('handyman_id', isEqualTo: handymanId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      int reviewCount = 0;

      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        if (data != null && data['rating'] != null) {
          totalRating += (data['rating'] as num).toDouble();
          reviewCount++;
        }
      }

      if (reviewCount == 0) return;

      double averageRating = totalRating / reviewCount;

      await _db.collection('handymanProfiles').doc(handymanId).update({
        'rating_avg': averageRating,
        'rating_count': reviewCount,
        'updated_at': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint('Error updating handyman rating: $e');
    }
  }

  /// Get all reviews for a specific handyman
  Stream<List<Review>> getHandymanReviews(String handymanId, {int limit = 10}) {
    return _db
        .collection('reviews')
        .where('handyman_id', isEqualTo: handymanId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  /// Check if user can review a booking
  Future<bool> canReviewBooking(String bookingId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) return false;

      final bookingData = bookingDoc.data()!;
      if (bookingData['customer_id'] != currentUser.uid) return false;
      if (bookingData['status'] != 'Completed') return false;
      if (bookingData['has_review'] == true) return false;

      return true;
    } catch (e) {
      debugPrint('Error checking review eligibility: $e');
      return false;
    }
  }

  /// Get review for a specific booking (if exists)
  Future<Map<String, dynamic>?> getBookingReview(String bookingId) async {
    try {
      final snapshot = await _db
          .collection('reviews')
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return {
        'id': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      };
    } catch (e) {
      debugPrint('Error getting booking review: $e');
      return null;
    }
  }

  /// Get rating breakdown (number of 1-star, 2-star, etc.)
  Future<Map<int, int>> getRatingBreakdown(String handymanId) async {
    try {
      final snapshot = await _db
          .collection('reviews')
          .where('handyman_id', isEqualTo: handymanId)
          .get();

      final Map<int, int> breakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data != null && data['rating'] != null) {
          final int rating = (data['rating'] as num).round();
          if (breakdown.containsKey(rating)) {
            breakdown[rating] = (breakdown[rating] ?? 0) + 1;
          }
        }
      }

      return breakdown;
    } catch (e) {
      debugPrint('Error getting rating breakdown: $e');
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
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

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _db.collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Stream<List<Map<String, dynamic>>> getServiceCategories() {
    return _db.collection('serviceCategories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...(doc.data() as Map<String, dynamic>)}).toList();
    });
  }
}
