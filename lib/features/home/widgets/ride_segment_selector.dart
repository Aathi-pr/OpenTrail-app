import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

class RideSegmentSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;

  const RideSegmentSelector({
    super.key,
    required this.selectedIndex,
    required this.onSegmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF141414).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF242424), width: 1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth = constraints.maxWidth / 2;

              return Stack(
                children: [
                  // Smooth Glass Capsule Background
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * segmentWidth,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF383838),
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  // Segment Titles
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSegmentSelected(0),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: selectedIndex == 0
                                    ? const Color(0xFFF4F4F2)
                                    : const Color(0xFF8B8B8B),
                                fontSize: 12,
                                fontWeight: selectedIndex == 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                letterSpacing: 2,
                              ),
                              child: const Text("CREATED"),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSegmentSelected(1),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: selectedIndex == 1
                                    ? const Color(0xFFF4F4F2)
                                    : const Color(0xFF8B8B8B),
                                fontSize: 12,
                                fontWeight: selectedIndex == 1
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                letterSpacing: 2,
                              ),
                              child: const Text("JOINED"),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
