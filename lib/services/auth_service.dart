import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Getters
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

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
  }) async {
    try {
      // 1. Create User in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Create User Profile in Firestore aligned with your screenshot
      await _db.collection('users').doc(result.user!.uid).set({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'is_handyman': false, // Match screenshot field
        'is_active': true,    // Match screenshot field
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
      // 1. Create User in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = result.user!.uid;

      // 2. Create Basic User Profile
      await _db.collection('users').doc(uid).set({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'is_handyman': true, // Setting true for handyman
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 3. Create Detailed Handyman Profile aligned with your screenshot
      await _db.collection('handymanProfiles').doc(uid).set({
        'user_id': uid,                // Added to match screenshot
        'category_id': categoryId,     // e.g., 'plumbing'
        'category_name': categoryName, // e.g., 'Plumbing'
        'experience': experience,
        'hourly_rate': hourlyRate,
        'bio': bio ?? '',
        'rating_avg': 0.0,             // Initial value
        'jobs_completed': 0,           // Changed from review_count to match screenshot
        'work_status': "Available",    // Changed from is_available to match screenshot
        'updated_at': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      rethrow;
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
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}