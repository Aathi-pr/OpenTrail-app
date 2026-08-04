import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_trail/features/maps/widgets/rider_marker.dart';
import 'package:open_trail/models/rider_location_model.dart';

class ConvoyMarkerLayer extends StatelessWidget {
  const ConvoyMarkerLayer({super.key, required this.riders});

  final List<RiderLocationModel> riders;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: riders.map((rider) {
        return Marker(
          point: LatLng(rider.latitude!, rider.longitude!),
          width: (rider.displayName.length * 11 + 32)
              .clamp(120, 280)
              .toDouble(),
          height: 60,
          alignment: Alignment.topCenter,
          child: RiderMarker(rider: rider),
        );
      }).toList(),
    );
  }
}
