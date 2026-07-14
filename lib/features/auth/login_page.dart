import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:open_trail/auth/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0A);
    const fg = Color(0xFFF4F4F2);
    const secondary = Color(0xFF8B8B8B);
    const border = Color(0xFF242424);
    const card = Color(0xFF111111);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "OPEN TRAIL",
                    style: TextStyle(
                      color: fg,
                      fontSize: 18,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 44),


                  const Text(
                    "Ride\nTogether.",
                    style: TextStyle(
                      color: fg,
                      fontSize: 54,
                      height: .95,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Create shared rides,\n"
                    "navigate together,\n"
                    "and stay connected.",
                    style: TextStyle(
                      color: secondary,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),

                  const Spacer(),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final auth = AuthService();
                        await auth.signInWithGoogle();
                      },
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: card,
                          border: Border.all(color: border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            children: [
                              Image.asset("assets/g.png", width: 22),

                              const SizedBox(width: 18),

                              const Expanded(
                                child: Text(
                                  "CONTINUE WITH GOOGLE",
                                  style: TextStyle(
                                    color: fg,
                                    letterSpacing: 2,
                                    fontSize: 15,
                                  ),
                                ),
                              ),

                              const Icon(Icons.arrow_forward, color: fg),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Center(
                    child: Text(
                      "By continuing you agree to the Terms.",
                      style: TextStyle(color: secondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
