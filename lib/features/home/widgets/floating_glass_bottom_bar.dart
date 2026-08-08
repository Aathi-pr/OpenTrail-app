import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class FloatingGlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingGlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTabBar.bottom(
      selectedIndex: currentIndex,
      onTabSelected: onTabSelected,
      barBorderRadius: 40,
      maskingQuality: MaskingQuality.high,
      settings: const LiquidGlassSettings(
        thickness: 20,
        blur: 4,
        refractiveIndex: 1.25,
        lightIntensity: 0.6,
        chromaticAberration: 0.015,
        saturation: 1.2,
      ),
      horizontalPadding: 12,
      verticalPadding: 6,
      barHeight: 64,
      tabWidth: 136,
      selectedIconColor: const Color(0xFFF4F4F2),
      unselectedIconColor: const Color(0xFF8B8B8B),
      indicatorColor: const Color(0xFF242424).withValues(alpha: 0.85),
      interactionBehavior: GlassInteractionBehavior.full,
      tabs: [
        GlassTab(
          icon: const _NavItemLabel(
            icon: CupertinoIcons.house,
            label: "HOME",
            isSelected: false,
          ),
          activeIcon: const _NavItemLabel(
            icon: CupertinoIcons.house_fill,
            label: "HOME",
            isSelected: true,
          ),
        ),

        GlassTab(
          icon: const _NavItemLabel(
            icon: CupertinoIcons.flag,
            label: "RIDES",
            isSelected: false,
          ),
          activeIcon: const _NavItemLabel(
            icon: CupertinoIcons.flag_fill,
            label: "RIDES",
            isSelected: true,
          ),
        ),

                GlassTab(
          icon: const _NavItemLabel(
            icon: CupertinoIcons.person_3,
            label: "CLUB",
            isSelected: false,
          ),
          activeIcon: const _NavItemLabel(
            icon: CupertinoIcons.person_3_fill,
            label: "CLUB",
            isSelected: true,

          ),
        ),
      ],
    );
  }
}

class _NavItemLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavItemLabel({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFFF4F4F2)
        : const Color(0xFF8B8B8B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isSelected ? 1.0 : 0.65,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: color,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
