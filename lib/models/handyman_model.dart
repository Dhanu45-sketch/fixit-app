import 'package:cloud_firestore/cloud_firestore.dart';

class Handyman {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePhoto;
  final String categoryId;
  final String categoryName;
  final double hourlyRate;
  final int experience;
  final String bio;
  final double averageRating;
  final int totalJobsCompleted;
  final String workStatus;
  final List<String> certificates;

  Handyman({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhoto,
    required this.categoryId,
    required this.categoryName,
    required this.hourlyRate,
    required this.experience,
    required this.bio,
    this.averageRating = 0.0,
    this.totalJobsCompleted = 0,
    this.workStatus = 'Available',
    this.certificates = const [],
  });

  String get fullName => '$firstName $lastName';

  String get initials => '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ""}'.toUpperCase();

  factory Handyman.fromFirestore(DocumentSnapshot doc, Map<String, dynamic> userData) {
    final data = doc.data() as Map<String, dynamic>;
    return Handyman(
      id: doc.id,
      firstName: userData['first_name'] ?? '',
      lastName: userData['last_name'] ?? '',
      profilePhoto: userData['profile_image'] ?? userData['profile_photo'],
      categoryId: data['category_id'] ?? '',
      categoryName: data['category_name'] ?? '',
      hourlyRate: (data['hourly_rate'] ?? 0.0).toDouble(),
      experience: data['experience'] ?? 0,
      bio: data['bio'] ?? '',
      averageRating: (data['rating_avg'] ?? 0.0).toDouble(),
      totalJobsCompleted: data['jobs_completed'] ?? 0,
      workStatus: data['work_status'] ?? 'Available',
      certificates: List<String>.from(data['certificates'] ?? []),
    );
  }
}
