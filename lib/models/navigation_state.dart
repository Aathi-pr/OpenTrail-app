import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_trail/models/navigation_step.dart';

class NavigationState {
  final LatLng currentLocation;
  final LatLng snappedLocation;
  final Position? currentPosition;
  final LatLng destination;

  final List<LatLng> remainingRoute;
  final List<LatLng> completedRoute;
  final List<NavigationStep> steps;
  final int currentStepIndex;

  final bool navigating;
  final bool arrived;
  final bool offRoute;
  final bool rerouting;

  final double remainingDistance;
  final double remainingDuration;
  final double distanceToNextStep;
  final double speed;
  final double heading;

  NavigationState({
    required this.currentLocation,
    required this.snappedLocation,
    required this.currentPosition,
    required this.destination,
    required List<LatLng> remainingRoute,
    required List<LatLng> completedRoute,
    required List<NavigationStep> steps,
    required this.currentStepIndex,
    required this.navigating,
    required this.arrived,
    required this.offRoute,
    required this.rerouting,
    required this.remainingDistance,
    required this.remainingDuration,
    required this.distanceToNextStep,
    required this.speed,
    required this.heading,
  }) : remainingRoute = List.unmodifiable(remainingRoute),
       completedRoute = List.unmodifiable(completedRoute),
       steps = List.unmodifiable(steps);

  NavigationState copyWith({
    LatLng? currentLocation,
    LatLng? snappedLocation,
    Position? currentPosition,
    LatLng? destination,
    List<LatLng>? remainingRoute,
    List<LatLng>? completedRoute,
    List<NavigationStep>? steps,
    int? currentStepIndex,
    bool? navigating,
    bool? arrived,
    bool? offRoute,
    bool? rerouting,
    double? remainingDistance,
    double? remainingDuration,
    double? distanceToNextStep,
    double? speed,
    double? heading,
  }) {
    return NavigationState(
      currentLocation: currentLocation ?? this.currentLocation,
      snappedLocation: snappedLocation ?? this.snappedLocation,
      currentPosition: currentPosition ?? this.currentPosition,
      destination: destination ?? this.destination,
      remainingRoute: remainingRoute ?? this.remainingRoute,
      completedRoute: completedRoute ?? this.completedRoute,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      navigating: navigating ?? this.navigating,
      arrived: arrived ?? this.arrived,
      offRoute: offRoute ?? this.offRoute,
      rerouting: rerouting ?? this.rerouting,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      distanceToNextStep: distanceToNextStep ?? this.distanceToNextStep,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }
}
