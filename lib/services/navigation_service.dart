import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/navigation_state.dart';
import 'route_service.dart';

class NavigationService extends ChangeNotifier {
  NavigationService(this._routeService);

  final RouteService _routeService;

  StreamSubscription<Position>? _gpsSubscription;

  NavigationState? _state;

  NavigationState? get state => _state;

  bool get navigating => _state?.navigating ?? false;

  Future<void> startNavigation({
    required LatLng start,
    required LatLng destination,
  }) async {}

  Future<void> stopNavigation() async {}

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }
}
