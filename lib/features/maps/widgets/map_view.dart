import 'package:flutter/cupertino.dart';
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

    // NEW
    this.meetingPoint,
    this.meetingPointRoute,
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

  // ============================================================
  // COMMUNITY RIDE MEETING POINT
  // ============================================================

  final LatLng? meetingPoint;

  final List<LatLng>? meetingPointRoute;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,

      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
      ),

      children: [
        // ========================================================
        // MAP
        // ========================================================
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

        // ========================================================
        // COMMUNITY MEETING ROUTE
        //
        // This is intentionally separate from the navigation
        // route so instant rides are completely unaffected.
        // ========================================================
        if (meetingPointRoute != null && meetingPointRoute!.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: meetingPointRoute!,
                strokeWidth: 3.5,
                color: const Color(0xFF8B8B8B),
              ),
            ],
          ),

        // ========================================================
        // MEETING POINT MARKER
        // ========================================================
        if (meetingPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: meetingPoint!,
                width: 44,
                height: 44,

                child: _MeetingPointMarker(),
              ),
            ],
          ),

        // ========================================================
        // CURRENT USER
        // ========================================================
        if (currentPosition != null)
          UserMarkerLayer(
            currentPosition: currentPosition,
            navigationPosition: navigationPosition,
            userName: cachedUserName,
            isLeader: isLeader,
          ),

        // ========================================================
        // OTHER RIDERS
        // ========================================================
        if (otherRiders.isNotEmpty) ConvoyMarkerLayer(riders: otherRiders),

        // ========================================================
        // DESTINATION
        // ========================================================
        if (searchedLocation != null)
          DestinationMarkerLayer(destination: searchedLocation!),

        // ========================================================
        // NAVIGATION ROUTES
        // ========================================================
        if (completedRoute.isNotEmpty)
          CompletedRouteLayer(route: completedRoute),

        if (remainingRoute.isNotEmpty)
          RemainingRouteLayer(route: remainingRoute),

        // ========================================================
        // LEADER → RIDER ROUTES
        // ========================================================
        if (leaderRoutes.isNotEmpty) LeaderRouteLayer(routes: leaderRoutes),

        // ========================================================
        // WAYPOINTS
        // ========================================================
        if (waypoints.isNotEmpty)
          WaypointLayer(waypoints: waypoints, onWaypointTap: onWaypointTap),
      ],
    );
  }
}

// ================================================================
// MEETING POINT MARKER
// ================================================================

class _MeetingPointMarker extends StatelessWidget {
  const _MeetingPointMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 30,
        height: 30,

        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F2),
          shape: BoxShape.circle,

          border: Border.all(color: const Color(0xFF080808), width: 3),

          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 8, spreadRadius: 1),
          ],
        ),

        child: const Icon(
          CupertinoIcons.flag_fill,
          size: 13,
          color: Color(0xFF080808),
        ),
      ),
    );
  }
}
