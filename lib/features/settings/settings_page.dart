import 'package:flutter/material.dart';
import 'package:open_trail/auth/auth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0A);
    const fg = Color(0xFFF4F4F2);
    const secondary = Color(0xFF8B8B8B);
    const border = Color(0xFF242424);
    const card = Color(0xFF111111);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: fg),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "SETTINGS",
                    style: TextStyle(
                      color: fg,
                      fontSize: 18,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Spacer(),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final auth = AuthService();

                    await auth.signOut();

                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: card,
                      border: Border.all(color: border),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: fg),
                          SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              "SIGN OUT",
                              style: TextStyle(
                                color: fg,
                                letterSpacing: 2,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward, color: fg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
