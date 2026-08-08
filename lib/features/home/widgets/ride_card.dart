import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_trail/features/maps/map_page.dart';

class RideCard extends StatefulWidget {
  final dynamic ride;

  const RideCard({super.key, required this.ride});

  @override
  State<RideCard> createState() => RideCardState();
}

class RideCardState extends State<RideCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.ride.isNavigating ?? false;
    final destination = (widget.ride.destination as String?)?.trim();
    final destinationLabel = destination == null || destination.isEmpty
        ? "No destination set"
        : destination;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapPage(
                rideDocumentId: widget.ride.documentId,
                initialRide: widget.ride,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: GlassCard(
            shape: LiquidRoundedRectangle(borderRadius: 1),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.ride.rideId ?? "UNKNOWN ID",
                      style: const TextStyle(
                        color: Color(0xFFF4F4F2),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF1C3A27)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: active
                              ? const Color(0xFF2A5E3F)
                              : const Color(0xFF2B2B2B),
                        ),
                      ),
                      child: Text(
                        active ? "ACTIVE" : "ENDED",
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF52C47C)
                              : const Color(0xFF8B8B8B),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  destinationLabel,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Color(0xFF8B8B8B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.ride.leaderName ?? "Unknown Leader",
                      style: const TextStyle(
                        color: Color(0xFF8B8B8B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Icon(
                      Icons.people_outline,
                      size: 14,
                      color: Color(0xFF8B8B8B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${widget.ride.memberCount ?? 1} members",
                      style: const TextStyle(
                        color: Color(0xFF8B8B8B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
