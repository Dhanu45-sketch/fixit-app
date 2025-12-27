import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final bool isHandyman;
  final String? profilePhoto;
  final GeoPoint? location;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.isHandyman,
    this.profilePhoto,
    this.location,
    this.isActive = true,
    this.createdAt,
  });

  // Helper to get full name directly
  String get fullName => '$firstName $lastName';

  // Helper to get initials for avatars
  String get initials => '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ""}'.toUpperCase();

  // Create a UserModel from a Firestore Document
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      isHandyman: data['is_handyman'] ?? false,
      profilePhoto: data['profile_photo'],
      location: data['location'] is GeoPoint ? data['location'] : null,
      isActive: data['is_active'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  // Convert UserModel to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'is_handyman': isHandyman,
      'profile_photo': profilePhoto,
      'location': location,
      'is_active': isActive,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}