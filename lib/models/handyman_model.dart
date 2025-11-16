// ==========================================
// FILE: lib/models/handyman_model.dart
// ==========================================
class Handyman {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePhoto;
  final String categoryName;
  final int experience;
  final double hourlyRate;
  final double rating;
  final int totalJobs;
  final String workStatus;
  final String? city;

  Handyman({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhoto,
    required this.categoryName,
    required this.experience,
    required this.hourlyRate,
    required this.rating,
    required this.totalJobs,
    required this.workStatus,
    this.city,
  });

  String get fullName => '$firstName $lastName';

  factory Handyman.fromJson(Map<String, dynamic> json) {
    return Handyman(
      id: json['handyman_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePhoto: json['profile_photo'],
      categoryName: json['category_name'],
      experience: json['experience'],
      hourlyRate: json['hourly_rate']?.toDouble() ?? 0.0,
      rating: json['rating']?.toDouble() ?? 0.0,
      totalJobs: json['total_jobs_completed'] ?? 0,
      workStatus: json['work_status'] ?? 'Available',
      city: json['city'],
    );
  }
}