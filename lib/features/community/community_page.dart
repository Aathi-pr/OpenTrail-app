import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:open_trail/features/community/community_ride_details_page.dart';
import 'package:open_trail/features/community/create_community_ride_page.dart';
import 'package:open_trail/features/weather/dynamic_weather_background.dart';
import 'package:open_trail/features/weather/weather_condition.dart';
import 'package:open_trail/features/weather/weather_data.dart';
import 'package:open_trail/features/weather/weather_service.dart';
import 'package:open_trail/models/community_ride.dart';
import 'package:open_trail/services/community_ride_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final CommunityRideService _communityRideService = CommunityRideService();

  final TextEditingController _searchController = TextEditingController();

  int _selectedFilterIndex = 0;

  static const List<String> _filters = [
    'ALL TRAILS',
    'ADVENTURE',
    'TOURING',
    'WEEKEND',
    'NEARBY',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onCreateRidePressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCommunityRidePage()),
    );
  }

  List<CommunityRide> _processRides(List<CommunityRide> rides) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final search = _searchController.text.trim().toLowerCase();

    final filtered = rides.where((ride) {
      if (search.isNotEmpty) {
        final matchesSearch =
            ride.title.toLowerCase().contains(search) ||
            ride.destination.toLowerCase().contains(search) ||
            ride.meetingPoint.toLowerCase().contains(search) ||
            ride.category.toLowerCase().contains(search) ||
            ride.leaderName.toLowerCase().contains(search) ||
            ride.rideId.toLowerCase().contains(search);

        if (!matchesSearch) {
          return false;
        }
      }

      switch (_selectedFilterIndex) {
        case 1:
          return ride.category.trim().toLowerCase() == 'adventure';

        case 2:
          return ride.category.trim().toLowerCase() == 'touring';

        case 3:
          return ride.category.trim().toLowerCase() == 'weekend';

        case 4:
          return true;

        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) {
      final aMine = a.leaderUid == currentUid;

      final bMine = b.leaderUid == currentUid;

      if (aMine && !bMine) {
        return -1;
      }

      if (!aMine && bMine) {
        return 1;
      }

      return a.departureTime.compareTo(b.departureTime);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080909),
      body: SafeArea(
        child: StreamBuilder<List<CommunityRide>>(
          stream: _communityRideService.watchPublicRides(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: () {
                  setState(() {});
                },
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _LoadingState();
            }

            final rides = _processRides(
              snapshot.data ?? const <CommunityRide>[],
            );

            return RefreshIndicator(
              color: const Color(0xFF080909),
              backgroundColor: const Color(0xFFF4F4F2),
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                children: [
                  _buildHeader(),

                  const SizedBox(height: 42),

                  _buildHero(),

                  const SizedBox(height: 32),

                  _buildSearch(),

                  const SizedBox(height: 13),

                  _buildFilters(),

                  const SizedBox(height: 38),

                  if (rides.isEmpty)
                    _EmptyCommunityState(onCreateRide: _onCreateRidePressed)
                  else
                    _buildRideSections(rides),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'CLUB // EXPEDITIONS',
            style: TextStyle(
              color: Color(0xFF9B9D99),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.8,
            ),
          ),
        ),
        _CreateButton(onTap: _onCreateRidePressed),
      ],
    );
  }

  Widget _buildHero() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXPLORE',
          style: TextStyle(
            color: Color(0xFF858884),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 3.4,
          ),
        ),

        SizedBox(height: 9),

        Text(
          'PUBLIC\nTRAILS.',
          style: TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 41,
            fontWeight: FontWeight.w200,
            letterSpacing: -1.9,
            height: 0.96,
          ),
        ),

        SizedBox(height: 16),

        Text(
          'Find a route. Join a group. Ride together.',
          style: TextStyle(
            color: Color(0xFF929590),
            fontSize: 13,
            fontWeight: FontWeight.w300,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF111212),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF292B2A)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() {});
        },
        style: const TextStyle(
          color: Color(0xFFF4F4F2),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: const Color(0xFFF4F4F2),
        decoration: const InputDecoration(
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: Color(0xFF969995),
            size: 17,
          ),
          hintText: 'SEARCH EXPEDITIONS...',
          hintStyle: TextStyle(
            color: Color(0xFF6F726E),
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          return _FilterSegment(
            label: _filters[index],
            isSelected: _selectedFilterIndex == index,
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildRideSections(List<CommunityRide> rides) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final myRides = rides
        .where((ride) => ride.leaderUid == currentUid)
        .toList();

    final communityRides = rides
        .where((ride) => ride.leaderUid != currentUid)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (myRides.isNotEmpty) ...[
          const _SectionHeader(number: '01', title: 'YOUR EXPEDITIONS'),

          const SizedBox(height: 17),

          ...myRides.map(
            (ride) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _CommunityRideCard(ride: ride, isMine: true),
            ),
          ),

          if (communityRides.isNotEmpty) ...[
            const SizedBox(height: 21),

            const _SectionHeader(number: '02', title: 'COMMUNITY EXPEDITIONS'),

            const SizedBox(height: 17),
          ],
        ] else ...[
          const _SectionHeader(number: '01', title: 'UPCOMING DISPATCHES'),

          const SizedBox(height: 17),
        ],

        ...communityRides.map(
          (ride) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _CommunityRideCard(ride: ride, isMine: false),
          ),
        ),
      ],
    );
  }
}

class _CommunityRideCard extends StatefulWidget {
  const _CommunityRideCard({required this.ride, required this.isMine});

  final CommunityRide ride;
  final bool isMine;

  @override
  State<_CommunityRideCard> createState() => _CommunityRideCardState();
}

class _CommunityRideCardState extends State<_CommunityRideCard> {
  final WeatherService _weatherService = WeatherService();

  WeatherData? _weather;

  bool _loadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void didUpdateWidget(covariant _CommunityRideCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.ride.documentId != widget.ride.documentId ||
        oldWidget.ride.destinationLatitude != widget.ride.destinationLatitude ||
        oldWidget.ride.destinationLongitude !=
            widget.ride.destinationLongitude) {
      _loadWeather();
    }
  }

  Future<void> _loadWeather() async {
    final latitude = widget.ride.destinationLatitude;

    final longitude = widget.ride.destinationLongitude;

    if (latitude == null || longitude == null) {
      if (!mounted) return;

      setState(() {
        _weather = null;
        _loadingWeather = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loadingWeather = true;
      });
    }

    try {
      final weather = await _weatherService.fetchWeatherForCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      setState(() {
        _weather = weather;
        _loadingWeather = false;
      });
    } catch (error) {
      debugPrint('OpenTrail weather error: $error');

      if (!mounted) return;

      setState(() {
        _weather = null;
        _loadingWeather = false;
      });
    }
  }

  String get _temperature {
    if (_weather == null) {
      return '--°';
    }

    return '${_weather!.temperature.round()}°';
  }

  String get _weatherLabel {
    if (_weather == null) {
      return 'NO DATA';
    }

    switch (_weather!.condition) {
      case WeatherCondition.clearDay:
        return 'CLEAR';

      case WeatherCondition.clearDark:
        return 'CLEAR NIGHT';

      case WeatherCondition.partlyCloudyDay:
        return 'PARTLY CLOUDY';

      case WeatherCondition.partlyCloudyNight:
        return 'PARTLY CLOUDY';

      case WeatherCondition.cloudy:
        return 'CLOUDY';

      case WeatherCondition.overcast:
        return 'OVERCAST';

      case WeatherCondition.drizzle:
        return 'DRIZZLE';

      case WeatherCondition.rainy:
        return 'RAIN';

      case WeatherCondition.heavyRain:
        return 'HEAVY RAIN';

      case WeatherCondition.thunderstorm:
        return 'THUNDERSTORM';

      case WeatherCondition.snowy:
        return 'SNOW';

      case WeatherCondition.sleet:
        return 'SLEET';

      case WeatherCondition.hail:
        return 'HAIL';

      case WeatherCondition.foggy:
        return 'FOG';

      case WeatherCondition.windy:
        return 'WINDY';

      case WeatherCondition.hazy:
        return 'HAZY';
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${weekdays[date.weekday - 1]} '
        '${date.day} '
        '${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  Color get _statusColor {
    switch (widget.ride.status) {
      case 'active':
        return const Color(0xFF52C47C);

      case 'cancelled':
        return const Color(0xFFD06A6A);

      default:
        return const Color(0xFFD8D9D5);
    }
  }

  String get _statusLabel {
    switch (widget.ride.status) {
      case 'active':
        return 'ACTIVE';

      case 'cancelled':
        return 'CANCELLED';

      default:
        return 'OPEN';
    }
  }

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityRideDetailsPage(ride: widget.ride),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final condition = _weather?.condition ?? WeatherCondition.clearDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openDetails,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.white.withValues(alpha: 0.035),
        highlightColor: Colors.white.withValues(alpha: 0.018),
        child: Container(
          height: 224,
          decoration: BoxDecoration(
            color: const Color(0xFF101111),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isMine
                  ? const Color(0xFF454744)
                  : const Color(0xFF292B2A),
              width: 0.8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: DynamicWeatherBackground(condition: condition),
                  ),
                ),

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.34),
                          Colors.black.withValues(alpha: 0.78),
                          Colors.black.withValues(alpha: 0.97),
                        ],
                        stops: const [0.0, 0.30, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 15, 17, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopRow(),

                      const Spacer(),

                      _buildDestination(),

                      const SizedBox(height: 15),

                      _buildInfoRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.isMine ? const Color(0xFFE8E9E5) : _statusColor,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 8),

        Text(
          widget.isMine
              ? 'YOUR EXPEDITION'
              : widget.ride.category.trim().toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFD1D2CE),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),

        const Spacer(),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            border: Border.all(color: _statusColor.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _statusLabel,
            style: TextStyle(
              color: _statusColor,
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestination() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.ride.rideId,
          style: const TextStyle(
            color: Color(0xFF8C8E8A),
            fontSize: 7,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.7,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          widget.ride.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 26,
            fontWeight: FontWeight.w300,
            letterSpacing: -1.0,
            height: 1.02,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Icon(
              CupertinoIcons.location_solid,
              color: Color(0xFFB8B9B5),
              size: 10,
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                widget.ride.destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFC6C7C3),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Column(
      children: [
        Container(height: 1, color: Colors.white.withValues(alpha: 0.11)),

        const SizedBox(height: 10),

        Row(
          children: [
            _CardMeta(
              icon: CupertinoIcons.calendar,
              value: _formatDate(widget.ride.departureTime),
            ),

            const SizedBox(width: 13),

            _CardMeta(
              icon: CupertinoIcons.clock,
              value: _formatTime(widget.ride.departureTime),
            ),

            const SizedBox(width: 13),

            _CardMeta(
              icon: CupertinoIcons.person_2,
              value: '${widget.ride.members.length}/${widget.ride.maxMembers}',
            ),

            const Spacer(),

            if (_loadingWeather)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.1,
                  color: Color(0xFFD1D2CE),
                ),
              )
            else
              _CardWeather(),

            const SizedBox(width: 13),

            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(
                CupertinoIcons.arrow_up_right,
                color: Color(0xFFD2D3CF),
                size: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeather() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _temperature,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 15,
            fontWeight: FontWeight.w300,
            height: 1,
          ),
        ),

        const SizedBox(width: 6),

        Text(
          _weatherLabel,
          style: const TextStyle(
            color: Color(0xFF9A9C98),
            fontSize: 6.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _CardWeather() {
    return _buildWeather();
  }
}

class _CardMeta extends StatelessWidget {
  const _CardMeta({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF858783), size: 10),

        const SizedBox(width: 5),

        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFB8B9B5),
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '[ $number ]',
          style: const TextStyle(
            color: Color(0xFF70736F),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.7,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE0E1DD),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(child: Container(height: 1, color: const Color(0xFF292B2A))),
      ],
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF151616),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF303230)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.add, color: Color(0xFFF4F4F2), size: 13),

              SizedBox(width: 6),

              Text(
                'CREATE',
                style: TextStyle(
                  color: Color(0xFFF4F4F2),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSegment extends StatelessWidget {
  const _FilterSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F4F2) : const Color(0xFF111212),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF4F4F2)
                : const Color(0xFF292B2A),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF080909)
                  : const Color(0xFF969995),
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 1.4,
        color: Color(0xFFF4F4F2),
      ),
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  const _EmptyCommunityState({required this.onCreateRide});

  final VoidCallback onCreateRide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 65),
      child: Column(
        children: [
          const Icon(CupertinoIcons.map, color: Color(0xFF3D403D), size: 40),

          const SizedBox(height: 19),

          const Text(
            'NO PUBLIC TRAILS',
            style: TextStyle(
              color: Color(0xFFE5E6E2),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.1,
            ),
          ),

          const SizedBox(height: 9),

          const Text(
            'Be the first rider to publish an expedition.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF81847F),
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 19),

          TextButton(
            onPressed: onCreateRide,
            child: const Text(
              'CREATE A RIDE',
              style: TextStyle(
                color: Color(0xFFF4F4F2),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: Color(0xFF777A76),
              size: 30,
            ),

            const SizedBox(height: 17),

            const Text(
              "COULDN'T LOAD EXPEDITIONS",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF4F4F2),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF858885),
                fontSize: 12,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 19),

            TextButton(
              onPressed: onRetry,
              child: const Text(
                'TRY AGAIN',
                style: TextStyle(
                  color: Color(0xFFF4F4F2),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
