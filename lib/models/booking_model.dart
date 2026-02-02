// lib/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String customerId;
  final String handymanId;
  final String customerName;
  final String serviceName;
  final String status; // Pending, Confirmed, On The Way, In Progress, Completed, Cancelled
  final DateTime scheduledStartTime;
  final double totalPrice;
  final String notes;
  final String address;
  final bool isEmergency;
  
  // Review fields
  final bool hasReview;
  final String? reviewId;

  // Navigation fields
  final DateTime? navigationStartedAt;  // When handyman started navigation
  final DateTime? arrivedAt;            // When handyman marked as arrived

  Booking({
    required this.id,
    required this.customerId,
    required this.handymanId,
    required this.customerName,
    required this.serviceName,
    required this.status,
    required this.scheduledStartTime,
    required this.totalPrice,
    required this.notes,
    required this.address,
    this.isEmergency = false,
    this.hasReview = false,
    this.reviewId,
    this.navigationStartedAt,
    this.arrivedAt,
  });

  // Helper to check if handyman is on the way
  bool get isOnTheWay => status == 'On The Way';

  // Helper to check if handyman has arrived
  bool get hasArrived => arrivedAt != null;

  // Convert Firestore Document to Booking Object
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      customerId: data['customer_id'] ?? '',
      handymanId: data['handyman_id'] ?? '',
      customerName: data['customer_name'] ?? 'Customer',
      serviceName: data['service_name'] ?? 'Service',
      status: data['status'] ?? 'Pending',
      scheduledStartTime: (data['scheduled_start_time'] as Timestamp).toDate(),
      totalPrice: (data['total_price'] ?? 0).toDouble(),
      notes: data['notes'] ?? '',
      address: data['address'] ?? 'No Address',
      isEmergency: data['is_emergency'] ?? false,
      hasReview: data['has_review'] ?? false,
      reviewId: data['review_id'],
      
      // Navigation Fields
      navigationStartedAt: data['navigation_started_at'] != null
          ? (data['navigation_started_at'] as Timestamp).toDate()
          : null,
      arrivedAt: data['arrived_at'] != null
          ? (data['arrived_at'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert Booking Object to Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'handyman_id': handymanId,
      'customer_name': customerName,
      'service_name': serviceName,
      'status': status,
      'scheduled_start_time': Timestamp.fromDate(scheduledStartTime),
      'total_price': totalPrice,
      'notes': notes,
      'address': address,
      'is_emergency': isEmergency,
      'has_review': hasReview,
      'review_id': reviewId,
      
      // Navigation Fields
      'navigation_started_at': navigationStartedAt != null
          ? Timestamp.fromDate(navigationStartedAt!)
          : null,
      'arrived_at': arrivedAt != null
          ? Timestamp.fromDate(arrivedAt!)
          : null,
    };
  }

  // Create a copy with updated fields
  Booking copyWith({
    String? status,
    DateTime? navigationStartedAt,
    DateTime? arrivedAt,
    bool? hasReview,
    String? reviewId,
  }) {
    return Booking(
      id: id,
      customerId: customerId,
      handymanId: handymanId,
      customerName: customerName,
      serviceName: serviceName,
      status: status ?? this.status,
      scheduledStartTime: scheduledStartTime,
      totalPrice: totalPrice,
      notes: notes,
      address: address,
      isEmergency: isEmergency,
      hasReview: hasReview ?? this.hasReview,
      reviewId: reviewId ?? this.reviewId,
      navigationStartedAt: navigationStartedAt ?? this.navigationStartedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
    );
  }
}
