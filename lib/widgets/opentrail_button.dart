import 'package:flutter/material.dart';

// class OpentrailButton extends StatelessWidget {
//   final String text;
//   final VoidCallback? onPressed;

//   const OpentrailButton({super.key, required this.text, required this.onPressed});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: MediaQuery.of(context).size.width * 0.9,
//       height: 46,
//       child: OutlinedButton(
//         onPressed: onPressed,
//         style: OutlinedButton.styleFrom(
//           elevation: 0,
//           backgroundColor: Colors.white70,
//           foregroundColor: const Color(0xFFF5F5F2),
//           side: const BorderSide(color: Colors.white30, width: 1),
//           shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
//         ),
//         child: Text(
//           text,
//           style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w300, color: Colors.black),
//         ),
//       ),
//     );
//   }
// }


class OpentrailButton extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const OpentrailButton({
    required this.number,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFFF4F4F2);
    const secondary = Color(0xFF8B8B8B);
    const border = Color(0xFF242424);
    const card = Color(0xFF111111);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: card,
            border: Border.all(color: border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        number,
                        style: const TextStyle(color: secondary, fontSize: 16),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        title,
                        style: const TextStyle(
                          color: fg,
                          fontSize: 24,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: secondary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.arrow_forward_rounded, color: fg, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
