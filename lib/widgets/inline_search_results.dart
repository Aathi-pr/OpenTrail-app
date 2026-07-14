import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../services/location_search_service.dart';

class InlineSearchResults extends StatelessWidget {
  final String searchQuery;
  final LocationSearchService searchService;
  final Function(LatLng coordinates, String locationLabel) onPlaceSelected;

  const InlineSearchResults({
    super.key,
    required this.searchQuery,
    required this.searchService,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      child: GlassCard(
        useOwnLayer: true,
        quality: GlassQuality.premium,
        shape: LiquidRoundedRectangle(borderRadius: 15),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: FutureBuilder<List<dynamic>>(
          future: searchService.searchPlaces(searchQuery),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    snapshot.hasError
                        ? snapshot.error.toString()
                        : "No locations found",
                    style: const TextStyle(color: Colors.white38),
                  ),
                ),
              );
            }

            final places = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: places.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final place = places[index];
                final properties = place['properties'] ?? {};
                final label = properties['label'] ?? 'Unknown location';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                  ),
                  title: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    properties['country'] ?? '',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  onTap: () {
                    final coordinates = place['geometry']['coordinates'];
                    final lon = (coordinates[0] as num).toDouble();
                    final lat = (coordinates[1] as num).toDouble();
                    onPlaceSelected(LatLng(lat, lon), label);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
