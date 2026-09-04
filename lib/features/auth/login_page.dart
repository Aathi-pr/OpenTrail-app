import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:open_trail/features/home/home_page.dart';
import 'package:open_trail/auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Entrance Animations
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _bodyFade;
  late Animation<Offset> _bodySlide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );

    _headlineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _headlineSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _bodyFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _bodySlide = Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Ultra-smooth transition into HomePage
  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      final auth = AuthService();
      final userCredential = await auth.signInWithGoogle();

      if (userCredential != null && mounted) {
        // Phase 1: Smoothly reverse login screen animations down to black
        await _animController.reverse();

        if (!mounted) return;

        // Phase 2: Push HomePage with a clean fade-in route
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            opaque: true,
            barrierColor: const Color(0xFF0A0A0A),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final fadeIn = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInCubic,
                  );

                  return FadeTransition(opacity: fadeIn, child: child);
                },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // If login failed, reverse the animation back to normal display
        _animController.forward();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

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
          /// Background Ambient Glow
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: const Text(
                        "OPEN TRAIL",
                        style: TextStyle(
                          color: fg,
                          fontSize: 18,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),

                  /// Headline
                  FadeTransition(
                    opacity: _headlineFade,
                    child: SlideTransition(
                      position: _headlineSlide,
                      child: const Text(
                        "Ride\nTogether.",
                        style: TextStyle(
                          color: fg,
                          fontSize: 54,
                          height: .95,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Body Subtitle
                  FadeTransition(
                    opacity: _bodyFade,
                    child: SlideTransition(
                      position: _bodySlide,
                      child: const Text(
                        "Create shared rides,\n"
                        "navigate together,\n"
                        "and stay connected.",
                        style: TextStyle(
                          color: secondary,
                          fontSize: 18,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  /// Sign In Button & Legal Notice
                  FadeTransition(
                    opacity: _buttonFade,
                    child: SlideTransition(
                      position: _buttonSlide,
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isSigningIn ? null : _handleGoogleSignIn,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 70,
                                decoration: BoxDecoration(
                                  color: _isSigningIn
                                      ? const Color(0xFF1A1A1A)
                                      : card,
                                  border: Border.all(
                                    color: _isSigningIn
                                        ? const Color(0xFF444444)
                                        : border,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                  ),
                                  child: Row(
                                    children: [
                                      if (_isSigningIn)
                                        const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: fg,
                                          ),
                                        )
                                      else
                                        Image.asset(
                                          "assets/g.png",
                                          width: 22,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.g_mobiledata,
                                                    color: fg,
                                                    size: 28,
                                                  ),
                                        ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Text(
                                          _isSigningIn
                                              ? "CONNECTING..."
                                              : "CONTINUE WITH GOOGLE",
                                          style: const TextStyle(
                                            color: fg,
                                            letterSpacing: 2,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (!_isSigningIn)
                                        const Icon(
                                          Icons.arrow_forward,
                                          color: fg,
                                        ),
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
            ),
          ),
        ],
      ),
    );
  }
}
