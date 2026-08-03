import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class WaypointSearchResults extends StatelessWidget {
  const WaypointSearchResults({
    super.key,
    required this.places,
    required this.isLoading,
    required this.onPlaceSelected,
  });

  final List<dynamic> places;
  final bool isLoading;
  final void Function(LatLng location, String locationLabel) onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(radius: 10, color: Colors.white),
        ),
      );
    }

    if (places.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: const Center(
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

    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B), // Deep solid OLED slate
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: places.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withOpacity(0.06),
          ),
          itemBuilder: (context, index) {
            final place = places[index] as Map<String, dynamic>;
            final properties = place['properties'] as Map<String, dynamic>;
            final coordinates =
                properties['coordinates'] as Map<String, dynamic>;

            final name =
                (properties['name'] ??
                        properties['full_address'] ??
                        'Unknown Location')
                    .toString();
            final address =
                (properties['full_address'] ??
                        properties['place_formatted'] ??
                        '')
                    .toString();
            final lat = (coordinates['latitude'] as num).toDouble();
            final lon = (coordinates['longitude'] as num).toDouble();

            return InkWell(
              splashColor: Colors.white.withOpacity(0.08),
              highlightColor: Colors.white.withOpacity(0.04),
              onTap: () => onPlaceSelected(LatLng(lat, lon), name),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Precise Pin Icon
                    const Icon(
                      CupertinoIcons.location_fill,
                      color: Color(0xFFA1A1AA),
                      size: 14,
                    ),
                    const SizedBox(width: 12),

                    // Label Stack
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFAFAFA),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              address,
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

                    // Clean Arrow
                    const Icon(
                      CupertinoIcons.arrow_up_right,
                      color: Color(0xFF52525B),
                      size: 12,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
