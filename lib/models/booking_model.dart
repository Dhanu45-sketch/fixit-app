import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String customerId;
  final String handymanId;
  final String customerName;
  final String serviceName;
  final String status; // Pending, Confirmed, Rejected, In Progress, Completed, Cancelled
  final DateTime scheduledStartTime;
  final double totalPrice;
  final String notes;
  final String address;
  final bool isEmergency;

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
  });

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
    };
  }
}