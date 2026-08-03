import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

@immutable
class NavigationEngineState {
  const NavigationEngineState({
    required this.gpsPosition,
    required this.filteredLocation,
    required this.heading,
    required this.speed,
  });

  final Position gpsPosition;

  final LatLng filteredLocation;

  final double heading;

  final double speed;

  LatLng get currentLocation => filteredLocation;

  bool get isMoving => speed > 0.5;

  bool get hasHeading => heading >= 0;

  NavigationEngineState copyWith({
    Position? gpsPosition,
    LatLng? filteredLocation,
    double? heading,
    double? speed,
  }) {
    return NavigationEngineState(
      gpsPosition: gpsPosition ?? this.gpsPosition,
      filteredLocation: filteredLocation ?? this.filteredLocation,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
    );
  }

  @override
  String toString() {
    return 'NavigationEngineState('
        'location: $currentLocation, '
        'heading: ${heading.toStringAsFixed(1)}, '
        'speed: ${speed.toStringAsFixed(2)} m/s'
        ')';
  }
}

class NavigationEngine extends ChangeNotifier {
  NavigationEngineState? _state;


  NavigationEngineState? get state => _state;

  bool get hasState => _state != null;

  void updatePosition(Position position) {
    _state = NavigationEngineState(
      gpsPosition: position,
      filteredLocation: LatLng(position.latitude, position.longitude),
      heading: _normalizeHeading(position.heading),
      speed: _normalizeSpeed(position.speed),
    );

    notifyListeners();
  }

  void reset() {
    _state = null;
    notifyListeners();
  }

  double _normalizeHeading(double heading) {
    if (!heading.isFinite || heading < 0) {
      return 0;
    }

    return heading % 360;
  }

  double _normalizeSpeed(double speed) {
    if (!speed.isFinite || speed < 0) {
      return 0;
    }

    return speed;
  }
}
