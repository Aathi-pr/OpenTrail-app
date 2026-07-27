import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class BottomToolbar extends StatelessWidget {
  const BottomToolbar({
    super.key,
    required this.isSatelliteMode,
    required this.isLeader,
    required this.isNavigating,
    required this.onToggleSatellite,
    required this.onNavigationPressed,
    required this.onCenterLocation,
  });

  final bool isSatelliteMode;
  final bool isLeader;
  final bool isNavigating;

  final VoidCallback onToggleSatellite;
  final VoidCallback onNavigationPressed;
  final VoidCallback onCenterLocation;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useOwnLayer: true,
      quality: GlassQuality.premium,
      shape: LiquidRoundedRectangle(borderRadius: 32),
      settings: const LiquidGlassSettings(
        thickness: 15,
        blur: 2,
        refractiveIndex: 15.12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarButton(
            icon: isSatelliteMode ? Icons.layers : Icons.layers_outlined,
            onTap: onToggleSatellite,
          ),

          if (isLeader) ...[
            const SizedBox(width: 10),

            Expanded(
              child: GlassButton(
                useOwnLayer: true,
                quality: GlassQuality.standard,
                shape: LiquidRoundedRectangle(borderRadius: 24),
                icon: Icon(
                  isNavigating
                      ? CupertinoIcons.stop_fill
                      : CupertinoIcons.location_north_fill,
                  color: Colors.white,
                ),
                label:
                  isNavigating ? "Stop Ride" : "Start Ride",
                  onTap: onNavigationPressed,
                ),

              ),
          ],

          const SizedBox(width: 10),

          _ToolbarButton(icon: Icons.gps_fixed, onTap: onCenterLocation),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      icon: Icon(icon, color: Colors.white),
      onPressed: onTap,
    );
  }
}
