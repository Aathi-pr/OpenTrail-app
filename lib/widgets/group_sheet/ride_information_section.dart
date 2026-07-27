import 'package:flutter/material.dart';
import 'package:open_trail/models/ride_model.dart';

class RideInformationSection extends StatelessWidget {
  const RideInformationSection({
    super.key,
    required this.ride,
    required this.destination,
    // required this.distance,
    // required this.duration,
    required this.leaderName,
  });

  final RideModel ride;
  final String destination;
  final String leaderName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(1)
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Ride Information",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 20),

          _InfoRow(title: "Ride Code", value: ride.rideId),

          _InfoRow(title: "Leader", value: leaderName),

          _InfoRow(
            title: "Status",
            value: ride.isNavigating ? "Navigating" : "Waiting",
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
