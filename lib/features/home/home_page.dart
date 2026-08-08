import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:open_trail/auth/auth_service.dart';
import 'package:open_trail/features/community/community_page.dart';
import 'package:open_trail/features/home/dialogs/join_ride_dialog.dart';
import 'package:open_trail/features/home/widgets/empty_rides_state.dart';
import 'package:open_trail/services/ride_service.dart';
import 'package:open_trail/features/home/widgets/floating_glass_bottom_bar.dart';
import 'package:open_trail/features/home/widgets/greeting_section.dart';
import 'package:open_trail/features/home/widgets/hero_section.dart';
import 'package:open_trail/features/home/widgets/home_header.dart';
import 'package:open_trail/features/home/widgets/quick_actions.dart';
import 'package:open_trail/features/home/widgets/ride_card.dart';
import 'package:open_trail/features/home/widgets/ride_segment_selector.dart';
import 'package:open_trail/features/home/widgets/weather_summary.dart';
import 'package:open_trail/features/maps/map_page.dart';
import 'package:open_trail/features/weather/dynamic_weather_background.dart';
import 'package:open_trail/features/weather/weather_condition.dart';
import 'package:open_trail/features/weather/weather_data.dart';
import 'package:open_trail/features/weather/weather_service.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    MyRidesPage(),
    CommunityPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Persistent Stack with Butter-Smooth Depth Fade Transition
          for (int i = 0; i < _pages.length; i++)
            IgnorePointer(
              ignoring: i != _currentIndex,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                opacity: i == _currentIndex ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  scale: i == _currentIndex ? 1.0 : 0.98,
                  child: _pages[i],
                ),
              ),
            ),

          // Floating Glass Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: SizedBox(
                width: 360,
                child: Material(
                  color: Colors.transparent,
                  child: FloatingGlassBottomBar(
                    currentIndex: _currentIndex,
                    onTabSelected: (index) {
                      HapticFeedback.mediumImpact();
                      if (_currentIndex != index) {
                        setState(() => _currentIndex = index);
                      }
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

  WeatherData? _weather;
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

  /// Weather refresh with guaranteed minimum execution time for visual feedback
  Future<void> _loadWeather() async {
    if (!mounted) return;

    setState(() => _isLoadingWeather = true);

    try {
      await Future.wait([
        _weatherService.fetchCurrentWeather().then((weather) {
          if (mounted) {
            setState(() => _weather = weather);
          }
        }),
        // Holds spinner open for at least 800ms so pull interaction feels smooth
        Future.delayed(const Duration(milliseconds: 800)),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weather Sync Failed: $e'),
          backgroundColor: const Color(0xFF161616),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
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
    final rideId = await showJoinRideDialog(context);

    if (!mounted) return;

    if (rideId == null || rideId.trim().isEmpty) {
      return;
    }

    await _joinRide(rideId.trim());
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
      background: DynamicWeatherBackground(
        condition: _weather?.condition ?? WeatherCondition.clearDark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: const Color(0xFFF4F4F2),
            backgroundColor: const Color(0xFF161616),
            strokeWidth: 2.0,
            displacement: 40.0,
            onRefresh: _loadWeather,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                  sliver: SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HomeHeader(authService: _authService),

                            const SizedBox(height: 26),

                            GreetingSection(
                              name:
                                  _authService.currentUser?.displayName ??
                                  "Rider",
                            ),

                            const SizedBox(height: 56),

                            WeatherSummary(
                              temperature: _weather?.temperature,
                              description: _weather?.description ?? "",
                              location: _weather?.location ?? "",
                              isLoading: _isLoadingWeather,
                            ),

                            const SizedBox(width: 20),

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
                                        : const Color(0xFF00E676),
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

                            const SizedBox(height: 26),

                            const HeroSection(),

                            const SizedBox(height: 28),

                            QuickActions(
                              isCreating: _isCreatingRide,
                              isJoining: _isJoiningRide,
                              onCreate: _createRide,
                              onJoin: _showJoinRideDialog,
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

              RideSegmentSelector(
                selectedIndex: _selectedSegment,
                onSegmentSelected: _onSegmentChanged,
              ),

              const SizedBox(height: 24),

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

  Future<void> _handleManualRefresh() async {
    // Provide tactile delay on stream manual pulls
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

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

        return RefreshIndicator(
          color: const Color(0xFFF4F4F2),
          backgroundColor: const Color(0xFF161616),
          strokeWidth: 2.0,
          onRefresh: _handleManualRefresh,
          child: CustomScrollView(
            key: PageStorageKey('${widget.storageKey}_scroll'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              if (rides.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyRidesState(message: widget.emptyMessage),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => RideCard(ride: rides[index]),
                      childCount: rides.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
