import 'package:flutter/material.dart';

Future<String?> showJoinRideDialog(BuildContext context) async {
  final controller = TextEditingController();

  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Join",
    barrierColor: Colors.black.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "JOIN GROUP",
                        style: TextStyle(
                          color: Color(0xFFF4F4F2),
                          fontSize: 16,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFFF4F4F2),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Container(
                  width: 48,
                  height: 1,
                  color: const Color(0xFFF4F4F2),
                ),

                const SizedBox(height: 32),

                const Text(
                  "Enter your\ninvitation code.",
                  style: TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 40,
                    height: 1.05,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 56),

                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 28,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w300,
                  ),
                  decoration: const InputDecoration(
                    hintText: "OT-XXXXXX",
                    hintStyle: TextStyle(
                      color: Colors.white24,
                      letterSpacing: 6,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF242424),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFF4F4F2),
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    Navigator.pop(context, value.trim());
                  },
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        controller.text.trim(),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF4F4F2),
                      side: const BorderSide(
                        color: Color(0xFF242424),
                      ),
                      backgroundColor: const Color(0xFF111111),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      "JOIN GROUP",
                      style: TextStyle(
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: child,
      );
    },
  );
}
