import 'package:flutter/material.dart';

import 'package:open_trail/auth/auth_service.dart';
import 'package:open_trail/features/settings/settings_page.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "OPEN TRAIL",
            style: TextStyle(
              color: Color(0xFFF4F4F2),
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 6,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          },
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A1A1A),
            backgroundImage: authService.currentUserPhotoUrl != null
                ? NetworkImage(authService.currentUserPhotoUrl!)
                : null,
            child: authService.currentUserPhotoUrl == null
                ? const Icon(
                    Icons.person_outline,
                    color: Color(0xFFF4F4F2),
                    size: 18,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
