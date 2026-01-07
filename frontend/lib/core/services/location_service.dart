import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Check and request location permissions
  static Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get address from coordinates
  static Future<Map<String, String>?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return {
          'address':
              '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}',
          'city': place.locality ?? place.subAdministrativeArea ?? '',
          'country': place.country ?? '',
        };
      }
    } catch (e) {
      // Geocoding failed
    }
    return null;
  }

  /// Get full location data (position + address)
  static Future<Map<String, dynamic>?> getFullLocation() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final address =
        await getAddressFromCoordinates(position.latitude, position.longitude);

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address?['address'] ?? 'Unknown location',
      'city': address?['city'] ?? 'Unknown city',
    };
  }
}
