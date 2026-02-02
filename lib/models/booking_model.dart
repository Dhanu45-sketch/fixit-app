// lib/models/booking_model.dart
// FIXED VERSION - Added hasReview property

import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String customerId;
  final String handymanId;
  final String customerName;
  final String serviceName;
  final String status;
  final DateTime scheduledStartTime;
  final double totalPrice;
  final String notes;
  final String address;
  final bool isEmergency;
  final bool hasReview; // NEW: Added to track if user has reviewed

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
    this.hasReview = false, // NEW: Default to false
  });

  // Factory constructor to create Booking from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Booking(
      id: doc.id,
      customerId: data['customer_id'] ?? '',
      handymanId: data['handyman_id'] ?? '',
      customerName: data['customer_name'] ?? 'Unknown',
      serviceName: data['service_name'] ?? '',
      status: data['status'] ?? 'Pending',
      scheduledStartTime: (data['scheduled_start_time'] as Timestamp).toDate(),
      totalPrice: (data['total_price'] ?? 0).toDouble(),
      notes: data['notes'] ?? '',
      address: data['address'] ?? '',
      isEmergency: data['is_emergency'] ?? false,
      hasReview: data['has_review'] ?? false, // NEW: Read from Firestore
    );
  }

  // Convert Booking to Map for Firestore
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
      'has_review': hasReview, // NEW: Include in Firestore writes
    };
  }

  // CopyWith method for easy object copying with modifications
  Booking copyWith({
    String? id,
    String? customerId,
    String? handymanId,
    String? customerName,
    String? serviceName,
    String? status,
    DateTime? scheduledStartTime,
    double? totalPrice,
    String? notes,
    String? address,
    bool? isEmergency,
    bool? hasReview, // NEW: Allow updating hasReview
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      handymanId: handymanId ?? this.handymanId,
      customerName: customerName ?? this.customerName,
      serviceName: serviceName ?? this.serviceName,
      status: status ?? this.status,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      address: address ?? this.address,
      isEmergency: isEmergency ?? this.isEmergency,
      hasReview: hasReview ?? this.hasReview,
    );
  }
}