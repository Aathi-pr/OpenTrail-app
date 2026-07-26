import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_trail/auth/auth_service.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/models/rider_location_model.dart';

class GroupSheet extends StatefulWidget {
  const GroupSheet({
    super.key,
    required this.ride,
    required this.distance,
    required this.duration,
    required this.ridersStream,
    required this.currentUserName,
    required this.currentUserId,
    required this.isLeader,
    required this.isNavigating,
  });

  final RideModel ride;
  final String distance;
  final String duration;
  final Stream<List<RiderLocationModel>> ridersStream;
  final String currentUserName;
  final String currentUserId;
  final bool isNavigating;
  final bool isLeader;

  @override
  State<GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<GroupSheet> {
  final AuthService _authService = AuthService();

List<RiderLocationModel> _getNormalizedRidersList(
    List<RiderLocationModel> riders,
  ) {
    final list = List<RiderLocationModel>.from(riders);

    final hasLeader = list.any((r) => r.role.toLowerCase().trim() == "leader");

    if (!hasLeader && widget.isLeader) {
      final user = FirebaseAuth.instance.currentUser;

      list.insert(
        0,
        RiderLocationModel(
          userId: widget.currentUserId,
          displayName: widget.currentUserName.isNotEmpty
              ? widget.currentUserName
              : (user?.displayName ?? 'Leader'),
          role: "leader",
          isOnline: true,
          photoUrl: _authService.currentUserPhotoUrl ?? user?.photoURL,
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final joinLink =
        "opentrail://join-ride?rideId=${Uri.encodeComponent(widget.ride.rideId)}";

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.60,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.premium,
          shape: const LiquidRoundedRectangle(borderRadius: 32),
          settings: const LiquidGlassSettings(
            blur: 24,
            thickness: 35,
            chromaticAberration: 0.2,
          ),
          // StreamBuilder handles real-time updates automatically!
          child: StreamBuilder<List<RiderLocationModel>>(
            stream: widget.ridersStream,
            initialData: const [],
            builder: (context, snapshot) {
              final rawRiders = snapshot.data ?? [];
              final effectiveRiders = _getNormalizedRidersList(rawRiders);

              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "RIDE DETAILS",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          "ACTIVE",
                          style: TextStyle(
                            color: Colors.greenAccent.shade100,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CODE",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.ride.rideId,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              CupertinoIcons.square_on_square,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.ride.rideId),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Ride ID copied")),
                              );
                            },
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              CupertinoIcons.share,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: joinLink));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Join link copied")),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "MEMBERS",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        "${effectiveRiders.length} Total",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      effectiveRiders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CupertinoActivityIndicator(color: Colors.white70),
                      ),
                    )
                  else if (effectiveRiders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "No members connected",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ...effectiveRiders.map((rider) {
                      final isLeaderRole =
                          rider.role.toLowerCase().trim() == "leader";
                      return _WireframeMemberTile(
                        rider: rider,
                        isLeader: isLeaderRole,
                      );
                    }),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _WireframeMetricCard(
                          title: "DISTANCE",
                          value: widget.distance,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _WireframeMetricCard(
                          title: "TIME",
                          value: widget.duration,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () {
                      // Leave group logic
                    },
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Text(
                        "LEAVE GROUP",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// Subwidgets remain unchanged (_WireframeMemberTag, _WireframeMetricCard)
class _WireframeMemberTile extends StatelessWidget {
  const _WireframeMemberTile({required this.rider, required this.isLeader});

  final RiderLocationModel rider;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = rider.photoUrl != null && rider.photoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLeader
              ? Colors.amber.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Circular Google Profile Picture with Online Status Badge Overlay
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: hasPhoto
                      ? Image.network(
                          rider.photoUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CupertinoActivityIndicator(radius: 8),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),

              // Online / Offline Indicator Badge
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: rider.isOnline ? Colors.greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1E1E1E), // Background color match
                      width: 1.5,
                    ),
                    boxShadow: rider.isOnline
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Display Name & Online Status Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rider.displayName.isNotEmpty
                      ? rider.displayName
                      : "Anonymous Rider",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rider.isOnline ? "Online" : "Offline",
                  style: TextStyle(
                    color: rider.isOnline
                        ? Colors.greenAccent.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Leader Badge / Crown Icon
          if (isLeader)
            const FaIcon(FontAwesomeIcons.crown, color: Colors.amber, size: 16),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          CupertinoIcons.person_fill,
          size: 18,
          color: isLeader ? Colors.amber : Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _WireframeMetricCard extends StatelessWidget {
  const _WireframeMetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
