import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:open_trail/auth/auth_service.dart';
import 'package:open_trail/features/maps/map_page.dart';
import 'package:open_trail/features/settings/settings_page.dart';
import 'package:open_trail/features/weather/dynamic_weather_background.dart';
import 'package:open_trail/features/weather/weather_condition.dart';
import 'package:open_trail/features/weather/weather_service.dart';
import 'package:open_trail/services/ride_service.dart';
import 'package:open_trail/widgets/opentrail_button.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Preserve screen state across tab switching
          IndexedStack(
            index: _currentIndex,
            children: const [HomePage(), MyRidesPage()],
          ),

          // Floating Glass Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: SizedBox(
                width: 290, // adjust to taste
                child: Material(
                  color: Colors.transparent,
                  child: FloatingGlassBottomBar(
                    currentIndex: _currentIndex,
                    onTabSelected: (index) {
                      setState(() => _currentIndex = index);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingGlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingGlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTabBar.bottom(
      selectedIndex: currentIndex,
      onTabSelected: onTabSelected,
      barBorderRadius: 40,
      maskingQuality: MaskingQuality.high,
      settings: const LiquidGlassSettings(
        thickness: 20,
        blur: 4,
        refractiveIndex: 1.25,
        lightIntensity: 0.6,
        chromaticAberration: 0.015,
        saturation: 1.2,
      ),
      horizontalPadding: 12,
      verticalPadding: 6,
      barHeight: 64,
      tabWidth: 136,
      selectedIconColor: const Color(0xFFF4F4F2),
      unselectedIconColor: const Color(0xFF8B8B8B),
      indicatorColor: const Color(0xFF242424).withOpacity(0.85),
      interactionBehavior: GlassInteractionBehavior.full,
      tabs: [
        GlassTab(
          icon: const _NavItemLabel(
            icon: CupertinoIcons.house,
            label: "HOME",
            isSelected: false,
          ),
          activeIcon: const _NavItemLabel(
            icon: CupertinoIcons.house_fill,
            label: "HOME",
            isSelected: true,
          ),
        ),

        GlassTab(
          icon: const _NavItemLabel(
            icon: CupertinoIcons.flag,
            label: "MY RIDES",
            isSelected: false,
          ),
          activeIcon: const _NavItemLabel(
            icon: CupertinoIcons.flag_fill,
            label: "MY RIDES",
            isSelected: true,
          ),
        ),
      ],
    );
  }
}

class _NavItemLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavItemLabel({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFFF4F4F2)
        : const Color(0xFF8B8B8B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final RideService _rideService = RideService();
  final WeatherService _weatherService = WeatherService();

  WeatherCondition _weatherCondition = WeatherCondition.clearDark;
  bool _isLoadingWeather = false;
  bool _isCreatingRide = false;
  bool _isJoiningRide = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _loadWeather();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0.0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;
    setState(() => _isLoadingWeather = true);

    final condition = await _weatherService.fetchCurrentWeatherCondition();

    if (!mounted) return;
    setState(() {
      _weatherCondition = condition;
      _isLoadingWeather = false;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _createRide() async {
    if (_isCreatingRide) return;
    setState(() => _isCreatingRide = true);

    try {
      final ride = await _rideService.createRide();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MapPage(rideDocumentId: ride.documentId, initialRide: ride),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create ride: $error')));
    } finally {
      if (mounted) setState(() => _isCreatingRide = false);
    }
  }

  Future<void> _showJoinRideDialog() async {
    final controller = TextEditingController();

    final rideId = await showGeneralDialog<String>(
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
                        icon: const Icon(Icons.close, color: Color(0xFFF4F4F2)),
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
                        borderSide: BorderSide(color: Color(0xFF242424)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF4F4F2)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF4F4F2),
                        side: const BorderSide(color: Color(0xFF242424)),
                        backgroundColor: const Color(0xFF111111),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        "JOIN GROUP",
                        style: TextStyle(letterSpacing: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (rideId != null && rideId.isNotEmpty) {
      _joinRide(rideId);
    }
  }

  Future<void> _joinRide(String rideId) async {
    if (_isJoiningRide) return;
    setState(() => _isJoiningRide = true);

    try {
      final ride = await _rideService.joinRide(rideId);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MapPage(rideDocumentId: ride.documentId, initialRide: ride),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to join ride: $error')));
    } finally {
      if (mounted) setState(() => _isJoiningRide = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background: DynamicWeatherBackground(condition: _weatherCondition),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadWeather,
            color: const Color(0xFFF4F4F2),
            backgroundColor: const Color(0xFF161616),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                              backgroundImage:
                                  _authService.currentUserPhotoUrl != null
                                  ? NetworkImage(
                                      _authService.currentUserPhotoUrl!,
                                    )
                                  : null,
                              child: _authService.currentUserPhotoUrl == null
                                  ? const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFFF4F4F2),
                                      size: 18,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 56),

                      Container(
                        width: 40,
                        height: 1,
                        color: const Color(0xFFF4F4F2),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        "Begin a\nshared journey.",
                        style: TextStyle(
                          color: Color(0xFFF4F4F2),
                          fontSize: 44,
                          height: 1.05,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Create a group and explore\ntogether in real time.",
                        style: TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 56),
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isLoadingWeather
                                  ? const Color(0xFF8B8B8B)
                                  : const Color(0xFFF4F4F2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isLoadingWeather
                                ? "SYNCING WEATHER..."
                                : "WEATHER SYNCED",
                            style: const TextStyle(
                              color: Color(0xFF8B8B8B),
                              fontSize: 10,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      OpentrailButton(
                        number: "01",
                        title: _isCreatingRide ? "CREATING..." : "CREATE GROUP",
                        subtitle: "Start a new ride and invite others.",
                        onTap: _isCreatingRide ? null : _createRide,
                      ),
                      const SizedBox(height: 16),
                      OpentrailButton(
                        number: "02",
                        title: _isJoiningRide ? "JOINING..." : "JOIN GROUP",
                        subtitle: "Enter an invitation code to join.",
                        onTap: _isJoiningRide ? null : _showJoinRideDialog,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyRidesPage extends StatefulWidget {
  const MyRidesPage({super.key});

  @override
  State<MyRidesPage> createState() => _MyRidesPageState();
}

class _MyRidesPageState extends State<MyRidesPage> {
  int _selectedSegment = 0;
  late final PageController _pageController;
  final RideService _rideService = RideService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSegmentChanged(int index) {
    setState(() => _selectedSegment = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              const Text(
                "MY RIDES",
                style: TextStyle(
                  color: Color(0xFFF4F4F2),
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 6,
                ),
              ),

              const SizedBox(height: 24),

              // Glass Segmented Selector
              RideSegmentSelector(
                selectedIndex: _selectedSegment,
                onSegmentSelected: _onSegmentChanged,
              ),

              const SizedBox(height: 24),

              // Tab View Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _selectedSegment = index);
                  },
                  children: [
                    _RidesListStream(
                      stream: _rideService.watchCreatedRides(),
                      emptyMessage: "You haven't created any rides yet.",
                      storageKey: 'created_rides',
                    ),
                    _RidesListStream(
                      stream: _rideService.watchJoinedRides(),
                      emptyMessage: "No joined rides yet.",
                      storageKey: 'joined_rides',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RideSegmentSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;

  const RideSegmentSelector({
    super.key,
    required this.selectedIndex,
    required this.onSegmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF141414).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF242424), width: 1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth = constraints.maxWidth / 2;

              return Stack(
                children: [
                  // Smooth Glass Capsule Background
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * segmentWidth,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF383838),
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  // Segment Titles
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSegmentSelected(0),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: selectedIndex == 0
                                    ? const Color(0xFFF4F4F2)
                                    : const Color(0xFF8B8B8B),
                                fontSize: 12,
                                fontWeight: selectedIndex == 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                letterSpacing: 2,
                              ),
                              child: const Text("CREATED"),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSegmentSelected(1),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: selectedIndex == 1
                                    ? const Color(0xFFF4F4F2)
                                    : const Color(0xFF8B8B8B),
                                fontSize: 12,
                                fontWeight: selectedIndex == 1
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                letterSpacing: 2,
                              ),
                              child: const Text("JOINED"),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RidesListStream extends StatefulWidget {
  final Stream<List<dynamic>> stream;
  final String emptyMessage;
  final String storageKey;

  const _RidesListStream({
    required this.stream,
    required this.emptyMessage,
    required this.storageKey,
  });

  @override
  State<_RidesListStream> createState() => _RidesListStreamState();
}

class _RidesListStreamState extends State<_RidesListStream>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<dynamic>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF4F4F2),
              strokeWidth: 1.5,
            ),
          );
        }

        final rides = snapshot.data ?? [];

        if (rides.isEmpty) {
          return ListView(
            key: PageStorageKey('${widget.storageKey}_empty'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              SizedBox(
                height: 360,
                child: _EmptyRidesState(message: widget.emptyMessage),
              ),
            ],
          );
        }

        return ListView.builder(
          key: PageStorageKey('${widget.storageKey}_list'),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 110),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _RideCard(ride: rides[index]);
          },
        );
      },
    );
  }
}

class _RideCard extends StatefulWidget {
  final dynamic ride;

  const _RideCard({required this.ride});

  @override
  State<_RideCard> createState() => _RideCardState();
}

class _RideCardState extends State<_RideCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.ride.isNavigating ?? false;
    final destination = (widget.ride.destination as String?)?.trim();
    final destinationLabel = destination == null || destination.isEmpty
        ? "No destination set"
        : destination;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapPage(
                rideDocumentId: widget.ride.documentId,
                initialRide: widget.ride,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: GlassCard(
            shape: LiquidRoundedRectangle(borderRadius: 1),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.ride.rideId ?? "UNKNOWN ID",
                      style: const TextStyle(
                        color: Color(0xFFF4F4F2),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF1C3A27)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: active
                              ? const Color(0xFF2A5E3F)
                              : const Color(0xFF2B2B2B),
                        ),
                      ),
                      child: Text(
                        active ? "ACTIVE" : "ENDED",
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF52C47C)
                              : const Color(0xFF8B8B8B),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  destinationLabel,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Color(0xFF8B8B8B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.ride.leaderName ?? "Unknown Leader",
                      style: const TextStyle(
                        color: Color(0xFF8B8B8B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Icon(
                      Icons.people_outline,
                      size: 14,
                      color: Color(0xFF8B8B8B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${widget.ride.memberCount ?? 1} members",
                      style: const TextStyle(
                        color: Color(0xFF8B8B8B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRidesState extends StatelessWidget {
  final String message;
  const _EmptyRidesState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.explore_outlined, color: Color(0xFF242424), size: 48),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8B8B8B),
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
