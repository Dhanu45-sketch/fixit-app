// lib/utils/location_privacy.dart
// Privacy-safe location handling for maps

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'colors.dart';

class LocationPrivacy {
  /// Fuzz GPS coordinates for privacy
  /// Returns approximate location within specified radius
  static LatLng fuzzLocation(LatLng actualLocation, {double radiusKm = 1.5}) {
    // Don't fuzz if radius is 0
    if (radiusKm == 0) return actualLocation;

    final random = Random();

    // Convert km to degrees (rough approximation)
    // 1 degree latitude ≈ 111 km
    final radiusDegrees = radiusKm / 111.0;

    // Generate random offset
    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * radiusDegrees;

    final latOffset = distance * cos(angle);
    final lngOffset = distance * sin(angle) / cos(actualLocation.latitude * pi / 180);

    return LatLng(
      actualLocation.latitude + latOffset,
      actualLocation.longitude + lngOffset,
    );
  }

  /// Get privacy level based on booking status
  static double getPrivacyRadius(String bookingStatus, bool hasActiveBooking) {
    // No active booking: Show approximate area (1.5km radius)
    if (!hasActiveBooking) return 1.5;

    // Booking pending/confirmed: Medium precision (500m)
    if (bookingStatus == 'Pending' || bookingStatus == 'Confirmed') {
      return 0.5;
    }

    // Active service: High precision (100m)
    if (bookingStatus == 'In Progress') {
      return 0.1;
    }

    // Completed: Hide location
    return 1.5;
  }

  /// Calculate distance without exposing exact location
  static double calculateApproximateDistance(
      LatLng userLocation,
      LatLng handymanFuzzedLocation,
      ) {
    const double earthRadiusKm = 6371;

    final lat1 = userLocation.latitude * pi / 180;
    final lat2 = handymanFuzzedLocation.latitude * pi / 180;
    final dLat = (handymanFuzzedLocation.latitude - userLocation.latitude) * pi / 180;
    final dLng = (handymanFuzzedLocation.longitude - userLocation.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m away';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km away';
    } else {
      return '${distanceKm.round()} km away';
    }
  }

  /// Get neighborhood/area name from coordinates (requires geocoding)
  static Future<String> getAreaName(LatLng location) async {
    // This would use the geocoding package
    // For now, return a placeholder
    // In production, implement reverse geocoding
    return 'Kandy Area';
  }

  /// Check if handyman should be visible on map
  static bool shouldShowOnMap(
      Map<String, dynamic> handymanData,
      String? currentUserId,
      ) {
    // Don't show if handyman is unavailable
    if (handymanData['work_status'] != 'Available') {
      return false;
    }

    // Don't show if handyman has disabled location sharing
    if (handymanData['location_sharing_enabled'] == false) {
      return false;
    }

    // Don't show if handyman disabled map visibility
    if (handymanData['show_on_map'] == false) {
      return false;
    }

    return true;
  }

  /// Create privacy-safe marker
  static Marker createPrivacyMarker({
    required String handymanId,
    required LatLng fuzzedLocation,
    required bool hasActiveBooking,
    required String categoryName,
    required double distanceKm,
    required VoidCallback onTap,
  }) {
    return Marker(
      markerId: MarkerId(handymanId),
      position: fuzzedLocation,
      onTap: onTap,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        hasActiveBooking ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
      ),
      infoWindow: InfoWindow(
        title: categoryName,
        snippet: formatDistance(distanceKm),
      ),
      alpha: hasActiveBooking ? 1.0 : 0.8,
    );
  }

  /// Create privacy zone circle
  static Circle createPrivacyCircle({
    required String handymanId,
    required LatLng fuzzedLocation,
    required double radiusKm,
  }) {
    return Circle(
      circleId: CircleId('privacy_$handymanId'),
      center: fuzzedLocation,
      radius: radiusKm * 1000, // Convert km to meters
      fillColor: AppColors.primary.withOpacity(0.1),
      strokeColor: AppColors.primary.withOpacity(0.3),
      strokeWidth: 2,
    );
  }
}
