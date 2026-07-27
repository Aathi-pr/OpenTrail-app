import 'package:flutter/material.dart';
import 'package:open_trail/models/rider_location_model.dart';

class RiderMarker extends StatelessWidget {
  const RiderMarker({super.key, required this.rider});

  final RiderLocationModel rider;

  // ignore: unused_element
  String get _initials {
    final trimmed = rider.displayName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Color get _color {
    if (!rider.isOnline) {
      return Colors.grey;
    }

    return rider.role == 'leader'
        ? Colors.orangeAccent
        : Colors.lightBlueAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(50),
            border: BoxBorder.all(color: Colors.white30),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rider.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              if (!rider.isOnline) ...[
                const SizedBox(width: 6),
                const Icon(Icons.cloud_off, color: Colors.redAccent, size: 14),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: .45),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
