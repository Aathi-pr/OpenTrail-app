import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_trail/auth/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _signOutController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isSigningOut = false;

  // Dynamic Version State
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();

    _signOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _signOutController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _signOutController, curve: Curves.easeOutCubic),
    );
  }

  /// Fetches application version and build number from native platform metadata
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appVersion = '1.0.0'; // Fallback in case platform info fails
        });
      }
    }
  }

  @override
  void dispose() {
    _signOutController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut(AuthService authService) async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    // Trigger smooth fade & scale animation
    await _signOutController.forward();

    // Perform sign out action
    await authService.signOut();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0A);
    const fg = Color(0xFFF4F4F2);
    const secondary = Color(0xFF8B8B8B);
    const border = Color(0xFF242424);
    const card = Color(0xFF111111);

    final authService = AuthService();
    final user = authService.currentUser;
    final photoUrl = authService.currentUserPhotoUrl;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _signOutController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Row(
                  children: [
                    IconButton(
                      onPressed: _isSigningOut
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: fg,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
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

                const SizedBox(height: 36),

                /// User Profile Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF1A1A1A),
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, color: fg)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? "Rider",
                              style: const TextStyle(
                                color: fg,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? "No email linked",
                              style: const TextStyle(
                                color: secondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                /// About Section
                const Text(
                  "ABOUT",
                  style: TextStyle(
                    color: secondary,
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: fg, size: 20),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Version",
                          style: TextStyle(color: fg, fontSize: 14),
                        ),
                      ),
                      Text(
                        _appVersion,
                        style: const TextStyle(
                          color: secondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                /// Animated Sign Out Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSigningOut
                        ? null
                        : () => _handleSignOut(authService),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 60,
                      decoration: BoxDecoration(
                        color: _isSigningOut ? const Color(0xFF1C0A0A) : card,
                        border: Border.all(
                          color: _isSigningOut
                              ? Colors.redAccent
                              : Colors.redAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          children: [
                            _isSigningOut
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.redAccent,
                                    ),
                                  )
                                : const Icon(
                                    Icons.logout,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                _isSigningOut ? "SIGNING OUT..." : "SIGN OUT",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  letterSpacing: 2,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            if (!_isSigningOut)
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.redAccent,
                                size: 18,
                              ),
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
      ),
    );
  }
}
