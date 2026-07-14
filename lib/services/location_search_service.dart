import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LocationSearchService {
  Future<List<dynamic>> searchPlaces(String query) async {
    if (query.trim().length < 2) return [];

    final apiKey = dotenv.env['GEOCODE_EARTH_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("❌ GEOCODE_EARTH_API_KEY not found.");
      return [];
    }

    final uri = Uri.https('api.geocode.earth', '/v1/autocomplete', {
      'text': query,
      'api_key': apiKey,
      'size': '10',
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final json = jsonDecode(response.body);
      return json['features'] as List<dynamic>;
    } catch (e) {
      debugPrint("Search network error: $e");
      return [];
    }
  }
}
