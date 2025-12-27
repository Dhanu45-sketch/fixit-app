import 'package:cloud_firestore/cloud_firestore.dart';

class JobRequest {
  final String id;
  final String customerUserId;
  final String customerName;
  final String description;
  final String jobType;
  final String location;
  final bool isEmergency;
  final DateTime createdTime;
  final DateTime? deadline;
  final String status;
  final double offeredPrice; // Removed nullable to prevent UI logic errors

  JobRequest({
    required this.id,
    required this.customerUserId,
    required this.customerName,
    required this.description,
    required this.jobType,
    required this.location,
    required this.isEmergency,
    required this.createdTime,
    this.deadline,
    required this.status,
    required this.offeredPrice,
  });

  // Helper for Firestore query snapshots
  factory JobRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return JobRequest.fromMap(data, doc.id);
  }

  factory JobRequest.fromMap(Map<String, dynamic> data, String documentId) {
    return JobRequest(
      id: documentId,
      customerUserId: data['customer_user_id']?.toString() ?? '',
      customerName: data['customer_name']?.toString() ?? 'Anonymous',
      description: data['description']?.toString() ?? 'No description provided',
      jobType: data['job_type']?.toString() ?? 'General',
      location: data['location_address']?.toString() ?? 'No location',
      // Handles both Boolean and Integer (0/1) formats
      isEmergency: data['is_emergency'] == true || data['is_emergency'] == 1,
      // Safely parse timestamps
      createdTime: data['created_time'] is Timestamp
          ? (data['created_time'] as Timestamp).toDate()
          : DateTime.now(),
      deadline: data['deadline'] is Timestamp
          ? (data['deadline'] as Timestamp).toDate()
          : null,
      status: data['status']?.toString() ?? 'Open',
      // Crucial: Firestore often returns 'num', so we must call .toDouble() safely
      offeredPrice: (data['offered_price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_user_id': customerUserId,
      'customer_name': customerName,
      'description': description,
      'job_type': jobType,
      'location_address': location,
      'is_emergency': isEmergency,
      'created_time': FieldValue.serverTimestamp(), // Better for consistency
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'status': status,
      'offered_price': offeredPrice,
    };
  }
}