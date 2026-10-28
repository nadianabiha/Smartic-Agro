import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class LocationService {
  Future<bool> checkLocationService() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<ph.PermissionStatus> requestLocationPermission() async {
    return await ph.Permission.location.request();
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<Map<String, String>?> getLocationDetails(
      double lat, double lon) async {
    // Placeholder for reverse geocoding
    // You can integrate geocoding package here
    return {
      'latitude': lat.toStringAsFixed(6),
      'longitude': lon.toStringAsFixed(6),
    };
  }
}
