import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

/// Service for handling navigation to customer locations
/// Uses Google Maps URL scheme (100% FREE - no API costs)
class NavigationService {

  /// Opens Google Maps with directions to the specified location
  ///
  /// Tries in order:
  /// 1. Google Maps app (Android/iOS)
  /// 2. Apple Maps (iOS fallback)
  /// 3. Browser with Google Maps (final fallback)
  ///
  /// [latitude] Customer's latitude
  /// [longitude] Customer's longitude
  /// [address] Optional address for display
  ///
  /// Returns true if navigation opened successfully
  Future<bool> navigateToLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      // Method 1: Try Google Maps URL scheme (works on Android & iOS)
      final googleMapsUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving'
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication, // Opens in Maps app
        );
        return true;
      }

      // Method 2: Fallback to universal geo URI
      final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');

      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
        return true;
      }

      // Method 3: Final fallback - browser
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      return true;

    } catch (e) {
      debugPrint('Navigation error: $e');
      return false;
    }
  }

  /// Opens Google Maps with address-based navigation
  ///
  /// [address] Full address string (e.g., "123 Main St, Kandy, Sri Lanka")
  ///
  /// Returns true if navigation opened successfully
  Future<bool> navigateToAddress(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving'
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Navigation error: $e');
      return false;
    }
  }

  /// Opens phone dialer with customer's phone number
  ///
  /// [phoneNumber] Customer's phone number
  Future<bool> callCustomer(String phoneNumber) async {
    try {
      // Remove any spaces or special characters
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final url = Uri.parse('tel:$cleanNumber');

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Call error: $e');
      return false;
    }
  }

  /// Opens Google Maps to show the location (view only, no navigation)
  /// Useful for customers to see their own address
  ///
  /// [latitude] Location latitude
  /// [longitude] Location longitude
  Future<bool> viewLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('View location error: $e');
      return false;
    }
  }

  /// Calculate approximate distance between two points (in kilometers)
  /// Uses Haversine formula
  ///
  /// [lat1] Starting latitude
  /// [lon1] Starting longitude
  /// [lat2] Destination latitude
  /// [lon2] Destination longitude
  ///
  /// Returns distance in kilometers
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
            _sin(dLon / 2) * _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  // Helper math functions
  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => _nativeSin(x);
  double _cos(double x) => _nativeCos(x);
  double _sqrt(double x) => _nativeSqrt(x);
  double _atan2(double y, double x) => _nativeAtan2(y, x);

  // Native math functions
  double _nativeSin(double x) {
    // Using Taylor series approximation for sin
    double result = x;
    double term = x;
    for (int n = 1; n < 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }

  double _nativeCos(double x) {
    // Using Taylor series approximation for cos
    double result = 1.0;
    double term = 1.0;
    for (int n = 1; n < 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }

  double _nativeSqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;

    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _nativeAtan2(double y, double x) {
    if (x > 0) {
      return _atan(y / x);
    } else if (x < 0 && y >= 0) {
      return _atan(y / x) + 3.141592653589793;
    } else if (x < 0 && y < 0) {
      return _atan(y / x) - 3.141592653589793;
    } else if (x == 0 && y > 0) {
      return 3.141592653589793 / 2;
    } else if (x == 0 && y < 0) {
      return -3.141592653589793 / 2;
    }
    return 0;
  }

  double _atan(double x) {
    // Using Taylor series approximation for atan
    if (x.abs() > 1) {
      return (3.141592653589793 / 2) * (x > 0 ? 1 : -1) - _atan(1 / x);
    }

    double result = x;
    double term = x;
    for (int n = 1; n < 20; n++) {
      term *= -x * x * (2 * n - 1) / (2 * n + 1);
      result += term;
    }
    return result;
  }

  /// Format distance for display
  /// Returns "X.X km" or "XXX m" depending on distance
  String formatDistance(double kilometers) {
    if (kilometers < 1) {
      return '${(kilometers * 1000).round()} m';
    } else {
      return '${kilometers.toStringAsFixed(1)} km';
    }
  }

  /// Estimate travel time based on distance (rough estimate)
  /// Assumes average speed of 30 km/h in urban areas
  ///
  /// Returns estimated minutes
  int estimateTravelTime(double kilometers) {
    const averageSpeed = 30.0; // km/h in urban areas
    final hours = kilometers / averageSpeed;
    return (hours * 60).round();
  }

  /// Format travel time for display
  /// Returns "X mins" or "X hours Y mins"
  String formatTravelTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min${minutes != 1 ? 's' : ''}';
    } else {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      if (remainingMins == 0) {
        return '$hours hour${hours != 1 ? 's' : ''}';
      }
      return '$hours hr${hours != 1 ? 's' : ''} $remainingMins min${remainingMins != 1 ? 's' : ''}';
    }
  }
}