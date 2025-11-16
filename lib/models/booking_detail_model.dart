// ==========================================
// FILE: lib/models/booking_detail_model.dart
// ==========================================
class BookingDetail {
  final int id;
  final String handymanName;
  final String? handymanPhoto;
  final String serviceType;
  final String description;
  final String location;
  final DateTime scheduledDate;
  final String scheduledTime;
  final int estimatedHours;
  final double amount;
  final String status; // Pending, Confirmed, In Progress, Completed, Cancelled
  final bool isEmergency;
  final String? customerName;
  final DateTime? completedDate;
  final double? rating;

  BookingDetail({
    required this.id,
    required this.handymanName,
    this.handymanPhoto,
    required this.serviceType,
    required this.description,
    required this.location,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.estimatedHours,
    required this.amount,
    required this.status,
    this.isEmergency = false,
    this.customerName,
    this.completedDate,
    this.rating,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      id: json['booking_id'],
      handymanName: json['handyman_name'],
      handymanPhoto: json['handyman_photo'],
      serviceType: json['service_type'],
      description: json['description'],
      location: json['location'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'],
      estimatedHours: json['estimated_hours'],
      amount: json['amount']?.toDouble() ?? 0.0,
      status: json['status'],
      isEmergency: json['is_emergency'] ?? false,
      customerName: json['customer_name'],
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'])
          : null,
      rating: json['rating']?.toDouble(),
    );
  }
}
