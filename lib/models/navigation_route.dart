import 'package:latlong2/latlong.dart';
import 'navigation_step.dart';

class NavigationRoute {
  final List<LatLng> geometry;
  final List<NavigationStep> steps;

  const NavigationRoute({required this.geometry, required this.steps});
}
