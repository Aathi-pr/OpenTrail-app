import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_trail/auth/auth_service.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/models/rider_location_model.dart';
import 'package:open_trail/models/waypoint_model.dart';
import 'package:open_trail/services/navigation_service.dart';
import 'package:open_trail/widgets/group_sheet/ride_progress_card.dart';
import 'package:open_trail/widgets/group_sheet/ride_summary_grid.dart';

class GroupSheet extends StatefulWidget {
  const GroupSheet({
    super.key,
    required this.ride,
    required this.distance,
    required this.duration,
    required this.navigationService,
    required this.riders,
    required this.currentUserName,
    required this.currentUserId,
    required this.isLeader,
    required this.isNavigating,
    this.onWaypointToggle,
  });

  final RideModel ride;
  final NavigationService navigationService;
  final String distance;
  final String duration;

  final List<RiderLocationModel> riders;
  final String currentUserName;
  final String currentUserId;
  final bool isNavigating;
  final bool isLeader;

  /// Optional callback to mark waypoints completed/uncompleted directly from sheet
  final Function(WaypointModel waypoint)? onWaypointToggle;

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

    final waypoints = widget.ride.waypoints ?? [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.60,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(color: Colors.black),
          child: Builder(
            builder: (context) {
              final effectiveRiders = _getNormalizedRidersList(widget.riders);

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
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(1),
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
                              CupertinoIcons.qrcode,
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
                              CupertinoIcons.square_on_square,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: joinLink));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Join link copied"),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    "SUMMARY",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  AnimatedBuilder(
                    animation: widget.navigationService,
                    builder: (context, child) {
                      return RideSummaryGrid(
                        distance: widget.distance,
                        duration: widget.duration,
                        averageSpeed:
                            "${widget.navigationService.currentSpeed.toStringAsFixed(1)} km/h",
                        onlineRiders: widget.riders
                            .where((r) => r.isOnline)
                            .length,
                        totalRiders: widget.riders.length,
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 1,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "PROGRESS",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  AnimatedBuilder(
                    animation: widget.navigationService,
                    builder: (context, child) {
                      return RideProgressCard(
                        progress: widget.navigationService.progress,
                        completedDistance:
                            widget.navigationService.completedDistance,
                        totalDistance: widget.navigationService.totalDistance,
                        remainingDistance:
                            widget.navigationService.remainingDistance,
                        remainingDuration:
                            widget.navigationService.remainingDuration,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 1,
                  ),

                  const SizedBox(height: 12),

                  // ================= WAYPOINTS SECTION =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "WAYPOINTS",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        "${waypoints.length} Stops",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (waypoints.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "No waypoints added yet",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ...waypoints.map((waypoint) {
                      return _WireframeWaypointTile(
                        waypoint: waypoint,
                        onTap: widget.onWaypointToggle != null
                            ? () => widget.onWaypointToggle!(waypoint)
                            : null,
                      );
                    }),

                  const SizedBox(height: 24),

                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 1,
                  ),

                  const SizedBox(height: 12),

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

                  if (effectiveRiders.isEmpty)
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

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      // Leave group logic
                    },
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(1),
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

class _WireframeWaypointTile extends StatelessWidget {
  const _WireframeWaypointTile({required this.waypoint, this.onTap});

  final WaypointModel waypoint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleText = waypoint.title.isNotEmpty
        ? waypoint.title
        : (waypoint.locationName.isNotEmpty
              ? waypoint.locationName
              : waypoint.categoryLabel);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(1),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(1),
          border: Border.all(
            color: waypoint.completed
                ? Colors.greenAccent.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: waypoint.categoryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: waypoint.categoryColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Icon(
                waypoint.categoryIcon,
                size: 18,
                color: waypoint.categoryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titleText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: waypoint.completed
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: waypoint.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        waypoint.categoryLabel.toUpperCase(),
                        style: TextStyle(
                          color: waypoint.categoryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (waypoint.stopMinutes > 0) ...[
                        Text(
                          " • ",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          "${waypoint.stopMinutes} MIN STOP",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              waypoint.completed
                  ? CupertinoIcons.checkmark_alt_circle_fill
                  : CupertinoIcons.circle,
              color: waypoint.completed
                  ? Colors.greenAccent
                  : Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(1),
        border: Border.all(
          color: isLeader
              ? Colors.amber.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
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
                      color: const Color(0xFF1E1E1E),
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
