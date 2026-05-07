import 'package:url_launcher/url_launcher.dart';

/// Navigation Utilities for Driver
/// Provides map navigation for delivery drivers
class NavigationUtils {
  /// Open Google Maps with directions from current location to destination
  static Future<void> navigateToLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    final Uri fallbackUrl = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude${label != null ? '(${Uri.encodeComponent(label)})' : ''}',
    );

    try {
      // Try Google Maps web URL first
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUrl)) {
        // Fallback to geo: scheme
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      throw Exception('Navigation failed: $e');
    }
  }

  /// Navigate to restaurant (pickup location)
  static Future<void> navigateToRestaurant({
    required double? latitude,
    required double? longitude,
    required String restaurantName,
    required String restaurantAddress,
  }) async {
    if (latitude == null || longitude == null) {
      // If no coordinates, try to search by name
      final Uri searchUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$restaurantName $restaurantAddress')}',
      );

      if (await canLaunchUrl(searchUrl)) {
        await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open maps');
      }
      return;
    }

    await navigateToLocation(
      latitude: latitude,
      longitude: longitude,
      label: '$restaurantName (Pickup)',
    );
  }

  /// Navigate to customer (delivery location)
  static Future<void> navigateToCustomer({
    required double? latitude,
    required double? longitude,
    required String customerName,
    required String deliveryAddress,
  }) async {
    if (latitude == null || longitude == null) {
      // If no coordinates, try to search by address
      final Uri searchUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(deliveryAddress)}',
      );

      if (await canLaunchUrl(searchUrl)) {
        await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open maps');
      }
      return;
    }

    await navigateToLocation(
      latitude: latitude,
      longitude: longitude,
      label: '$customerName (Delivery)',
    );
  }

  /// Call customer phone number
  static Future<void> callCustomer(String phoneNumber) async {
    final Uri telUrl = Uri.parse('tel:${phoneNumber.replaceAll(RegExp(r'\s+'), '')}');

    if (await canLaunchUrl(telUrl)) {
      await launchUrl(telUrl);
    } else {
      throw Exception('Could not launch phone dialer');
    }
  }
}
