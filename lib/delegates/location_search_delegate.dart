import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LocationSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  Future<List<dynamic>> searchPlaces(String query) async {
    if (query.trim().length < 2) return [];

    final apiKey = dotenv.env['GEOCODE_EARTH_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("GEOCODE_EARTH_API_KEY not found.");
    }

    final uri = Uri.https('api.geocode.earth', '/v1/autocomplete', {
      'text': query,
      'api_key': apiKey,
      'size': '10',
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Search failed (${response.statusCode})");
    }

    final json = jsonDecode(response.body);

    return json['features'] as List<dynamic>;
  }

  @override
  String get searchFieldLabel => "Search Destination";

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      useMaterial3: true,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x00000000),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),

      dividerColor: Colors.white10,

      iconTheme: const IconThemeData(color: Colors.white),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: Colors.white24,
        selectionHandleColor: Colors.white,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          splashRadius: 20,
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            query = "";
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      splashRadius: 20,
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  Widget _buildSearchResults() {
    if (query.trim().length < 2) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            "Start typing to search",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: FutureBuilder<List<dynamic>>(
        future: searchPlaces(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final places = snapshot.data ?? [];

          if (places.isEmpty) {
            return const Center(
              child: Text(
                "No locations found",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: places.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final place = places[index];

              return ListTile(
                tileColor: Colors.black,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                ),
                title: Text(
                  place['properties']['label'] ?? 'Unknown location',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    place['properties']['country'] ?? '',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                onTap: () => close(context, place),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }
}
