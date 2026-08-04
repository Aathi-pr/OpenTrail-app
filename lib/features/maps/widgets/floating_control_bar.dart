import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show CircularProgressIndicator, StrokeCap;
import 'package:flutter/services.dart';
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
          icon: _SosHoldButton(
            onConfirmed: widget.onSos,
            holdDuration: const Duration(seconds: 2),
          ),
          label: 'SOS',
          onTap: () {},
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

class _SosHoldButton extends StatefulWidget {
  const _SosHoldButton({
    required this.onConfirmed,
    this.holdDuration = const Duration(seconds: 2),
  });

  final VoidCallback onConfirmed;
  final Duration holdDuration;

  @override
  State<_SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<_SosHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lastHapticStep = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );

    _controller.addListener(_handleHapticsDuringHold);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
        _controller.reset();
        _lastHapticStep = 0;
      }
    });
  }

  void _handleHapticsDuringHold() {
    final step = (_controller.value * 5).floor();
    if (step > _lastHapticStep && step < 5) {
      HapticFeedback.mediumImpact();
      _lastHapticStep = step;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleHapticsDuringHold);
    _controller.dispose();
    super.dispose();
  }

  void _startHolding() {
    _lastHapticStep = 0;
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _cancelHolding() {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _cancelHolding(),
      onTapCancel: () => _cancelHolding(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          return SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (progress > 0)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemRed.withOpacity(
                            0.5 * progress,
                          ),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                if (progress > 0)
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 3.5,
                      color: CupertinoColors.systemRed.withOpacity(0.25),
                    ),
                  ),

                if (progress > 0)
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3.5,
                      strokeCap: StrokeCap.round,
                      color: CupertinoColors.systemRed,
                    ),
                  ),

                Transform.scale(
                  scale: 1.0 + (progress * 0.15),
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Color.lerp(
                      CupertinoColors.systemRed,
                      const Color(0xFFFF4D4D),
                      progress,
                    ),
                    size: 24,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
