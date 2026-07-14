import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  Future<List<LatLng>> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final apiKey = dotenv.env['ORS_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("ORS_API_KEY not found in .env");
    }

    debugPrint("========== ROUTE REQUEST ==========");
    debugPrint("Start : ${start.latitude}, ${start.longitude}");
    debugPrint("End   : ${end.latitude}, ${end.longitude}");

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
    };

    debugPrint(jsonEncode(body));

    final response = await http.post(
      uri,
      headers: {"Authorization": apiKey, "Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    debugPrint("Status: ${response.statusCode}");
    debugPrint(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        "OpenRouteService Error (${response.statusCode})\n${response.body}",
      );
    }

    final data = jsonDecode(response.body);

    final List<dynamic> coords = data["features"][0]["geometry"]["coordinates"];

    return coords.map<LatLng>((c) {
      return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
    }).toList();
  }
}
