import 'package:latlong2/latlong.dart';
import 'navigation_step.dart';

class NavigationRoute {
  final List<LatLng> geometry;
  final List<NavigationStep> steps;
  final double distanceMeters;
  final double durationSeconds;

  const NavigationRoute({
    required this.geometry,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}
