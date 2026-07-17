import 'package:latlong2/latlong.dart';
import 'package:open_trail/models/navigation_step.dart';

class NavigationState {
  final LatLng currentLocation;
  final LatLng destination;

  final List<LatLng> remainingRoute;
  final List<LatLng> completedRoute;
  final List<NavigationStep> steps;
  final int currentStepIndex;

  final bool navigating;
  final bool arrived;

  final double remainingDistance;
  final double remainingDuration;
  final double speed;
  final double heading;

  const NavigationState({
    required this.currentLocation,
    required this.destination,
    required this.remainingRoute,
    required this.completedRoute,
    required this.steps,
    required this.currentStepIndex,
    required this.navigating,
    required this.arrived,
    required this.remainingDistance,
    required this.remainingDuration,
    required this.speed,
    required this.heading,
  });

  NavigationState copyWith({
    LatLng? currentLocation,
    LatLng? destination,
    List<LatLng>? remainingRoute,
    List<LatLng>? completedRoute,
    List<NavigationStep>? steps,
    int? currentStepIndex,
    bool? navigating,
    bool? arrived,
    double? remainingDistance,
    double? remainingDuration,
    double? speed,
    double? heading,
  }) {
    return NavigationState(
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination ?? this.destination,
      remainingRoute: remainingRoute ?? this.remainingRoute,
      completedRoute: completedRoute ?? this.completedRoute,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      navigating: navigating ?? this.navigating,
      arrived: arrived ?? this.arrived,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }
}
