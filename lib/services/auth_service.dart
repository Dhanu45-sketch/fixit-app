import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  // Updated constructor to support dependency injection for testing
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Getters
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

  // --- GET SERVICE CATEGORIES ---
  Stream<List<Map<String, dynamic>>> getServiceCategories() {
    return _db.collection('serviceCategories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // --- SIGN IN ---
  Future<UserCredential?> signIn({required String email, required String password}) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // --- REGISTER CUSTOMER ---
  Future<UserCredential?> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    bool isHandyman = false,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('users').doc(result.user!.uid).set({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'is_handyman': isHandyman,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // --- REGISTER HANDYMAN ---
  Future<UserCredential?> registerHandyman({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String categoryId,
    required String categoryName,
    required int experience,
    required double hourlyRate,
    String? bio,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String uid = result.user!.uid;

      await _db.collection('users').doc(uid).set({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'is_handyman': true,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await _db.collection('handymanProfiles').doc(uid).set({
        'user_id': uid,
        'category_id': categoryId,
        'category_name': categoryName,
        'experience': experience,
        'hourly_rate': hourlyRate,
        'bio': bio ?? '',
        'rating_avg': 0.0,
        'jobs_completed': 0,
        'work_status': "Available",
        'updated_at': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

    // --- UPDATE USER PROFILE ---
  Future<bool> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    String? profilePictureUrl,
  }) async {
    try {
      final dataToUpdate = {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'address': address,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (profilePictureUrl != null) {
        dataToUpdate['profile_picture_url'] = profilePictureUrl;
      }

      await _db.collection('users').doc(userId).update(dataToUpdate);
      return true;
    } catch (e) {
      debugPrint("Error updating profile: $e");
      return false;
    }
  }


  // --- UTILS ---
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = user.uid; // Important: Add user ID to map
          return data;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
