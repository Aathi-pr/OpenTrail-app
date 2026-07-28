import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/models/rider_location_model.dart';
import 'package:open_trail/services/navigation_service.dart';
import 'package:open_trail/widgets/group_sheet/group_sheet.dart';

class RideInfoCard extends StatelessWidget {
  const RideInfoCard({
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
  });

  final RideModel? ride;
  final NavigationService navigationService;

  final String distance;
  final String duration;

  final List<RiderLocationModel> riders;
  final String currentUserName;
  final String currentUserId;
  final bool isLeader;
  final bool isNavigating;

  @override
  Widget build(BuildContext context) {
    if (ride == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      width: MediaQuery.of(context).size.width * 0.94,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: LiquidRoundedRectangle(borderRadius: 50),
      quality: GlassQuality.premium,
      useOwnLayer: true,
      settings: LiquidGlassSettings(
        thickness: 15,
        refractiveIndex: 15.12,
        blur: 2,
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final currentRide = ride!;

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.only(right: 16, top: 4, bottom: 4),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),

            GestureDetector(
              onTap: () async {
                await HapticFeedback.heavyImpact();

                if (!context.mounted) return;

                showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) {
                    return GroupSheet(
                      ride: currentRide,
                      distance: distance,
                      duration: duration,

                      navigationService: navigationService,

                      riders: riders,
                      currentUserName: currentUserName,
                      currentUserId: currentUserId,
                      isLeader: isLeader,
                      isNavigating: isNavigating,
                    );
                  },
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.people_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${currentRide.memberCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        GestureDetector(
          onTap: () async {
            await HapticFeedback.lightImpact();

            if (!context.mounted) return;

            await Clipboard.setData(ClipboardData(text: currentRide.rideId));

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ride ID copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TAP TO COPY',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentRide.rideId,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
