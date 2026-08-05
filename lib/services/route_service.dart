import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:open_trail/models/navigation_route.dart';
import 'package:open_trail/models/navigation_step.dart';

class RouteService {
  Future<NavigationRoute> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final apiKey = dotenv.env['ORS_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("ORS_API_KEY not found in .env");
    }

    // Basic validation
    if (start.latitude.abs() > 90 ||
        end.latitude.abs() > 90 ||
        start.longitude.abs() > 180 ||
        end.longitude.abs() > 180) {
      throw Exception("Invalid latitude/longitude.");
    }

    final uri = Uri.parse(
      "https://api.openrouteservice.org/v2/directions/driving-car/geojson",
    );

    final body = {
      "coordinates": [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ],
      "instructions": true,
      "instructions_format": "text",
    };

    final response = await http.post(
      uri,
      headers: {"Authorization": apiKey, "Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "OpenRouteService Error (${response.statusCode})\n${response.body}",
      );
    }

    final data = jsonDecode(response.body);

    final List<dynamic> coords = data["features"][0]["geometry"]["coordinates"];

    final segment = data["features"][0]["properties"]["segments"][0];

    final steps = (segment["steps"] as List)
        .map(
          (step) => NavigationStep(
            instruction: step["instruction"],
            distance: (step["distance"] as num).toDouble(),
            duration: (step["duration"] as num).toDouble(),
            type: step["type"],
            waypointIndex: step["way_points"][1],
          ),
        )
        .toList();

    final geometry = coords.map<LatLng>((c) {
      return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
    }).toList();

    return NavigationRoute(
      geometry: geometry,
      steps: steps,
      distanceMeters: (segment["distance"] as num).toDouble(),
      durationSeconds: (segment["duration"] as num).toDouble(),
    );
  }
}
