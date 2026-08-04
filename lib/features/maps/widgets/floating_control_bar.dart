import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class FloatingControlBar extends StatefulWidget {
  const FloatingControlBar({
    super.key,
    required this.isSatelliteMode,
    required this.isNavigating,
    required this.onSearch,
    required this.onToggleSatellite,
    required this.onNavigation,
    required this.onCenterLocation,
    required this.onAddWaypoint,
    required this.onSos,
  });

  final bool isSatelliteMode;
  final bool isNavigating;

  final VoidCallback onSearch;
  final VoidCallback onToggleSatellite;
  final VoidCallback onNavigation;
  final VoidCallback onCenterLocation;
  final VoidCallback onAddWaypoint;
  final VoidCallback onSos;

  @override
  State<FloatingControlBar> createState() => _FloatingControlBarState();
}

class _FloatingControlBarState extends State<FloatingControlBar> {
  int _selectedIndex = 0;

  void _handleTab(int index) {
    switch (index) {
      case 0:
        widget.onSearch();
        break;

      case 1:
        widget.onToggleSatellite();
        break;

      case 2:
        widget.onAddWaypoint();
        break;

      case 3:
        widget.onNavigation();
        break;

      case 4:
        widget.onCenterLocation();
        break;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 0),
      child: GlassTabBar.bottom(
        selectedIndex: _selectedIndex,
        onTabSelected: _handleTab,
        barBorderRadius: 50,
        extraButton: GlassTabBarExtraButton(
          icon: const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: CupertinoColors.systemRed,
          ),
          label: 'SOS',
          onTap: widget.onSos,
        ),
        maskingQuality: MaskingQuality.high,
        settings: const LiquidGlassSettings(
          thickness: 20,
          blur: 3,
          refractiveIndex: 1.2,
          lightIntensity: .5,
          chromaticAberration: .01,
          saturation: 1.2,
        ),
        horizontalPadding: 0,
        verticalPadding: 8,
        barHeight: 68,
        tabWidth: 72,
        selectedIconColor: CupertinoColors.systemOrange,
        unselectedIconColor: CupertinoColors.white,
        indicatorColor: CupertinoColors.white.withOpacity(.12),
        interactionBehavior: GlassInteractionBehavior.full,
        tabs: [
          const GlassTab(
            icon: Icon(CupertinoIcons.search),
            activeIcon: Icon(CupertinoIcons.search),
          ),

          GlassTab(
            icon: Icon(
              widget.isSatelliteMode
                  ? CupertinoIcons.map_fill
                  : CupertinoIcons.map,
            ),
            activeIcon: Icon(
              widget.isSatelliteMode
                  ? CupertinoIcons.map_fill
                  : CupertinoIcons.map,
            ),
          ),

          const GlassTab(
            icon: Icon(CupertinoIcons.map_pin_ellipse),
            activeIcon: Icon(CupertinoIcons.map_pin_ellipse),
          ),

          GlassTab(
            icon: Icon(
              widget.isNavigating
                  ? CupertinoIcons.stop_fill
                  : CupertinoIcons.play_fill,
            ),
            activeIcon: Icon(
              widget.isNavigating
                  ? CupertinoIcons.stop_fill
                  : CupertinoIcons.play_fill,
            ),
          ),

          const GlassTab(
            icon: Icon(CupertinoIcons.location_fill),
            activeIcon: Icon(CupertinoIcons.location_fill),
          ),
        ],
      ),
    );
  }
}
