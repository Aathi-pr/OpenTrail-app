import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class WaypointSearchBar extends StatelessWidget {
  const WaypointSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GlassTextField.search(
      controller: controller,
      height: 50,
      shape: LiquidRoundedRectangle(borderRadius: 50),
      useOwnLayer: true,
      quality: GlassQuality.premium,
      settings: const LiquidGlassSettings(thickness: 20),
      placeholder: 'Search waypoints...',
      placeholderStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: onChanged,
      prefixIcon: const Icon(
        CupertinoIcons.search,
        size: 18,
        color: Colors.white70,
      ),
      // Automatically show clear icon when query is present
      suffixIcon: searchQuery.isNotEmpty
          ? const Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 18,
              color: Colors.white54,
            )
          : null,
      onSuffixTap: () {
        controller.clear();
        onChanged('');
        onClose();
      },
    );
    // return Container(
    //   height: 56,
    //   decoration: BoxDecoration(
    //     color: const Color(0xFF151515),
    //     borderRadius: BorderRadius.circular(18),
    //     border: Border.all(
    //       color: Colors.white10,
    //     ),
    //   ),
    //   child: Row(
    //     children: [
    //       const SizedBox(width: 14),

    //       const Icon(
    //         CupertinoIcons.map_pin_ellipse,
    //         color: Colors.orange,
    //         size: 20,
    //       ),

    //       const SizedBox(width: 10),

    //       Expanded(
    //         child: GlassTextField(
    //           controller: controller,
    //           autofocus: true,
    //           onChanged: onChanged,
    //           // style: const TextStyle(
    //           //   color: Colors.white,
    //           // ),
    //           // decoration: const InputDecoration(
    //           //   hintText: "Search waypoint...",
    //           //   hintStyle: TextStyle(
    //           //     color: Colors.white38,
    //           //   ),
    //           //   border: InputBorder.none,
    //           // ),
    //         ),
    //       ),

    //       IconButton(
    //         onPressed: onClose,
    //         icon: const Icon(
    //           CupertinoIcons.xmark_circle_fill,
    //           color: Colors.white54,
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}
