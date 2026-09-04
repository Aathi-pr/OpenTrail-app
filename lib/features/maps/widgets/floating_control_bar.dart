import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show CircularProgressIndicator, StrokeCap;
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class FloatingControlBar extends StatefulWidget {
  const FloatingControlBar({
    super.key,
    required this.isLeader,
    required this.isSatelliteMode,
    required this.isNavigating,
    required this.onSearch,
    required this.onToggleSatellite,
    required this.onNavigation,
    required this.onCenterLocation,
    required this.onAddWaypoint,
    required this.onSos,
  });


  final bool isLeader;


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
    if (widget.isLeader) {
      _handleLeaderTab(index);
    } else {
      _handleRiderTab(index);
    }
  }


  void _handleLeaderTab(int index) {
    switch (index) {
      case 0:
        widget.onSearch();
        break;

      case 1:
        widget.onToggleSatellite();
        break;

      case 2:
        widget.onNavigation();
        break;

      case 3:
        widget.onCenterLocation();
        break;

      case 4:
        widget.onAddWaypoint();
        break;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }


  void _handleRiderTab(int index) {
    switch (index) {
      case 0:
        widget.onToggleSatellite();
        break;

      case 1:
        widget.onNavigation();
        break;

      case 2:
        widget.onCenterLocation();
        break;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }


  List<GlassTab> _buildLeaderTabs() {
    return [
      const GlassTab(
        icon: Icon(CupertinoIcons.search),
        activeIcon: Icon(CupertinoIcons.search),
      ),

      GlassTab(
        icon: Icon(
          widget.isSatelliteMode ? CupertinoIcons.map_fill : CupertinoIcons.map,
        ),
        activeIcon: Icon(
          widget.isSatelliteMode ? CupertinoIcons.map_fill : CupertinoIcons.map,
        ),
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

      const GlassTab(
        icon: Icon(CupertinoIcons.map_pin_ellipse),
        activeIcon: Icon(CupertinoIcons.map_pin_ellipse),
      ),
    ];
  }


  List<GlassTab> _buildRiderTabs() {
    return [
      GlassTab(
        icon: Icon(
          widget.isSatelliteMode ? CupertinoIcons.map_fill : CupertinoIcons.map,
        ),
        activeIcon: Icon(
          widget.isSatelliteMode ? CupertinoIcons.map_fill : CupertinoIcons.map,
        ),
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
    ];
  }


  @override
  void didUpdateWidget(covariant FloatingControlBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLeader != widget.isLeader) {
      if (widget.isLeader) {
        _selectedIndex = _selectedIndex.clamp(0, 4);
      } else {
        _selectedIndex = _selectedIndex.clamp(0, 2);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final tabs = widget.isLeader ? _buildLeaderTabs() : _buildRiderTabs();

    final maxIndex = tabs.length - 1;

    final safeSelectedIndex = _selectedIndex.clamp(0, maxIndex);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 0),
      child: GlassTabBar.bottom(
        selectedIndex: safeSelectedIndex,

        onTabSelected: _handleTab,

        barBorderRadius: 40,

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
          thickness: 32,
          blur: 8,
          refractiveIndex: 1.35,
          lightIntensity: 1.0,
          chromaticAberration: 0.03,
          saturation: 1.35,
        ),

        horizontalPadding: 0,

        verticalPadding: 8,

        barHeight: 68,

        tabWidth: widget.isLeader ? 64 : 72,

        selectedIconColor: CupertinoColors.systemOrange,

        unselectedIconColor: CupertinoColors.white,

        indicatorColor: CupertinoColors.white.withValues(alpha: 0.12),

        interactionBehavior: GlassInteractionBehavior.full,

        tabs: tabs,
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

      onTapCancel: _cancelHolding,

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
                          color: CupertinoColors.systemRed.withValues(alpha:
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
                      color: CupertinoColors.systemRed.withValues(alpha: 0.25),
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
