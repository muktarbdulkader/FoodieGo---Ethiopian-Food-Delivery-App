import 'dart:math';

/// Location utilities for distance calculation
class LocationUtils {
  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;

    // Convert degrees to radians
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    // Haversine formula
    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1Rad) * cos(lat2Rad);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Calculate delivery fee based on distance
  /// Base fee: 20 ETB
  /// Additional: 5 ETB per km after first 2 km
  static double calculateDeliveryFee(double distanceKm) {
    const double baseFee = 20.0;
    const double freeDistanceKm = 2.0;
    const double pricePerKm = 5.0;

    if (distanceKm <= freeDistanceKm) {
      return baseFee;
    }

    final extraDistance = distanceKm - freeDistanceKm;
    return baseFee + (extraDistance * pricePerKm);
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Estimate delivery time based on distance
  /// Assumes average speed of 30 km/h in city
  static int estimateDeliveryTimeMinutes(double distanceKm) {
    const double averageSpeedKmPerHour = 30.0;
    const int preparationTimeMinutes = 15; // Restaurant preparation time

    final travelTimeMinutes = (distanceKm / averageSpeedKmPerHour * 60).ceil();
    return preparationTimeMinutes + travelTimeMinutes;
  }

  /// Format delivery time for display
  static String formatDeliveryTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
  }
}
