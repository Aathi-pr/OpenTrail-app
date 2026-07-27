import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class InlineSearchResults extends StatelessWidget {
  final List<dynamic> places;
  final bool isLoading;
  final Function(LatLng coordinates, String locationLabel) onPlaceSelected;

  const InlineSearchResults({
    super.key,
    required this.places,
    required this.isLoading,
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
        settings: LiquidGlassSettings(
          thickness: 15,
          refractiveIndex: 15.12,
          blur: 5,
        ),
        quality: GlassQuality.premium,
        shape: LiquidRoundedRectangle(borderRadius: 15),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Builder(
          builder: (context) {
            if (isLoading) {
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

            if (places.isEmpty) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    "No locations found",
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: places.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final place = places[index] as Map<String, dynamic>;

                final properties = place['properties'] as Map<String, dynamic>;

                final coordinates =
                    properties['coordinates'] as Map<String, dynamic>;

                final title =
                    (properties['name'] ??
                            properties['full_address'] ??
                            'Unknown Location')
                        .toString();

                final subtitle =
                    (properties['full_address'] ??
                            properties['place_formatted'] ??
                            '')
                        .toString();

                final lat = (coordinates['latitude'] as num).toDouble();

                final lon = (coordinates['longitude'] as num).toDouble();

                final featureType = (properties['feature_type'] ?? '')
                    .toString();

                IconData icon;

                switch (featureType) {
                  case 'poi':
                    icon = Icons.place_outlined;
                    break;

                  case 'address':
                    icon = Icons.home_outlined;
                    break;

                  case 'street':
                    icon = Icons.route_outlined;
                    break;

                  case 'place':
                    icon = Icons.location_city_outlined;
                    break;

                  default:
                    icon = Icons.location_on_outlined;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(icon, color: Colors.white70),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  onTap: () {
                    onPlaceSelected(LatLng(lat, lon), title);
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
