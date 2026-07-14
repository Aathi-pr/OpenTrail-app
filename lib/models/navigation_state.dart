import 'package:latlong2/latlong.dart';

class NavigationState {
  final LatLng currentLocation;
  final LatLng destination;

  final List<LatLng> remainingRoute;
  final List<LatLng> completedRoute;

  final bool navigating;
  final bool arrived;

  final double remainingDistance;
  final double speed;
  final double heading;

  const NavigationState({
    required this.currentLocation,
    required this.destination,
    required this.remainingRoute,
    required this.completedRoute,
    required this.navigating,
    required this.arrived,
    required this.remainingDistance,
    required this.speed,
    required this.heading,
  });

  NavigationState copyWith({
    LatLng? currentLocation,
    LatLng? destination,
    List<LatLng>? remainingRoute,
    List<LatLng>? completedRoute,
    bool? navigating,
    bool? arrived,
    double? remainingDistance,
    double? speed,
    double? heading,
  }) {
    return NavigationState(
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination ?? this.destination,
      remainingRoute: remainingRoute ?? this.remainingRoute,
      completedRoute: completedRoute ?? this.completedRoute,
      navigating: navigating ?? this.navigating,
      arrived: arrived ?? this.arrived,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }
}
