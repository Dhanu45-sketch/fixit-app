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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('users').doc(result.user!.uid).set({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'is_handyman': false,
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
    bool acceptsEmergencies = false,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = result.user!.uid;

      // 1. Basic Profile
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

      // 2. Handyman Statistics Profile
      await _db.collection('handymanProfiles').doc(uid).set({
        'user_id': uid,
        'category_id': categoryId,
        'category_name': categoryName,
        'experience': experience,
        'hourly_rate': hourlyRate,
        'bio': bio ?? '',
        'rating_avg': 0.0,
        'rating_count': 0,
        'jobs_completed': 0,
        'total_earnings': 0.0,
        'work_status': "Available",
        'accepts_emergencies': acceptsEmergencies,
        'emergency_earnings': 0.0,
        'emergency_jobs_count': 0,
        'approval_status': 'pending',
        'approval_submitted_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getHandymanApprovalStatus(String userId) async {
    try {
      final doc = await _db.collection('handymanProfiles').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data != null ? data['approval_status'] as String? : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
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
