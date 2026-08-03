import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_trail/features/maps/widgets/layers/completed_route_layer.dart';
import 'package:open_trail/features/maps/widgets/layers/convoy_marker_layer.dart';
import 'package:open_trail/features/maps/widgets/layers/destination_marker_layer.dart';
import 'package:open_trail/features/maps/widgets/layers/leader_route_layer.dart';
import 'package:open_trail/features/maps/widgets/layers/remaining_route_layer.dart';
import 'package:open_trail/features/maps/widgets/layers/user_marker_layer.dart';
import 'package:open_trail/features/maps/widgets/layers/waypoint_layer.dart';
import 'package:open_trail/models/rider_location_model.dart';
import 'package:open_trail/models/waypoint_model.dart';

class MapView extends StatelessWidget {
  const MapView({
    super.key,
    required this.mapController,
    required this.initialCenter,
    required this.initialZoom,
    required this.isSatelliteMode,
    required this.currentPosition,
    required this.navigationPosition,
    required this.searchedLocation,
    required this.completedRoute,
    required this.remainingRoute,
    required this.otherRiders,
    required this.waypoints,
    required this.onWaypointTap,
    required this.leaderRoutes,
    required this.cachedUserName,
    required this.isLeader,
  });

  final MapController mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final bool isSatelliteMode;

  final Position? currentPosition;
  final Position? navigationPosition;

  final LatLng? searchedLocation;

  final List<LatLng> completedRoute;
  final List<LatLng> remainingRoute;

  final List<RiderLocationModel> otherRiders;
  final Map<String, List<LatLng>> leaderRoutes;
  final List<WaypointModel> waypoints;
  final ValueChanged<WaypointModel> onWaypointTap;

  final String cachedUserName;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
          additionalOptions: {
            'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
            'id': isSatelliteMode
                ? 'mapbox/satellite-streets-v12'
                : 'mapbox/dark-v11',
          },
          tileDimension: 512,
          zoomOffset: -1,
        ),

        if (currentPosition != null)
          UserMarkerLayer(
            currentPosition: currentPosition,
            navigationPosition: navigationPosition,
            userName: cachedUserName,
            isLeader: isLeader,
          ),

        if (otherRiders.isNotEmpty) ConvoyMarkerLayer(riders: otherRiders),

        if (searchedLocation != null)
          DestinationMarkerLayer(destination: searchedLocation!),

        if (completedRoute.isNotEmpty)
          CompletedRouteLayer(route: completedRoute),

        if (remainingRoute.isNotEmpty)
          RemainingRouteLayer(route: remainingRoute),

        if (leaderRoutes.isNotEmpty) LeaderRouteLayer(routes: leaderRoutes),

        if (waypoints.isNotEmpty)
          WaypointLayer(waypoints: waypoints, onWaypointTap: onWaypointTap),
      ],
    );
  }
}
