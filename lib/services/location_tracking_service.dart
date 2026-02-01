import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  // Start tracking location for handymen
  Future<void> startTracking({
    required String specialty,
    int updateIntervalSeconds = 30, // Update every 30 seconds
  }) async {
    if (_isTracking) return;

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Check and request location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }

    _isTracking = true;

    // Get user profile for name
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final name = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();

    // Start listening to position updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update when moved 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      await _updateLocationInFirestore(
        uid: user.uid,
        lat: position.latitude,
        lng: position.longitude,
        specialty: specialty,
        name: name,
      );
    });

    // Also update on a timer (fallback)
    _locationUpdateTimer = Timer.periodic(
      Duration(seconds: updateIntervalSeconds),
      (timer) async {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          await _updateLocationInFirestore(
            uid: user.uid,
            lat: position.latitude,
            lng: position.longitude,
            specialty: specialty,
            name: name,
          );
        } catch (e) {
          print('Error updating location: $e');
        }
      },
    );

    print('Location tracking started');
  }

  // Update location in Firestore
  Future<void> _updateLocationInFirestore({
    required String uid,
    required double lat,
    required double lng,
    required String specialty,
    required String name,
  }) async {
    try {
      await _firestore.collection('liveLocations').doc(uid).set({
        'role': 'handyman',
        'specialty': specialty,
        'approxLat': lat,
        'approxLng': lng,
        'availability': 'online',
        'lastUpdated': FieldValue.serverTimestamp(),
        'name': name,
      }, SetOptions(merge: true));

      print('Location updated: $lat, $lng');
    } catch (e) {
      print('Error updating location in Firestore: $e');
    }
  }

  // Stop tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _isTracking = false;
    
    // Cancel timers and subscriptions
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    // Update availability to offline
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('liveLocations').doc(user.uid).update({
          'availability': 'offline',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating offline status: $e');
      }
    }

    print('Location tracking stopped');
  }

  // Update work status
  Future<void> updateAvailability(String status) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('liveLocations').doc(user.uid).update({
        'availability': status, // 'online', 'offline', 'busy'
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating availability: $e');
    }
  }

  // Get current tracking status
  bool get isTracking => _isTracking;

  // Dispose
  void dispose() {
    stopTracking();
  }
}
