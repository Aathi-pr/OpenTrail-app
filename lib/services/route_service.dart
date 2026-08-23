import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:open_trail/models/navigation_route.dart';
import 'package:open_trail/models/navigation_step.dart';

class RouteService {
  RouteService();

  static const String _baseUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car/geojson';

  static const double _routingRadiusMeters = 1000;

  Future<NavigationRoute> getRoute({
    LatLng? start,
    LatLng? end,
    List<LatLng>? coordinates,
  }) async {
    final apiKey = dotenv.env['ORS_API_KEY'];

    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('ORS_API_KEY not found in .env');
    }

    late final List<LatLng> routeCoordinates;

    if (coordinates != null) {
      if (coordinates.length < 2) {
        throw Exception('At least two coordinates are required.');
      }

      routeCoordinates = List<LatLng>.from(coordinates);
    } else if (start != null && end != null) {
      routeCoordinates = [start, end];
    } else {
      throw Exception('Route requires either start/end or coordinates.');
    }

    for (int index = 0; index < routeCoordinates.length; index++) {
      final coordinate = routeCoordinates[index];

      if (!_isValidCoordinate(coordinate)) {
        throw Exception(
          'Invalid coordinate at point ${index + 1}:\n'
          '${coordinate.latitude}, '
          '${coordinate.longitude}',
        );
      }
    }

    final cleanedCoordinates = _removeConsecutiveDuplicates(routeCoordinates);

    if (cleanedCoordinates.length < 2) {
      throw Exception(
        'The selected route points are identical.\n'
        'Please select different locations.',
      );
    }

    final orsCoordinates = cleanedCoordinates
        .map((coordinate) => [coordinate.longitude, coordinate.latitude])
        .toList();

    final body = <String, dynamic>{
      'coordinates': orsCoordinates,

      'instructions': true,

      'instructions_format': 'text',

      'radiuses': List<double>.filled(
        cleanedCoordinates.length,
        _routingRadiusMeters,
      ),
    };

    final uri = Uri.parse(_baseUrl);

    late final http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {
          'Authorization': apiKey.trim(),

          'Content-Type': 'application/json; charset=utf-8',

          'Accept':
              'application/json, '
              'application/geo+json, '
              'application/gpx+xml, '
              'img/png; charset=utf-8',
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw Exception(
        'Unable to connect to OpenRouteService.\n\n'
        'Please check your internet connection and try again.',
      );
    }

    if (response.statusCode != 200) {
      throw _createRouteError(
        statusCode: response.statusCode,
        responseBody: response.body,
        coordinates: cleanedCoordinates,
      );
    }

    late final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('OpenRouteService returned an invalid response.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response received from OpenRouteService.');
    }

    final features = decoded['features'];

    if (features is! List || features.isEmpty) {
      throw Exception('OpenRouteService returned no route.');
    }

    final firstFeature = features.first;

    if (firstFeature is! Map) {
      throw Exception('OpenRouteService returned an invalid route feature.');
    }

    final geometryData = firstFeature['geometry'];

    if (geometryData is! Map) {
      throw Exception('Route geometry is missing.');
    }

    final rawCoordinates = geometryData['coordinates'];

    if (rawCoordinates is! List || rawCoordinates.isEmpty) {
      throw Exception('Route geometry contains no coordinates.');
    }

    final geometry = <LatLng>[];

    for (final rawCoordinate in rawCoordinates) {
      if (rawCoordinate is! List || rawCoordinate.length < 2) {
        continue;
      }

      final longitudeValue = rawCoordinate[0];
      final latitudeValue = rawCoordinate[1];

      if (longitudeValue is! num || latitudeValue is! num) {
        continue;
      }

      final longitude = longitudeValue.toDouble();

      final latitude = latitudeValue.toDouble();

      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        continue;
      }

      geometry.add(LatLng(latitude, longitude));
    }

    if (geometry.isEmpty) {
      throw Exception('Unable to decode route geometry.');
    }

    final properties = firstFeature['properties'];

    if (properties is! Map) {
      throw Exception('Route properties are missing.');
    }

    final rawSegments = properties['segments'];

    if (rawSegments is! List || rawSegments.isEmpty) {
      throw Exception('Route segments are missing.');
    }

    final steps = <NavigationStep>[];

    double totalDistanceMeters = 0;

    double totalDurationSeconds = 0;

    for (final rawSegment in rawSegments) {
      if (rawSegment is! Map) {
        continue;
      }

      final segmentDistance = (rawSegment['distance'] as num?)?.toDouble() ?? 0;

      final segmentDuration = (rawSegment['duration'] as num?)?.toDouble() ?? 0;

      totalDistanceMeters += segmentDistance;

      totalDurationSeconds += segmentDuration;

      final rawSteps = rawSegment['steps'];

      if (rawSteps is! List) {
        continue;
      }

      for (final rawStep in rawSteps) {
        if (rawStep is! Map) {
          continue;
        }

        final instruction = rawStep['instruction'] as String? ?? '';

        final distance = (rawStep['distance'] as num?)?.toDouble() ?? 0;

        final duration = (rawStep['duration'] as num?)?.toDouble() ?? 0;

        final type = (rawStep['type'] as num?)?.toInt() ?? 0;

        final rawWayPoints = rawStep['way_points'];

        int waypointIndex = 0;

        if (rawWayPoints is List && rawWayPoints.length >= 2) {
          final rawIndex = rawWayPoints[1];

          if (rawIndex is num) {
            waypointIndex = rawIndex.toInt();
          }
        }

        steps.add(
          NavigationStep(
            instruction: instruction,
            distance: distance,
            duration: duration,
            type: type,
            waypointIndex: waypointIndex,
          ),
        );
      }
    }

    if (totalDistanceMeters <= 0 || totalDurationSeconds <= 0) {
      final summary = properties['summary'];

      if (summary is Map) {
        final summaryDistance = (summary['distance'] as num?)?.toDouble() ?? 0;

        final summaryDuration = (summary['duration'] as num?)?.toDouble() ?? 0;

        if (totalDistanceMeters <= 0) {
          totalDistanceMeters = summaryDistance;
        }

        if (totalDurationSeconds <= 0) {
          totalDurationSeconds = summaryDuration;
        }
      }
    }

    if (totalDistanceMeters <= 0) {
      throw Exception(
        'OpenRouteService returned a route '
        'without a valid distance.',
      );
    }

    return NavigationRoute(
      geometry: geometry,
      steps: steps,
      distanceMeters: totalDistanceMeters,
      durationSeconds: totalDurationSeconds,
    );
  }

  List<LatLng> _removeConsecutiveDuplicates(List<LatLng> coordinates) {
    if (coordinates.isEmpty) {
      return [];
    }

    final result = <LatLng>[coordinates.first];

    for (int index = 1; index < coordinates.length; index++) {
      final previous = result.last;

      final current = coordinates[index];

      if (previous.latitude == current.latitude &&
          previous.longitude == current.longitude) {
        continue;
      }

      result.add(current);
    }

    return result;
  }

  bool _isValidCoordinate(LatLng coordinate) {
    return coordinate.latitude >= -90 &&
        coordinate.latitude <= 90 &&
        coordinate.longitude >= -180 &&
        coordinate.longitude <= 180;
  }

  Exception _createRouteError({
    required int statusCode,
    required String responseBody,
    required List<LatLng> coordinates,
  }) {
    if (statusCode == 404) {
      final coordinateIndex = _extractCoordinateIndex(responseBody);

      if (coordinateIndex != null &&
          coordinateIndex >= 0 &&
          coordinateIndex < coordinates.length) {
        final pointNumber = coordinateIndex + 1;

        String pointType;

        if (coordinateIndex == 0) {
          pointType = 'starting point';
        } else if (coordinateIndex == coordinates.length - 1) {
          pointType = 'destination';
        } else {
          pointType = 'waypoint $pointNumber';
        }

        return Exception(
          'Could not calculate the route.\n\n'
          'The selected $pointType is too far '
          'from a routable road.\n\n'
          'Try selecting a nearby road, '
          'parking area, fuel station, '
          'restaurant, or another accessible '
          'location.',
        );
      }

      return Exception(
        'Could not calculate the route.\n\n'
        'One of the selected locations is not '
        'close enough to a routable road.\n\n'
        'Please select locations that are '
        'accessible by road.',
      );
    }

    if (statusCode == 406) {
      return Exception(
        'OpenRouteService rejected the response format.\n\n'
        'The route request could not be processed. '
        'Please try again.',
      );
    }

    if (statusCode == 400) {
      return Exception(
        'OpenRouteService could not process this route.\n\n'
        'Please check the selected locations '
        'and try again.',
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return Exception(
        'OpenRouteService rejected the API key.\n\n'
        'Please check your ORS_API_KEY '
        'in the .env file.',
      );
    }

    if (statusCode == 429) {
      return Exception(
        'OpenRouteService rate limit reached.\n\n'
        'Please wait a moment and try again.',
      );
    }

    if (statusCode >= 500) {
      return Exception(
        'OpenRouteService is temporarily unavailable.\n\n'
        'Please try again in a moment.',
      );
    }

    return Exception(
      'OpenRouteService Error ($statusCode)\n'
      '$responseBody',
    );
  }

  int? _extractCoordinateIndex(String responseBody) {
    final match = RegExp(
      r'coordinate\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(responseBody);

    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }
}
