import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookingId;
  final String customerId;
  final String customerName;
  final String handymanId;
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime createdAt;
  final String serviceName;
  final String? customerPhoto;

  Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.handymanId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.serviceName,
    this.customerPhoto,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      bookingId: data['booking_id'] ?? '',
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? 'Anonymous',
      handymanId: data['handyman_id'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      serviceName: data['service_name'] ?? 'Service',
      customerPhoto: data['customer_photo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'customer_id': customerId,
      'customer_name': customerName,
      'handyman_id': handymanId,
      'rating': rating,
      'comment': comment,
      'created_at': Timestamp.fromDate(createdAt),
      'service_name': serviceName,
      'customer_photo': customerPhoto,
    };
  }
}
