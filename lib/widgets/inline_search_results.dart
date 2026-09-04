import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CupertinoActivityIndicator(
                    radius: 10,
                    color: Colors.white,
                  ),
                ),
              );
            }

            if (places.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "NO LOCATIONS FOUND",
                    style: TextStyle(
                      color: Color(0xFF71717A),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: places.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
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
                    icon = CupertinoIcons.placemark_fill;
                    break;
                  case 'address':
                    icon = CupertinoIcons.house_fill;
                    break;
                  case 'street':
                    icon = CupertinoIcons.waveform_path;
                    break;
                  case 'place':
                    icon = CupertinoIcons.building_2_fill;
                    break;
                  default:
                    icon = CupertinoIcons.location_fill;
                }

                return InkWell(
                  splashColor: Colors.white.withValues(alpha: 0.08),
                  highlightColor: Colors.white.withValues(alpha: 0.04),
                  onTap: () {
                    onPlaceSelected(LatLng(lat, lon), title);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: const Color(0xFFA1A1AA), size: 14),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFFAFAFA),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF71717A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.arrow_up_left,
                          color: Color(0xFF52525B),
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
