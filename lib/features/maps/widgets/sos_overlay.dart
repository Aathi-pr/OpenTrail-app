import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:open_trail/models/rider_location_model.dart';

class SOSOverlay extends StatefulWidget {
  const SOSOverlay({
    super.key,
    required this.active,
    required this.riders,
    this.duration = const Duration(milliseconds: 700),
    this.bottomPadding = 100.0,
  });

  final bool active;
  final Duration duration;
  final List<RiderLocationModel> riders;
  final double bottomPadding;

  @override
  State<SOSOverlay> createState() => _SOSOverlayState();
}

class _SOSOverlayState extends State<SOSOverlay> with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _revealAnimation;
  late final Ticker _ticker;

  final ValueNotifier<double> _timeNotifier = ValueNotifier<double>(0.0);

  ui.FragmentShader? _shader;
  bool _isVisible = false;
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();

    _revealController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _ticker = createTicker((elapsed) {
      _timeNotifier.value = elapsed.inMicroseconds / 1000000.0;
    });

    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _ticker.stop();
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      }
    });

    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'assets/shaders/sos.frag',
    );

    _shader = program.fragmentShader();

    if (!mounted) return;

    if (widget.active) {
      _startReveal();
    }
  }

  void _startReveal() {
    setState(() {
      _isVisible = true;
      _isHidden = false;
    });
    if (!_ticker.isActive) {
      _ticker.start();
    }
    _revealController.forward();
  }

  void _stopReveal() {
    _revealController.reverse();
  }

  @override
  void didUpdateWidget(covariant SOSOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.active != oldWidget.active) {
      if (_shader != null) {
        if (widget.active) {
          _startReveal();
        } else {
          _stopReveal();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _shader == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. FULL-SCREEN SHADER OVERLAY
        AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          opacity: _isHidden ? 0.0 : 1.0,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_revealAnimation, _timeNotifier]),
              builder: (_, _) {
                return CustomPaint(
                  painter: _SOSPainter(
                    shader: _shader!,
                    time: _timeNotifier.value,
                    progress: _revealAnimation.value,
                  ),
                );
              },
            ),
          ),
        ),

        // 2. EXPANDED PANEL OR MINIMAL BOTTOM BAR
        SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: _isHidden ? widget.bottomPadding : 16.0,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: _isHidden ? Alignment.bottomCenter : Alignment.center,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                offset: widget.active ? Offset.zero : const Offset(0, 0.15),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: widget.active ? 1.0 : 0.0,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.92,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _isHidden
                          ? _MinimalSOSBottomBar(
                              key: const ValueKey("minimal_bottom_bar"),
                              onExpand: () {
                                setState(() {
                                  _isHidden = false;
                                });
                              },
                            )
                          : _ExpandedSOSPanel(
                              key: const ValueKey("expanded_panel"),
                              riders: widget.riders,
                              onHide: () {
                                setState(() {
                                  _isHidden = true;
                                });
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _revealController.dispose();
    _timeNotifier.dispose();
    super.dispose();
  }
}

class _SOSPainter extends CustomPainter {
  const _SOSPainter({
    required this.shader,
    required this.time,
    required this.progress,
  });

  final ui.FragmentShader shader;
  final double time;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, progress);

    final paint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.srcOver;

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _SOSPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.progress != progress;
  }
}

class _ExpandedSOSPanel extends StatelessWidget {
  const _ExpandedSOSPanel({
    super.key,
    required this.riders,
    required this.onHide,
  });

  final List<RiderLocationModel> riders;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 44.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: riders
                .map(
                  (rider) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _SOSStatusCard(rider: rider),
                  ),
                )
                .toList(),
          ),
        ),
        // Single collapse button on the top right for the entire panel
        Positioned(
          top: 4,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHide,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xEE1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 22,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SOSStatusCard extends StatelessWidget {
  const _SOSStatusCard({required this.rider});

  final RiderLocationModel? rider;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser =
        rider?.userId == FirebaseAuth.instance.currentUser?.uid;

    final displayName = (rider?.displayName.isNotEmpty == true)
        ? rider!.displayName
        : "A Rider";

    final String initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : "R";

    final statusText = isCurrentUser ? "SIGNAL ACTIVE" : "NEEDS ASSISTANCE";

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: rider?.photoUrl != null
                      ? NetworkImage(rider!.photoUrl!)
                      : null,
                  child: rider?.photoUrl == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: Colors.redAccent.shade100,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimalSOSBottomBar extends StatelessWidget {
  const _MinimalSOSBottomBar({super.key, required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpand,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xEE120505),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulsingRedDot(),
                const SizedBox(width: 10),
                const Text(
                  "SOS ACTIVATED",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingRedDot extends StatefulWidget {
  const _PulsingRedDot();

  @override
  State<_PulsingRedDot> createState() => _PulsingRedDotState();
}

class _PulsingRedDotState extends State<_PulsingRedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.8),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
