import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:open_trail/auth/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: RotatedBox(
              quarterTurns: 1,
              child: Image.asset("assets/background.png", fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                children: [
                  AppBar(
                    title: Text(
                      "O P E N   T R A I L",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  SizedBox(height: 50),
                  Text(
                    "Sign in to create ride sessions,\njoin your group, and ride together.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF), // ~70% white opacity
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.63),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    child: InkWell(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      onTap: () async {
                        final auth = AuthService();
                           await auth.signInWithGoogle();
                      },
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width * 0.85,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        // color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset("assets/g.png"),
                            ),
                            Text("Sign In with Google"),
                          ],
                        ),
                      ),
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
