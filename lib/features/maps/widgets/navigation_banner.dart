import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_trail/features/maps/helpers/navigation_icon_helper.dart';
import 'package:open_trail/models/navigation_step.dart';

class NavigationBanner extends StatelessWidget {
  const NavigationBanner({
    super.key,
    required this.isVisible,
    required this.step,
    required this.distanceToNextTurn,
  });

  final bool isVisible;
  final NavigationStep? step;
  final double distanceToNextTurn;

  @override
  Widget build(BuildContext context) {
    if (!isVisible || step == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GlassCard(
        useOwnLayer: true,
        quality: GlassQuality.premium,
        settings: LiquidGlassSettings(
          thickness: 15,
          blur: 2,
          refractiveIndex: 15.12,
        ),
        shape: LiquidRoundedRectangle(borderRadius: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Icon(
                navigationIconForType(step!.type),
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                step!.instruction,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            const SizedBox(width: 12),

            SizedBox(
              width: 65,
              child: Text(
                "${distanceToNextTurn.round()} m",
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
