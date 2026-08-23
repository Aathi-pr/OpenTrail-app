import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:open_trail/auth/auth_service.dart';
import 'package:open_trail/features/community/community_page.dart';
import 'package:open_trail/features/home/dialogs/join_ride_dialog.dart';
import 'package:open_trail/features/home/widgets/empty_rides_state.dart';
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
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/services/ride_service.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() =>
      _MainNavigationPageState();
}

class _MainNavigationPageState
    extends State<MainNavigationPage> {
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
          for (int i = 0; i < _pages.length; i++)
            IgnorePointer(
              ignoring: i != _currentIndex,
              child: AnimatedOpacity(
                duration:
                    const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                opacity:
                    i == _currentIndex ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration:
                      const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  scale:
                      i == _currentIndex ? 1.0 : 0.98,
                  child: _pages[i],
                ),
              ),
            ),
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
                        setState(() {
                          _currentIndex = index;
                        });
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
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService =
      AuthService();

  final RideService _rideService =
      RideService();

  final WeatherService _weatherService =
      WeatherService();

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
      duration:
          const Duration(milliseconds: 800),
    );

    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;

    setState(() {
      _isLoadingWeather = true;
    });

    try {
      await Future.wait([
        _weatherService
            .fetchCurrentWeather()
            .then((weather) {
          if (!mounted) return;

          setState(() {
            _weather = weather;
          });
        }),
        Future.delayed(
          const Duration(milliseconds: 800),
        ),
      ]);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Weather Sync Failed: $e'),
          backgroundColor:
              const Color(0xFF161616),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<void> _createRide() async {
    if (_isCreatingRide) return;

    setState(() {
      _isCreatingRide = true;
    });

    try {
      final ride =
          await _rideService.createRide();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapPage(
            rideDocumentId:
                ride.documentId,
            initialRide: ride,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create ride: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRide = false;
        });
      }
    }
  }

  Future<void> _showJoinRideDialog() async {
    final rideId =
        await showJoinRideDialog(context);

    if (!mounted) return;

    if (rideId == null ||
        rideId.trim().isEmpty) {
      return;
    }

    await _joinRide(rideId.trim());
  }

  Future<void> _joinRide(String rideId) async {
    if (_isJoiningRide) return;

    setState(() {
      _isJoiningRide = true;
    });

    try {
      final ride =
          await _rideService.joinRide(rideId);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapPage(
            rideDocumentId:
                ride.documentId,
            initialRide: ride,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to join ride: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningRide = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background:
          DynamicWeatherBackground(
        condition:
            _weather?.condition ??
            WeatherCondition.clearDark,
      ),
      child: Scaffold(
        backgroundColor:
            Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color:
                const Color(0xFFF4F4F2),
            backgroundColor:
                const Color(0xFF161616),
            strokeWidth: 2.0,
            displacement: 40.0,
            onRefresh: _loadWeather,
            child: CustomScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(
                parent:
                    BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    120,
                  ),
                  sliver:
                      SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child:
                          SlideTransition(
                        position: _slideUp,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            HomeHeader(
                              authService:
                                  _authService,
                            ),

                            const SizedBox(
                              height: 26,
                            ),

                            GreetingSection(
                              name: _authService
                                      .currentUser
                                      ?.displayName ??
                                  'Rider',
                            ),

                            const SizedBox(
                              height: 56,
                            ),

                            WeatherSummary(
                              temperature:
                                  _weather
                                      ?.temperature,
                              description:
                                  _weather
                                          ?.description ??
                                      '',
                              location:
                                  _weather?.location ??
                                      '',
                              isLoading:
                                  _isLoadingWeather,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            Row(
                              children: [
                                AnimatedContainer(
                                  duration:
                                      const Duration(
                                    milliseconds:
                                        300,
                                  ),
                                  width: 6,
                                  height: 6,
                                  decoration:
                                      BoxDecoration(
                                    shape:
                                        BoxShape.circle,
                                    color:
                                        _isLoadingWeather
                                            ? const Color(
                                                0xFF8B8B8B,
                                              )
                                            : const Color(
                                                0xFF00E676,
                                              ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Text(
                                  _isLoadingWeather
                                      ? 'SYNCING WEATHER...'
                                      : 'WEATHER SYNCED',
                                  style:
                                      const TextStyle(
                                    color:
                                        Color(
                                      0xFF8B8B8B,
                                    ),
                                    fontSize: 10,
                                    letterSpacing:
                                        3,
                                    fontWeight:
                                        FontWeight
                                            .w400,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 26,
                            ),

                            const HeroSection(),

                            const SizedBox(
                              height: 28,
                            ),

                            QuickActions(
                              isCreating:
                                  _isCreatingRide,
                              isJoining:
                                  _isJoiningRide,
                              onCreate:
                                  _createRide,
                              onJoin:
                                  _showJoinRideDialog,
                            ),

                            const SizedBox(
                              height: 36,
                            ),

                            RecentExpeditions(),
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

class RecentExpeditions extends StatelessWidget {
  const RecentExpeditions({super.key});

  List<RideModel> _filterAndSortRides(
    List<RideModel>? created,
    List<RideModel>? joined,
  ) {
    final Map<String, RideModel> uniqueRides = {};

    final createdList = created ?? [];
    final joinedList = joined ?? [];

    for (final ride in [...createdList, ...joinedList]) {
      if (ride.isActive && ride.isCommunityRide) {
        uniqueRides[ride.documentId] = ride;
      }
    }

    final rides = uniqueRides.values.toList();

    rides.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return rides.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rideService = RideService();

    return StreamBuilder<List<RideModel>>(
      stream: rideService.watchCreatedRides(),
      builder: (context, createdSnapshot) {
        return StreamBuilder<List<RideModel>>(
          stream: rideService.watchJoinedRides(),
          builder: (context, joinedSnapshot) {
            if (createdSnapshot.connectionState == ConnectionState.waiting &&
                joinedSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            final recentRides = _filterAndSortRides(
              createdSnapshot.data,
              joinedSnapshot.data,
            );

            if (recentRides.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 2, bottom: 12),
                  child: Text(
                    'RECENT EXPEDITIONS',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
                for (final ride in recentRides)
                  _RecentExpeditionCard(
                    key: ValueKey(ride.documentId),
                    ride: ride,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RecentExpeditionCard extends StatefulWidget {
  const _RecentExpeditionCard({super.key, required this.ride});

  final RideModel ride;

  @override
  State<_RecentExpeditionCard> createState() => _RecentExpeditionCardState();
}

class _RecentExpeditionCardState extends State<_RecentExpeditionCard> {
  bool _isPressed = false;

  void _rejoin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(rideDocumentId: widget.ride.documentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF222222), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: GlassCard(
              shape: LiquidRoundedRectangle(borderRadius: 1),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ACTIVE STATUS INDICATOR
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ACTIVE EXPEDITION',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 9,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // EXPEDITION TITLE
                        Text(
                          ride.communityRideTitle ?? 'Community Expedition',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF4F4F2),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // DESTINATION
                        Text(
                          ride.destination ?? 'Unknown destination',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // RIDER COUNT & RIDE ID METADATA
                        Text(
                          '${ride.memberCount} RIDERS  •  ${ride.rideId.toUpperCase()}',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // HIGH-CONTRAST ACTION BUTTON
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isPressed = true),
                    onTapUp: (_) {
                      setState(() => _isPressed = false);
                      _rejoin(context);
                    },
                    onTapCancel: () => setState(() => _isPressed = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F2),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: const Text(
                        'REJOIN',
                        style: TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyRidesPage
    extends StatefulWidget {
  const MyRidesPage({super.key});

  @override
  State<MyRidesPage> createState() =>
      _MyRidesPageState();
}

class _MyRidesPageState
    extends State<MyRidesPage> {
  int _selectedSegment = 0;

  late final PageController
      _pageController;

  final RideService _rideService =
      RideService();

  @override
  void initState() {
    super.initState();

    _pageController =
        PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSegmentChanged(
    int index,
  ) {
    setState(() {
      _selectedSegment = index;
    });

    _pageController.animateToPage(
      index,
      duration:
          const Duration(
        milliseconds: 280,
      ),
      curve:
          Curves.easeOutCubic,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            0,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'MY RIDES',
                style: TextStyle(
                  color:
                      Color(0xFFF4F4F2),
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w300,
                  letterSpacing: 6,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              RideSegmentSelector(
                selectedIndex:
                    _selectedSegment,
                onSegmentSelected:
                    _onSegmentChanged,
              ),

              const SizedBox(
                height: 24,
              ),

              Expanded(
                child: PageView(
                  controller:
                      _pageController,
                  onPageChanged:
                      (index) {
                    setState(() {
                      _selectedSegment =
                          index;
                    });
                  },
                  children: [
                    _RidesListStream(
                      stream:
                          _rideService
                              .watchCreatedRides(),
                      emptyMessage:
                          "You haven't created any rides yet.",
                      storageKey:
                          'created_rides',
                    ),
                    _RidesListStream(
                      stream:
                          _rideService
                              .watchJoinedRides(),
                      emptyMessage:
                          'No joined rides yet.',
                      storageKey:
                          'joined_rides',
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

class _RidesListStream
    extends StatefulWidget {
  const _RidesListStream({
    required this.stream,
    required this.emptyMessage,
    required this.storageKey,
  });

  final Stream<List<dynamic>> stream;
  final String emptyMessage;
  final String storageKey;

  @override
  State<_RidesListStream>
      createState() =>
          _RidesListStreamState();
}

class _RidesListStreamState
    extends State<_RidesListStream>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void>
      _handleManualRefresh() async {
    await Future.delayed(
      const Duration(
        milliseconds: 600,
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    super.build(context);

    return StreamBuilder<List<dynamic>>(
      stream: widget.stream,
      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(
              color:
                  Color(0xFFF4F4F2),
              strokeWidth: 1.5,
            ),
          );
        }

        final rides =
            snapshot.data ?? [];

        return RefreshIndicator(
          color:
              const Color(0xFFF4F4F2),
          backgroundColor:
              const Color(0xFF161616),
          strokeWidth: 2,
          onRefresh:
              _handleManualRefresh,
          child: CustomScrollView(
            key: PageStorageKey(
              '${widget.storageKey}_scroll',
            ),
            physics:
                const AlwaysScrollableScrollPhysics(
              parent:
                  BouncingScrollPhysics(),
            ),
            slivers: [
              if (rides.isEmpty)
                SliverFillRemaining(
                  hasScrollBody:
                      false,
                  child:
                      EmptyRidesState(
                    message:
                        widget.emptyMessage,
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 120,
                  ),
                  sliver: SliverList(
                    delegate:
                        SliverChildBuilderDelegate(
                      (
                        context,
                        index,
                      ) {
                        return RideCard(
                          ride:
                              rides[index],
                        );
                      },
                      childCount:
                          rides.length,
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
