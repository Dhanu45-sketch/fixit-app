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

      // 2. Create User Profile in Firestore
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
    bool acceptsEmergencies = false, // NEW: Emergency opt-in
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
        'is_handyman': true,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 3. Create Detailed Handyman Profile with Approval Status
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
        
        // EMERGENCY CONFIGURATION
        'accepts_emergencies': acceptsEmergencies,
        'emergency_earnings': 0.0, // Track total emergency earnings
        'emergency_jobs_count': 0, // Track emergency jobs completed
        
        // APPROVAL SYSTEM
        'approval_status': 'pending', // pending, approved, rejected, suspended
        'approval_submitted_at': FieldValue.serverTimestamp(),
        'approval_reviewed_at': null,
        'approval_reviewed_by': null,
        'approval_rejection_reason': null,
        
        'updated_at': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // --- CHECK APPROVAL STATUS ---
  Future<String?> getHandymanApprovalStatus(String userId) async {
    try {
      final doc = await _db.collection('handymanProfiles').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['approval_status'] as String?;
      }
      return null;
    } catch (e) {
      return null;
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
