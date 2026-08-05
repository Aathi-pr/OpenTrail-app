import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/navigation_route.dart';
import '../models/navigation_state.dart';
import 'route_service.dart';

class NavigationService extends ChangeNotifier {
  NavigationService(this._routeService);

  static const double _arrivalDistanceMeters = 15;
  static const double _offRouteDistanceMeters = 40;
  static const double _stepReachedDistanceMeters = 20;
  static const Duration _rerouteCooldown = Duration(seconds: 8);
  static const double _metersPerDegree = 111320;

  final RouteService _routeService;
  final Distance _distance = const Distance();

  StreamSubscription<Position>? _gpsSubscription;

  NavigationState? _state;
  DateTime? _lastRerouteAt;
  bool _rerouting = false;
  List<LatLng> _fullRoute = [];
  double _routeGeometryDistanceMeters = 0;
  double _routeDurationSeconds = 0;
  double _completedDistanceMeters = 0;
  List<double> _stepDistanceMarkers = const [];

  NavigationState? get state => _state;

  bool get navigating => _state?.navigating ?? false;
  double get totalDistance => _routeGeometryDistanceMeters;
  double get completedDistance => _completedDistanceMeters;
  double get totalDuration => _routeDurationSeconds;
  double get remainingDistance => _state?.remainingDistance ?? 0;
  double get remainingDuration => _state?.remainingDuration ?? 0;
  double get currentSpeed => _state?.speed ?? 0;

  double get progress {
    if (_routeGeometryDistanceMeters <= 0) return 0;
    return (_completedDistanceMeters / _routeGeometryDistanceMeters).clamp(
      0.0,
      1.0,
    );
  }

  Future<void> previewRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    final route = await _routeService.getRoute(start: start, end: destination);
    _loadRoute(
      route: route,
      rawLocation: start,
      rawPosition: null,
      destination: destination,
      navigating: false,
    );
  }

  Future<void> startNavigation({
    required LatLng start,
    required LatLng destination,
  }) async {
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;

    final route = await _routeService.getRoute(start: start, end: destination);
    _loadRoute(
      route: route,
      rawLocation: start,
      rawPosition: null,
      destination: destination,
      navigating: true,
    );

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen(_handleGpsUpdate);
  }

  Future<void> stopNavigation() async {
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;

    final current = _state;
    if (current == null) return;

    _setState(current.copyWith(navigating: false, rerouting: false));
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  void _handleGpsUpdate(Position position) {
    final current = _state;
    if (current == null || !current.navigating) return;

    final rawLocation = LatLng(position.latitude, position.longitude);

    if (_isAtDestination(rawLocation, current.destination)) {
      unawaited(_completeArrival(position, current.destination));
      return;
    }

    final projection = _snapToRoute(rawLocation, _fullRoute);

    final offRoute =
        _distanceFromRoute(rawLocation, _fullRoute) > _offRouteDistanceMeters;

    if (offRoute) {
      _setState(
        current.copyWith(
          currentLocation: rawLocation,
          snappedLocation: projection.point,
          currentPosition: position,
          offRoute: true,
          rerouting: _rerouting,
          speed: _normalSpeed(position.speed),
          heading: position.heading,
        ),
      );
      unawaited(_maybeReroute(rawLocation, current.destination));
      return;
    }

    final progress = _advanceRoute(current, projection);
    _completedDistanceMeters = projection.distanceAlongRouteMeters;
    final currentStepIndex = _advanceStepIndex(
      current.currentStepIndex,
      _completedDistanceMeters,
    );
    final remainingDistance = _polylineDistanceMeters(progress.remainingRoute);
    final remainingDuration = _remainingDurationFor(remainingDistance);

    _setState(
      current.copyWith(
        currentLocation: rawLocation,
        snappedLocation: projection.point,
        currentPosition: position,
        remainingRoute: progress.remainingRoute,
        completedRoute: progress.completedRoute,
        currentStepIndex: currentStepIndex,
        offRoute: false,
        rerouting: false,
        remainingDistance: remainingDistance,
        remainingDuration: remainingDuration,
        distanceToNextStep: _distanceToStep(currentStepIndex),
        speed: _normalSpeed(position.speed),
        heading: position.heading,
      ),
    );
  }

  void _loadRoute({
    required NavigationRoute route,
    required LatLng rawLocation,
    required Position? rawPosition,
    required LatLng destination,
    required bool navigating,
  }) {
    final geometry = route.geometry.length >= 2
        ? List<LatLng>.of(route.geometry)
        : <LatLng>[rawLocation, destination];
    _fullRoute = List<LatLng>.from(geometry);
    final projection = _snapToRoute(rawLocation, _fullRoute);
    _routeGeometryDistanceMeters = _polylineDistanceMeters(geometry);
    _routeDurationSeconds = route.durationSeconds;
    _completedDistanceMeters = projection.distanceAlongRouteMeters;
    _stepDistanceMarkers = _buildStepDistanceMarkers(geometry, route);

    final initialProgress = _RouteProgress(
      completedRoute: <LatLng>[geometry.first, projection.point],
      remainingRoute: <LatLng>[
        projection.point,
        ...geometry.skip(projection.segmentIndex + 1),
      ],
    );
    final currentStepIndex = _advanceStepIndex(0, _completedDistanceMeters);
    final remainingDistance = _polylineDistanceMeters(
      initialProgress.remainingRoute,
    );
    final completedRoute = navigating
        ? initialProgress.completedRoute
        : const <LatLng>[];

    _setState(
      NavigationState(
        currentLocation: rawLocation,
        snappedLocation: projection.point,
        currentPosition: rawPosition,
        destination: destination,
        remainingRoute: initialProgress.remainingRoute,
        completedRoute: completedRoute,
        steps: route.steps,
        currentStepIndex: currentStepIndex,
        navigating: navigating,
        arrived: false,
        offRoute: projection.distanceMeters > _offRouteDistanceMeters,
        rerouting: false,
        remainingDistance: remainingDistance,
        remainingDuration: _remainingDurationFor(remainingDistance),
        distanceToNextStep: _distanceToStep(currentStepIndex),
        speed: _normalSpeed(rawPosition?.speed ?? 0),
        heading: rawPosition?.heading ?? 0,
      ),
    );
  }

  Future<void> _completeArrival(Position position, LatLng destination) async {
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;

    final current = _state;
    if (current == null) return;

    _setState(
      current.copyWith(
        currentLocation: LatLng(position.latitude, position.longitude),
        snappedLocation: destination,
        currentPosition: position,
        remainingRoute: <LatLng>[destination],
        completedRoute: <LatLng>[...current.completedRoute, destination],
        navigating: false,
        arrived: true,
        offRoute: false,
        rerouting: false,
        remainingDistance: 0,
        remainingDuration: 0,
        distanceToNextStep: 0,
        speed: _normalSpeed(position.speed),
        heading: position.heading,
      ),
    );
  }

  Future<void> _maybeReroute(LatLng start, LatLng destination) async {
    if (_rerouting) return;

    final now = DateTime.now();
    final lastRerouteAt = _lastRerouteAt;
    if (lastRerouteAt != null &&
        now.difference(lastRerouteAt) < _rerouteCooldown) {
      return;
    }

    _rerouting = true;
    _lastRerouteAt = now;

    final current = _state;
    if (current != null) {
      _setState(current.copyWith(rerouting: true));
    }

    try {
      final route = await _routeService.getRoute(
        start: start,
        end: destination,
      );

      if (_state?.navigating != true) return;

      _loadRoute(
        route: route,
        rawLocation: start,
        rawPosition: _state?.currentPosition,
        destination: destination,
        navigating: true,
      );
    } catch (e) {
      final latest = _state;
      if (latest != null) {
        _setState(latest.copyWith(rerouting: false));
      }
    } finally {
      _rerouting = false;
    }
  }

  _RouteProgress _advanceRoute(
    NavigationState current,
    _RouteProjection projection,
  ) {
    {
      final completedRoute = <LatLng>[];

      for (
        var i = 0;
        i <= projection.segmentIndex && i < _fullRoute.length;
        i++
      ) {
        _appendIfSeparated(completedRoute, _fullRoute[i]);
      }
      _appendIfSeparated(completedRoute, projection.point);

      final remainingRoute = <LatLng>[projection.point];
      if (projection.segmentIndex + 1 < _fullRoute.length) {
        remainingRoute.addAll(_fullRoute.skip(projection.segmentIndex + 1));
      }

      return _RouteProgress(
        completedRoute: completedRoute,
        remainingRoute: remainingRoute,
      );
    }
  }

  _RouteProjection _snapToRoute(LatLng point, List<LatLng> route) {
    if (route.isEmpty) {
      return _RouteProjection(
        point: point,
        distanceMeters: 0,
        segmentIndex: 0,
        distanceAlongRouteMeters: 0,
      );
    }

    if (route.length == 1) {
      return _RouteProjection(
        point: route.first,
        distanceMeters: _distance.as(LengthUnit.Meter, point, route.first),
        segmentIndex: 0,
        distanceAlongRouteMeters: 0,
      );
    }

    var bestProjection = _projectPointOnSegment(point, route[0], route[1]);
    var bestSegmentIndex = 0;
    var bestDistanceAlongRoute =
        bestProjection.segmentDistanceMeters * bestProjection.segmentFraction;
    var distanceBeforeSegment = 0.0;

    for (var i = 0; i < route.length - 1; i++) {
      final segmentProjection = _projectPointOnSegment(
        point,
        route[i],
        route[i + 1],
      );

      if (segmentProjection.distanceMeters < bestProjection.distanceMeters) {
        bestProjection = segmentProjection;
        bestSegmentIndex = i;
        bestDistanceAlongRoute =
            distanceBeforeSegment +
            segmentProjection.segmentDistanceMeters *
                segmentProjection.segmentFraction;
      }

      distanceBeforeSegment += _distance.as(
        LengthUnit.Meter,
        route[i],
        route[i + 1],
      );
    }

    return _RouteProjection(
      point: bestProjection.point,
      distanceMeters: bestProjection.distanceMeters,
      segmentIndex: bestSegmentIndex,
      distanceAlongRouteMeters: bestDistanceAlongRoute,
    );
  }

  _SegmentProjection _projectPointOnSegment(
    LatLng point,
    LatLng segmentStart,
    LatLng segmentEnd,
  ) {
    final originLatRadians = segmentStart.latitude * math.pi / 180;
    final longitudeScale = math.cos(originLatRadians) * _metersPerDegree;

    final pointX = (point.longitude - segmentStart.longitude) * longitudeScale;
    final pointY = (point.latitude - segmentStart.latitude) * _metersPerDegree;
    final segmentX =
        (segmentEnd.longitude - segmentStart.longitude) * longitudeScale;
    final segmentY =
        (segmentEnd.latitude - segmentStart.latitude) * _metersPerDegree;
    final segmentLengthSquared = segmentX * segmentX + segmentY * segmentY;

    if (segmentLengthSquared == 0) {
      return _SegmentProjection(
        point: segmentStart,
        distanceMeters: _distance.as(LengthUnit.Meter, point, segmentStart),
        segmentFraction: 0,
        segmentDistanceMeters: 0,
      );
    }

    // Project AP onto AB using dot(AP, AB) / |AB|^2, then clamp so the snapped
    // point stays on the finite route segment rather than the infinite line.
    final fraction =
        ((pointX * segmentX + pointY * segmentY) / segmentLengthSquared).clamp(
          0.0,
          1.0,
        );
    final projectedX = segmentX * fraction;
    final projectedY = segmentY * fraction;
    final projected = LatLng(
      segmentStart.latitude + projectedY / _metersPerDegree,
      segmentStart.longitude + projectedX / longitudeScale,
    );

    final dx = pointX - projectedX;
    final dy = pointY - projectedY;

    return _SegmentProjection(
      point: projected,
      distanceMeters: math.sqrt(dx * dx + dy * dy),
      segmentFraction: fraction,
      segmentDistanceMeters: math.sqrt(segmentLengthSquared),
    );
  }

  double _distanceFromRoute(LatLng point, List<LatLng> route) {
    return _snapToRoute(point, route).distanceMeters;
  }

  List<double> _buildStepDistanceMarkers(
    List<LatLng> geometry,
    NavigationRoute route,
  ) {
    if (route.steps.isEmpty || geometry.isEmpty) return const [];

    final distancesAtPoint = <double>[0];
    var total = 0.0;
    for (var i = 1; i < geometry.length; i++) {
      total += _distance.as(LengthUnit.Meter, geometry[i - 1], geometry[i]);
      distancesAtPoint.add(total);
    }

    return route.steps
        .map((step) {
          final waypointIndex = step.waypointIndex
              .clamp(0, distancesAtPoint.length - 1)
              .toInt();
          return distancesAtPoint[waypointIndex];
        })
        .toList(growable: false);
  }

  int _advanceStepIndex(int currentStepIndex, double completedDistanceMeters) {
    var nextIndex = currentStepIndex;

    while (nextIndex < _stepDistanceMarkers.length - 1 &&
        completedDistanceMeters + _stepReachedDistanceMeters >=
            _stepDistanceMarkers[nextIndex]) {
      nextIndex++;
    }

    return nextIndex;
  }

  double _distanceToStep(int currentStepIndex) {
    if (_stepDistanceMarkers.isEmpty ||
        currentStepIndex < 0 ||
        currentStepIndex >= _stepDistanceMarkers.length) {
      final latest = _state;
      return latest == null
          ? 0
          : _distance.as(
              LengthUnit.Meter,
              latest.snappedLocation,
              latest.destination,
            );
    }

    return math.max(
      0,
      _stepDistanceMarkers[currentStepIndex] - _completedDistanceMeters,
    );
  }

  double _polylineDistanceMeters(List<LatLng> points) {
    if (points.length < 2) return 0;

    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += _distance.as(LengthUnit.Meter, points[i - 1], points[i]);
    }
    return total;
  }

  double _remainingDurationFor(double remainingDistanceMeters) {
    if (_routeGeometryDistanceMeters <= 0) return _routeDurationSeconds;

    final routeFraction =
        (remainingDistanceMeters / _routeGeometryDistanceMeters).clamp(
          0.0,
          1.0,
        );
    return _routeDurationSeconds * routeFraction;
  }

  bool _isAtDestination(LatLng location, LatLng destination) {
    return _distance.as(LengthUnit.Meter, location, destination) <=
        _arrivalDistanceMeters;
  }

  void _appendIfSeparated(List<LatLng> points, LatLng next) {
    if (points.isEmpty ||
        _distance.as(LengthUnit.Meter, points.last, next) > 0.5) {
      points.add(next);
    }
  }

  double _normalSpeed(double speed) => speed.isFinite ? math.max(0, speed) : 0;

  void _setState(NavigationState state) {
    _state = state;
    notifyListeners();
  }
}

class _RouteProgress {
  const _RouteProgress({
    required this.completedRoute,
    required this.remainingRoute,
  });

  final List<LatLng> completedRoute;
  final List<LatLng> remainingRoute;
}

class _RouteProjection {
  const _RouteProjection({
    required this.point,
    required this.distanceMeters,
    required this.segmentIndex,
    required this.distanceAlongRouteMeters,
  });

  final LatLng point;
  final double distanceMeters;
  final int segmentIndex;
  final double distanceAlongRouteMeters;
}

class _SegmentProjection {
  const _SegmentProjection({
    required this.point,
    required this.distanceMeters,
    required this.segmentFraction,
    required this.segmentDistanceMeters,
  });

  final LatLng point;
  final double distanceMeters;
  final double segmentFraction;
  final double segmentDistanceMeters;
}
