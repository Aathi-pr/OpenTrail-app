// features/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'; // Official package API
import 'package:open_trail/features/maps/map_page.dart';
import 'package:open_trail/features/settings/settings_page.dart';
import 'package:open_trail/services/ride_service.dart';
import 'package:open_trail/widgets/opentrail_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RideService _rideService = RideService();
  bool _isCreatingRide = false;
  bool _isJoiningRide = false;

  Future<void> _createRide() async {
    if (_isCreatingRide) return;

    setState(() {
      _isCreatingRide = true;
    });

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
    } on RideException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create ride: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRide = false;
        });
      }
    }
  }

  Future<void> _showJoinRideDialog() async {
    final controller = TextEditingController();

    final rideId = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Join",
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        const bg = Color(0xFF0A0A0A);
        const fg = Color(0xFFF5F5F2);
        const secondary = Color(0xFF8B8B8B);
        const border = Color(0xFF242424);

        return Scaffold(
          backgroundColor: bg,
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
                            color: fg,
                            fontSize: 18,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: fg),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(width: 48, height: 1, color: fg),
                  const SizedBox(height: 32),
                  const Text(
                    "Enter your\ninvitation code.",
                    style: TextStyle(
                      color: fg,
                      fontSize: 42,
                      height: 1.05,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Use the code shared by the ride owner.",
                    style: TextStyle(
                      color: secondary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 56),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: fg,
                      fontSize: 30,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
                    decoration: const InputDecoration(
                      hintText: "OT-XXXXXX",
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        letterSpacing: 6,
                      ),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: fg),
                      ),
                    ),
                    onSubmitted: (value) =>
                        Navigator.pop(context, value.trim()),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: fg,
                        side: const BorderSide(color: border),
                        backgroundColor: const Color(0xFF111111),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        "JOIN GROUP",
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );

    if (rideId == null || rideId.trim().isEmpty) return;

    await _joinRide(rideId.trim());
  }

  Future<void> _joinRide(String rideId) async {
    if (_isJoiningRide) return;

    setState(() {
      _isJoiningRide = true;
    });

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
    } on RideException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to join ride: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningRide = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0A);

    return DefaultTabController(
      length: 2,
      child: GlassPage(
        background: Container(color: bg),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeHeader(
                            onSettingsTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 36),
                          const _HeroSection(),
                          const SizedBox(height: 40),
                          _ActionButtons(
                            isCreating: _isCreatingRide,
                            isJoining: _isJoiningRide,
                            onCreateTap: _createRide,
                            onJoinTap: _showJoinRideDialog,
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                  const SliverPersistentHeader(
                    pinned: true,
                    delegate: _RideTabsHeaderDelegate(),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _CreatedRidesList(rideService: _rideService),
                  _JoinedRidesList(rideService: _rideService),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── PRIVATE UI SUB-COMPONENTS ──────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final VoidCallback onSettingsTap;
  const _HomeHeader({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "OPEN TRAIL",
            style: TextStyle(
              color: Color(0xFFF4F4F2),
              fontSize: 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 6,
            ),
          ),
        ),
        IconButton(
          splashRadius: 20,
          onPressed: onSettingsTap,
          icon: const Icon(Icons.settings_outlined, color: Color(0xFFF4F4F2)),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 48, height: 1, color: const Color(0xFFF4F4F2)),
        const SizedBox(height: 28),
        const Text(
          "Begin a\nshared journey.",
          style: TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 44,
            height: 1.05,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "Create a group and explore\ntogether in real time.",
          style: TextStyle(color: Color(0xFF8B8B8B), fontSize: 17, height: 1.5),
        ),
        const SizedBox(height: 36),
        Container(width: 48, height: 1, color: const Color(0xFFF4F4F2)),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isCreating;
  final bool isJoining;
  final VoidCallback? onCreateTap;
  final VoidCallback? onJoinTap;

  const _ActionButtons({
    required this.isCreating,
    required this.isJoining,
    this.onCreateTap,
    this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OpentrailButton(
          number: "01",
          title: isCreating ? "CREATING..." : "CREATE GROUP",
          subtitle: "Start a new ride and invite others.",
          onTap: isCreating ? null : onCreateTap,
        ),
        const SizedBox(height: 18),
        OpentrailButton(
          number: "02",
          title: isJoining ? "JOINING..." : "JOIN WITH CODE",
          subtitle: "Enter an invitation code to join.",
          onTap: isJoining ? null : onJoinTap,
        ),
      ],
    );
  }
}

class _RideTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _RideTabsHeaderDelegate();

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            "MY RIDES",
            style: TextStyle(
              color: Color(0xFFF4F4F2),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFFF4F4F2),
            unselectedLabelColor: const Color(0xFF4A4A4A),
            indicatorColor: const Color(0xFFF4F4F2),
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: const EdgeInsets.only(right: 32),
            indicatorPadding: EdgeInsets.zero,
            dividerColor: const Color(0xFF1C1C1C),
            tabs: const [
              Tab(text: "Created"),
              Tab(text: "Joined"),
            ],
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 82.0;

  @override
  double get minExtent => 82.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _CreatedRidesList extends StatelessWidget {
  final RideService rideService;
  const _CreatedRidesList({required this.rideService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: rideService.watchCreatedRides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF4F4F2)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Color(0xFFEF5350), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return const _EmptyState(
            message: "You haven't created any shared paths yet.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _RideCard(ride: rides[index]);
          },
        );
      },
    );
  }
}

class _JoinedRidesList extends StatelessWidget {
  final RideService rideService;
  const _JoinedRidesList({required this.rideService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: rideService.watchJoinedRides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF4F4F2)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Color(0xFFEF5350), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return const _EmptyState(
            message: "No active shared group invitations found.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _RideCard(ride: rides[index]);
          },
        );
      },
    );
  }
}

class _RideCard extends StatelessWidget {
  final dynamic ride;

  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final bool active = ride.isNavigating ?? false;
    final destination = (ride.destination as String?)?.trim();
    final destinationLabel = destination == null || destination.isEmpty
        ? "No destination"
        : destination;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MapPage(rideDocumentId: ride.documentId, initialRide: ride),
            ),
          );
        },
        child: GlassCard(
          shape: LiquidRoundedRectangle(borderRadius: 1),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    ride.rideId ?? "UNKNOWN ID",
                    style: const TextStyle(
                      color: Color(0xFFF4F4F2),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
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
                          : const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      active ? "ACTIVE" : "ENDED",
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF52C47C)
                            : const Color(0xFF8B8B8B),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
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
                    ride.leaderName ?? "Unknown Leader",
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
                    "${ride.memberCount ?? 1} members",
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.explore_outlined,
            color: Color(0xFF222222),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
