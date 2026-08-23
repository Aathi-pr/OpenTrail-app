import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:open_trail/features/maps/map_page.dart';
import 'package:open_trail/models/community_ride.dart';
import 'package:open_trail/services/community_ride_service.dart';

class CommunityRideCard extends StatefulWidget {
  const CommunityRideCard({super.key, required this.ride});

  final CommunityRide ride;

  @override
  State<CommunityRideCard> createState() => _CommunityRideCardState();
}

class _CommunityRideCardState extends State<CommunityRideCard> {
  final CommunityRideService _communityRideService = CommunityRideService();

  bool _isPressed = false;
  bool _isLoading = false;

  Future<void> _handleAction() async {
    if (_isLoading) return;

    final ride = widget.ride;
    final currentUserId = _communityRideService.currentUserId;

    if (currentUserId == null) {
      _showMessage('You must be signed in.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (ride.status == 'active') {
        final operationalRideId = ride.operationalRideDocumentId;

        if (operationalRideId == null || operationalRideId.isEmpty) {
          throw Exception('Unable to find the active expedition.');
        }

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapPage(rideDocumentId: operationalRideId),
          ),
        );

        return;
      }

      if (ride.leaderUid == currentUserId) {
        final operationalRideId = await _communityRideService.startRide(
          ride.documentId,
        );

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapPage(rideDocumentId: operationalRideId),
          ),
        );

        return;
      }

      if (ride.hasMember(currentUserId)) {
        _showMessage('You are already part of this expedition.');
        return;
      }

      if (ride.hasJoinRequest(currentUserId)) {
        _showMessage('Join request already sent.');
        return;
      }

      await _communityRideService.requestToJoin(ride.documentId);

      _showMessage('Join request sent.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF161616),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final currentUserId = _communityRideService.currentUserId;

    final isLeader = currentUserId == ride.leaderUid;
    final isMember = currentUserId != null && ride.hasMember(currentUserId);
    final hasRequested =
        currentUserId != null && ride.hasJoinRequest(currentUserId);

    final isActive = ride.status == 'active';

    String actionLabel;

    if (_isLoading) {
      actionLabel = 'LOADING';
    } else if (isActive) {
      actionLabel = 'REJOIN';
    } else if (isLeader) {
      actionLabel = 'START EXPEDITION';
    } else if (isMember) {
      actionLabel = 'JOINED';
    } else if (hasRequested) {
      actionLabel = 'REQUESTED';
    } else {
      actionLabel = 'REQUEST TO JOIN';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        onTap: _handleAction,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: GlassCard(
            shape: LiquidRoundedRectangle(borderRadius: 1),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'EXPEDITION',
                      style: const TextStyle(
                        color: Color(0xFFF4F4F2),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1C3A27)
                            : const Color(0xFF1A1A1A),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF2A5E3F)
                              : const Color(0xFF2B2B2B),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'PLANNED',
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFF52C47C)
                              : const Color(0xFF8B8B8B),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  ride.title,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ride.destination,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8B8B8B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Color(0xFF8B8B8B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ride.leaderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.people_outline,
                      size: 14,
                      color: Color(0xFF8B8B8B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ride.members.length}/${ride.maxMembers}',
                      style: const TextStyle(
                        color: Color(0xFF8B8B8B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive || isLeader
                        ? const Color(0xFFF4F4F2)
                        : const Color(0xFF161616),
                    border: Border.all(color: const Color(0xFF2B2B2B)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: isActive || isLeader
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFFB0B0B0),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(
                    minHeight: 1,
                    backgroundColor: Color(0xFF222222),
                    color: Color(0xFFF4F4F2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
