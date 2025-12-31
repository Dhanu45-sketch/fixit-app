// lib/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String handymanId;
  final String customerId;
  final String customerName;
  final String bookingId;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;
  final String? customerPhoto;

  Review({
    required this.id,
    required this.handymanId,
    required this.customerId,
    required this.customerName,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.customerPhoto,
  });

  // Convert Firestore document to Review object
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      handymanId: data['handyman_id'] ?? '',
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? 'Anonymous',
      bookingId: data['booking_id'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      customerPhoto: data['customer_photo'],
    );
  }

  // Convert Review object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'handyman_id': handymanId,
      'customer_id': customerId,
      'customer_name': customerName,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'created_at': Timestamp.fromDate(createdAt),
      'customer_photo': customerPhoto,
    };
  }

  // Helper to get star display
  String get starsDisplay => '⭐' * rating;
}