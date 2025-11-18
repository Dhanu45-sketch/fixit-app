// ==========================================
// FILE: lib/models/booking_model.dart
// ==========================================
class Booking {
  final int id;
  final String customerName;
  final String jobDescription;
  final String location;
  final DateTime scheduledStartTime;
  final DateTime? estimatedEndTime;
  final String status;
  final double amount;

  Booking({
    required this.id,
    required this.customerName,
    required this.jobDescription,
    required this.location,
    required this.scheduledStartTime,
    this.estimatedEndTime,
    required this.status,
    required this.amount,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['booking_id'],
      customerName: json['customer_name'],
      jobDescription: json['job_description'],
      location: json['location'],
      scheduledStartTime: DateTime.parse(json['scheduled_start_time']),
      estimatedEndTime: json['estimated_end_time'] != null
          ? DateTime.parse(json['estimated_end_time'])
          : null,
      status: json['status'],
      amount: json['amount']?.toDouble() ?? 0.0,
    );
  }
}
