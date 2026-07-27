import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LocationSearchService {
  Future<List<dynamic>> searchPlaces(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    if (query.trim().length < 2) return [];

    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];

    if (token == null || token.isEmpty) {
      debugPrint("MAPBOX_ACCESS_TOKEN not found.");
      return [];
    }

    final params = <String, String>{
      'q': query,
      'access_token': token,
      'limit': '10',
      'language': 'en',
      'types': 'poi,address,street,place',
      'auto_complete': 'true',
      'country': 'IN',
    };

    if (latitude != null && longitude != null) {
      params['proximity'] = '$longitude,$latitude';
    }

    final uri = Uri.https(
      'api.mapbox.com',
      '/search/searchbox/v1/forward',
      params,
    );

    debugPrint(uri.toString());

    try {
      final response = await http.get(uri);

      debugPrint("Status: ${response.statusCode}");
      debugPrint(response.body);

      if (response.statusCode != 200) {
        return [];
      }

      final json = jsonDecode(response.body);

      return List<dynamic>.from(json['features'] ?? []);
    } catch (e) {
      debugPrint("Search Error: $e");
      return [];
    }
  }
}
