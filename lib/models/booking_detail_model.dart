import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetail {
  final String id; // Firestore IDs are Strings
  final String handymanName;
  final String? handymanPhoto;
  final String serviceType;
  final String description;
  final String location;
  final DateTime scheduledAt; // Combined date and time
  final int estimatedHours;
  final double amount;
  final String status;
  final bool isEmergency;
  final String? customerName;
  final DateTime? completedAt;
  final double? rating;

  BookingDetail({
    required this.id,
    required this.handymanName,
    this.handymanPhoto,
    required this.serviceType,
    required this.description,
    required this.location,
    required this.scheduledAt,
    required this.estimatedHours,
    required this.amount,
    required this.status,
    this.isEmergency = false,
    this.customerName,
    this.completedAt,
    this.rating,
  });


  // Simplified getter for UI consistency
  String get scheduledDateString => "${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}";
  String get scheduledTimeString => "${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}";

  factory BookingDetail.fromMap(Map<String, dynamic> data, String documentId) {
    return BookingDetail(
      id: documentId,
      handymanName: data['handyman_name'] ?? 'Handyman',
      handymanPhoto: data['handyman_photo'],
      serviceType: data['service_type'] ?? 'Service',
      description: data['job_description'] ?? '',
      location: data['location_address'] ?? '',
      // Handle Firestore Timestamp conversion
      scheduledAt: (data['scheduled_start_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedHours: data['estimated_hours'] ?? 1,
      amount: (data['total_amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Pending',
      isEmergency: data['is_emergency'] ?? false,
      customerName: data['customer_name'],
      completedAt: (data['actual_end_time'] as Timestamp?)?.toDate(),
      rating: (data['rating'] ?? 0.0).toDouble(),
    );
  }
}