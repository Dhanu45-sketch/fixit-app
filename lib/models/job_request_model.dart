// ==========================================
// FILE: lib/models/job_request_model.dart
// ==========================================
class JobRequest {
  final int id;
  final String customerName;
  final String description;
  final String jobType;
  final String location;
  final bool isEmergency;
  final DateTime createdTime;
  final DateTime? deadline;
  final String status;
  final double? offeredPrice;

  JobRequest({
    required this.id,
    required this.customerName,
    required this.description,
    required this.jobType,
    required this.location,
    required this.isEmergency,
    required this.createdTime,
    this.deadline,
    required this.status,
    this.offeredPrice,
  });

  factory JobRequest.fromJson(Map<String, dynamic> json) {
    return JobRequest(
      id: json['jobreq_id'],
      customerName: json['customer_name'],
      description: json['description'],
      jobType: json['job_type'],
      location: json['location'],
      isEmergency: json['is_emergency'] == 1,
      createdTime: DateTime.parse(json['created_time']),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: json['status'] ?? 'Open',
      offeredPrice: json['offered_price']?.toDouble(),
    );
  }
}
