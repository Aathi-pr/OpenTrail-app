import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserMarkerLayer extends StatelessWidget {
  const UserMarkerLayer({
    super.key,
    required this.currentPosition,
    required this.navigationPosition,
    required this.userName,
    required this._isLeader,
  });

  final Position? currentPosition;
  final Position? navigationPosition;
  final String userName;
  final bool _isLeader;

  @override
  Widget build(BuildContext context) {
    final position = navigationPosition ?? currentPosition;
    if (position == null) {
      return const SizedBox.shrink();
    }
    return MarkerLayer(
      markers: [
        Marker(point: LatLng(position.latitude, position.longitude),
        width: 120,
        height: 70,
        alignment: Alignment.topCenter,
         child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7
              ),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  )
                ]
              ),
              child: Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 4,),

            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _isLeader ? Colors.orangeAccent : Colors.lightBlueAccent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3
                )
              ),
            )
          ],
         )
         )
      ]
      );
  }
}
