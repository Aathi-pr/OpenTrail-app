import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:open_trail/features/maps/map_page.dart';
import 'package:open_trail/features/weather/dynamic_weather_background.dart';
import 'package:open_trail/features/weather/weather_condition.dart';
import 'package:open_trail/features/weather/weather_data.dart';
import 'package:open_trail/features/weather/weather_service.dart';

import 'package:open_trail/models/community_ride.dart';
import 'package:open_trail/models/waypoint_model.dart';

import 'package:open_trail/services/community_ride_service.dart';

class CommunityRideDetailsPage extends StatefulWidget {
  const CommunityRideDetailsPage({super.key, required this.ride});

  final CommunityRide ride;

  @override
  State<CommunityRideDetailsPage> createState() =>
      _CommunityRideDetailsPageState();
}

class _CommunityRideDetailsPageState extends State<CommunityRideDetailsPage> {
  final CommunityRideService _rideService = CommunityRideService();

  final WeatherService _weatherService = WeatherService();

  StreamSubscription<CommunityRide?>? _rideSubscription;

  late CommunityRide _ride;

  WeatherData? _weather;

  bool _loadingWeather = true;
  bool _starting = false;
  bool _cancelling = false;
  bool _requesting = false;

  String? _processingRequestUid;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  bool get _isLeader => _currentUid != null && _currentUid == _ride.leaderUid;

  bool get _isMember => _currentUid != null && _ride.hasMember(_currentUid!);

  bool get _hasRequested =>
      _currentUid != null && _ride.hasJoinRequest(_currentUid!);

  bool get _canRequestToJoin {
    if (_isLeader) return false;
    if (_isMember) return false;
    if (_hasRequested) return false;
    if (_ride.isFull) return false;
    if (_ride.status != 'published') return false;

    return true;
  }

  @override
  void initState() {
    super.initState();

    _ride = widget.ride;

    _listenToRide();

    _loadWeather();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();

    super.dispose();
  }

  void _listenToRide() {
    _rideSubscription = _rideService
        .watchRide(_ride.documentId)
        .listen(
          (updatedRide) {
            if (!mounted || updatedRide == null) {
              return;
            }

            final weatherChanged =
                _ride.destinationLatitude != updatedRide.destinationLatitude ||
                _ride.destinationLongitude != updatedRide.destinationLongitude;

            setState(() {
              _ride = updatedRide;
            });

            if (weatherChanged) {
              _loadWeather();
            }
          },
          onError: (error) {
            debugPrint('Community ride stream error: $error');
          },
        );
  }

  Future<void> _loadWeather() async {
    final latitude = _ride.destinationLatitude;

    final longitude = _ride.destinationLongitude;

    if (latitude == null || longitude == null) {
      if (!mounted) return;

      setState(() {
        _weather = null;
        _loadingWeather = false;
      });

      return;
    }

    setState(() {
      _loadingWeather = true;
    });

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

  WeatherCondition get _weatherCondition =>
      _weather?.condition ?? WeatherCondition.clearDark;

  String get _temperature {
    if (_weather == null) {
      return '--°';
    }

    return '${_weather!.temperature.round()}°';
  }

  String get _weatherLabel {
    if (_weather == null) {
      return 'WEATHER UNAVAILABLE';
    }

    return _formatWeatherCondition(_weather!.condition);
  }

  String _formatWeatherCondition(WeatherCondition condition) {
    switch (condition) {
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
        return 'LIGHT RAIN';

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

  Future<void> _acceptJoinRequest(String uid) async {
    if (_processingRequestUid != null) {
      return;
    }

    setState(() {
      _processingRequestUid = uid;
    });

    try {
      await _rideService.acceptJoinRequest(
        documentId: _ride.documentId,
        userId: uid,
      );

      if (!mounted) return;

      _showMessage('Rider accepted.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(_cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestUid = null;
        });
      }
    }
  }

  Future<void> _rejectJoinRequest(String uid) async {
    if (_processingRequestUid != null) {
      return;
    }

    setState(() {
      _processingRequestUid = uid;
    });

    try {
      await _rideService.rejectJoinRequest(
        documentId: _ride.documentId,
        userId: uid,
      );

      if (!mounted) return;

      _showMessage('Join request rejected.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(_cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestUid = null;
        });
      }
    }
  }

  Future<void> _startExpedition() async {
    if (_starting || !_isLeader) {
      return;
    }

    setState(() {
      _starting = true;
    });

    try {
      final operationalRideId = await _rideService.startRide(_ride.documentId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MapPage(rideDocumentId: operationalRideId),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(_cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _starting = false;
        });
      }
    }
  }

  Future<void> _cancelExpedition() async {
    if (_cancelling || !_isLeader) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF292A29)),
          ),
          title: const Text(
            'CANCEL EXPEDITION?',
            style: TextStyle(
              color: Color(0xFFF4F4F2),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.3,
            ),
          ),
          content: const Text(
            'This expedition will no longer be available to the community.',
            style: TextStyle(
              color: Color(0xFFB0B1AD),
              fontSize: 13,
              height: 1.55,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'KEEP',
                style: TextStyle(
                  color: Color(0xFFC2C2BE),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.7,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Color(0xFFD06A6A),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.7,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _cancelling = true;
    });

    try {
      await _rideService.cancelRide(_ride.documentId);

      if (!mounted) return;

      _showMessage('Expedition cancelled.');

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      _showMessage(_cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _cancelling = false;
        });
      }
    }
  }

  Future<void> _requestToJoin() async {
    if (_requesting) {
      return;
    }

    final uid = _currentUid;

    if (uid == null) {
      _showMessage('You must be signed in to join an expedition.');
      return;
    }

    if (_isLeader) {
      return;
    }

    if (_isMember) {
      _showMessage('You have already joined this expedition.');
      return;
    }

    if (_hasRequested) {
      _showMessage('Your join request is already pending.');
      return;
    }

    if (_ride.isFull) {
      _showMessage('This expedition is already full.');
      return;
    }

    if (_ride.status != 'published') {
      _showMessage('This expedition is no longer accepting riders.');
      return;
    }

    setState(() {
      _requesting = true;
    });

    try {
      await _rideService.requestToJoin(_ride.documentId);

      if (!mounted) return;

      _showMessage('Join request sent to ${_ride.leaderName}.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(_cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _requesting = false;
        });
      }
    }
  }

  void _openExpeditionMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(
          rideDocumentId: _ride.operationalRideDocumentId ?? _ride.documentId,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFFF4F4F2)),
          ),
          backgroundColor: const Color(0xFF171817),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  String _formatDeparture(DateTime date) {
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

  String _formatDateTime(DateTime date) {
    return '${_formatDeparture(date)} · '
        '${_formatTime(date)}';
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) {
      return '--';
    }

    if (minutes < 60) {
      return '$minutes MIN';
    }

    final hours = minutes ~/ 60;

    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '${hours}H';
    }

    return '${hours}H ${remainingMinutes}M';
  }

  String _formatCost(double? cost) {
    if (cost == null) {
      return '--';
    }

    if (cost <= 0) {
      return 'FREE';
    }

    return '₹${cost.toStringAsFixed(0)}';
  }

  String _waypointSubtitle(WaypointModel waypoint) {
    final parts = <String>[waypoint.categoryLabel.toUpperCase()];

    if (waypoint.stopMinutes > 0) {
      parts.add('${waypoint.stopMinutes} MIN STOP');
    }

    return parts.join(' · ');
  }

  String get _statusLabel {
    switch (_ride.status) {
      case 'active':
        return 'ACTIVE';

      case 'cancelled':
        return 'CANCELLED';

      case 'completed':
        return 'COMPLETED';

      default:
        return 'OPEN';
    }
  }

  Color get _statusColor {
    switch (_ride.status) {
      case 'active':
        return const Color(0xFF52C47C);

      case 'cancelled':
        return const Color(0xFFD06A6A);

      case 'completed':
        return const Color(0xFF858783);

      default:
        return const Color(0xFFD8D8D4);
    }
  }

  List<WaypointModel> get _sortedWaypoints {
    final waypoints = List<WaypointModel>.from(_ride.waypoints);

    waypoints.sort((a, b) => a.order.compareTo(b.order));

    return waypoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080909),
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: DynamicWeatherBackground(condition: _weatherCondition),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.38),
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.96),
                    ],
                    stops: const [0.0, 0.30, 0.62, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 45),
                    children: [
                      _buildHero(),

                      const SizedBox(height: 34),

                      _buildTripSchedule(),

                      const SizedBox(height: 38),

                      _buildSectionHeader(
                        'ROUTE',
                        trailing: '${_sortedWaypoints.length + 2} POINTS',
                      ),

                      const SizedBox(height: 15),

                      _buildRoute(),

                      const SizedBox(height: 38),

                      _buildSectionHeader('TRIP INFO'),

                      const SizedBox(height: 15),

                      _buildTripInfo(),

                      const SizedBox(height: 38),

                      _buildSectionHeader('EXPEDITION'),

                      const SizedBox(height: 15),

                      _buildDescription(),

                      const SizedBox(height: 38),

                      _buildSectionHeader(
                        'RIDERS',
                        trailing:
                            '${_ride.members.length.toString().padLeft(2, '0')} / '
                            '${_ride.maxMembers.toString().padLeft(2, '0')}',
                      ),

                      const SizedBox(height: 14),

                      _buildRiders(),

                      if (_isLeader && _ride.joinRequests.isNotEmpty) ...[
                        const SizedBox(height: 34),

                        _buildSectionHeader(
                          'REQUESTED',
                          trailing: _ride.joinRequests.length
                              .toString()
                              .padLeft(2, '0'),
                        ),

                        const SizedBox(height: 14),

                        _buildRequestedRiders(),
                      ],

                      if (_ride.destinationLatitude != null &&
                          _ride.destinationLongitude != null) ...[
                        const SizedBox(height: 38),
                        _buildSectionHeader('DESTINATION'),
                        const SizedBox(height: 14),
                        _buildDestination(),
                      ],

                      const SizedBox(height: 38),

                      _buildActions(),

                      const SizedBox(height: 18),

                      Center(child: _buildRideIdentifier()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 18, 0),
      child: Row(
        children: [
          _IconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(width: 7),

          const Expanded(
            child: Text(
              'CLUB // EXPEDITION',
              style: TextStyle(
                color: Color(0xFFB9BAB6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.6,
              ),
            ),
          ),

          Text(
            _ride.rideId,
            style: const TextStyle(
              color: Color(0xFF777975),
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CategoryLabel(text: _ride.category.toUpperCase()),

            const SizedBox(width: 11),

            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: _statusColor,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 7),

            Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          _ride.title,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 40,
            fontWeight: FontWeight.w200,
            height: 0.98,
            letterSpacing: -1.8,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(
                CupertinoIcons.location_solid,
                color: Color(0xFFB9BAB6),
                size: 13,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                _ride.destination,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD1D2CE),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        _buildWeather(),
      ],
    );
  }

  Widget _buildWeather() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_loadingWeather)
          const SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              strokeWidth: 1.2,
              color: Color(0xFFD7D8D4),
            ),
          )
        else
          Text(
            _temperature,
            style: const TextStyle(
              color: Color(0xFFF4F4F2),
              fontSize: 45,
              fontWeight: FontWeight.w200,
              height: 0.9,
              letterSpacing: -2,
            ),
          ),

        const SizedBox(width: 13),

        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _weatherLabel,
                style: const TextStyle(
                  color: Color(0xFFD2D3CF),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'DESTINATION WEATHER',
                style: TextStyle(
                  color: Color(0xFF777975),
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripSchedule() {
    return Column(
      children: [
        Container(height: 1, color: Colors.white.withValues(alpha: 0.13)),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _DepartureItem(
                label: 'DEPARTURE',
                value: _formatDeparture(_ride.departureTime),
              ),
            ),

            _verticalDivider(),

            Expanded(
              child: _DepartureItem(
                label: 'TIME',
                value: _formatTime(_ride.departureTime),
                centered: true,
              ),
            ),

            _verticalDivider(),

            Expanded(
              child: _DepartureItem(
                label: 'RIDERS',
                value: '${_ride.members.length}/${_ride.maxMembers}',
                centered: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(height: 1, color: Colors.white.withValues(alpha: 0.13)),

        const SizedBox(height: 17),

        _buildScheduleLocation(
          icon: CupertinoIcons.location,
          label: 'MEETING POINT',
          value: _ride.meetingPoint,
        ),

        if (_ride.returnTime != null) ...[
          const SizedBox(height: 15),

          _buildScheduleLocation(
            icon: CupertinoIcons.arrow_turn_up_left,
            label: 'RETURN',
            value: _formatDateTime(_ride.returnTime!),
          ),
        ],
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 38,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }

  Widget _buildScheduleLocation({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8E908C)),

        const SizedBox(width: 9),

        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7F817D),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Text(
            value.trim().isEmpty ? '--' : value,
            textAlign: TextAlign.right,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD1D2CE),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE3E4E0),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),

        if (trailing != null) ...[
          const SizedBox(width: 9),

          Text(
            trailing,
            style: const TextStyle(
              color: Color(0xFF686A67),
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ],

        const SizedBox(width: 13),

        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }

  Widget _buildRoute() {
    final waypoints = _sortedWaypoints;

    return Column(
      children: [
        _RoutePoint(
          number: '01',
          title: _ride.meetingPoint,
          subtitle: 'MEETING POINT',
          icon: CupertinoIcons.location_solid,
          isDestination: false,
        ),

        for (int i = 0; i < waypoints.length; i++) ...[
          const _RouteConnector(),

          _RoutePoint(
            number: (i + 2).toString().padLeft(2, '0'),
            title: waypoints[i].title.trim().isEmpty
                ? waypoints[i].locationName
                : waypoints[i].title,
            subtitle: _waypointSubtitle(waypoints[i]),
            icon: waypoints[i].categoryIcon,
            isDestination: false,
          ),
        ],

        const _RouteConnector(),

        _RoutePoint(
          number: (waypoints.length + 2).toString().padLeft(2, '0'),
          title: _ride.destination,
          subtitle: 'DESTINATION',
          icon: CupertinoIcons.flag_fill,
          isDestination: true,
        ),
      ],
    );
  }

  Widget _buildTripInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TripMetric(
                label: 'DISTANCE',
                value: _ride.routeDistanceKm == null
                    ? '--'
                    : '${_ride.routeDistanceKm!.toStringAsFixed(1)} KM',
              ),
            ),

            _verticalDivider(),

            Expanded(
              child: _TripMetric(
                label: 'TRAVEL TIME',
                value: _ride.routeDurationMinutes == null
                    ? '--'
                    : _formatDuration(_ride.routeDurationMinutes!),
                centered: true,
              ),
            ),

            _verticalDivider(),

            Expanded(
              child: _TripMetric(
                label: 'EST. COST',
                value: _formatCost(_ride.estimatedCost),
                centered: true,
              ),
            ),
          ],
        ),

        if (_ride.returnTime != null) ...[
          const SizedBox(height: 18),

          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                CupertinoIcons.arrow_2_circlepath,
                size: 14,
                color: Color(0xFF777975),
              ),

              const SizedBox(width: 9),

              const Text(
                'RETURN',
                style: TextStyle(
                  color: Color(0xFF777975),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),

              const Spacer(),

              Text(
                _formatDateTime(_ride.returnTime!),
                style: const TextStyle(
                  color: Color(0xFFD1D2CE),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDescription() {
    if (_ride.description.trim().isEmpty) {
      return const Text(
        'No description provided for this expedition.',
        style: TextStyle(color: Color(0xFF777975), fontSize: 12, height: 1.6),
      );
    }

    return Text(
      _ride.description.trim(),
      style: const TextStyle(
        color: Color(0xFFD0D1CD),
        fontSize: 14,
        fontWeight: FontWeight.w300,
        height: 1.65,
        letterSpacing: 0.05,
      ),
    );
  }

  Widget _buildRiders() {
    if (_ride.members.isEmpty) {
      return const Text(
        'NO RIDERS HAVE JOINED YET.',
        style: TextStyle(
          color: Color(0xFF777975),
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
        ),
      );
    }

    return Column(
      children: _ride.members.asMap().entries.map((entry) {
        final index = entry.key;

        final uid = entry.value;

        final isLeader = uid == _ride.leaderUid;

        final details = _ride.memberDetailsFor(uid);

        String name;

        if (details != null &&
            details.displayName.trim().isNotEmpty &&
            details.displayName.trim() != 'Rider') {
          name = details.displayName.trim();
        } else if (isLeader && _ride.leaderName.trim().isNotEmpty) {
          name = _ride.leaderName.trim();
        } else {
          name = 'Unknown rider';
        }

        String? photo;

        final storedPhoto = details?.photoUrl?.trim();

        if (storedPhoto != null && storedPhoto.isNotEmpty) {
          photo = storedPhoto;
        } else if (isLeader) {
          photo = _ride.leaderPhotoUrl;
        }

        return _MinimalRiderRow(
          name: name,
          photoUrl: photo,
          isLeader: isLeader,
          index: index,
        );
      }).toList(),
    );
  }

  Widget _buildRequestedRiders() {
    if (_ride.joinRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _ride.joinRequests.asMap().entries.map((entry) {
        final index = entry.key;

        final uid = entry.value;

        final request = _ride.requestDetailsFor(uid);

        String name = 'Unknown rider';

        String? photo;

        if (request != null) {
          final requestName = request.displayName.trim();

          if (requestName.isNotEmpty && requestName != 'Rider') {
            name = requestName;
          }

          final requestPhoto = request.photoUrl?.trim();

          if (requestPhoto != null && requestPhoto.isNotEmpty) {
            photo = requestPhoto;
          }
        }

        return _RequestedRiderRow(
          name: name,
          photoUrl: photo,
          index: index,
          processing: _processingRequestUid == uid,
          onAccept: () => _acceptJoinRequest(uid),
          onReject: () => _rejectJoinRequest(uid),
        );
      }).toList(),
    );
  }

  Widget _buildDestination() {
    final latitude = _ride.destinationLatitude;

    final longitude = _ride.destinationLongitude;

    if (latitude == null || longitude == null) {
      return Text(
        _ride.destination,
        style: const TextStyle(
          color: Color(0xFFF0F1ED),
          fontSize: 20,
          fontWeight: FontWeight.w300,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _ride.destination,
          style: const TextStyle(
            color: Color(0xFFF0F1ED),
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Icon(
              CupertinoIcons.location,
              color: Color(0xFF777975),
              size: 12,
            ),

            const SizedBox(width: 7),

            Text(
              '${latitude.toStringAsFixed(5)}, '
              '${longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                color: Color(0xFF858783),
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (_isLeader) {
      if (_ride.status == 'published') {
        return Column(
          children: [
            _PrimaryActionButton(
              label: 'START EXPEDITION',
              icon: CupertinoIcons.arrow_right,
              loading: _starting,
              onPressed: _startExpedition,
            ),

            const SizedBox(height: 10),

            _QuietDangerAction(
              label: 'CANCEL EXPEDITION',
              loading: _cancelling,
              onPressed: _cancelExpedition,
            ),
          ],
        );
      }

      if (_ride.status == 'active') {
        return _ActiveActionButton(onPressed: _openExpeditionMap);
      }

      return _InactiveAction(
        label: _ride.status == 'completed'
            ? 'EXPEDITION COMPLETED'
            : 'EXPEDITION CANCELLED',
        color: _ride.status == 'completed'
            ? const Color(0xFF858783)
            : const Color(0xFFD06A6A),
      );
    }

    if (_ride.status == 'cancelled') {
      return const _InactiveAction(
        label: 'EXPEDITION CANCELLED',
        color: Color(0xFFD06A6A),
      );
    }

    if (_ride.status == 'completed') {
      return const _InactiveAction(
        label: 'EXPEDITION COMPLETED',
        color: Color(0xFF858783),
      );
    }

    if (_ride.status == 'active') {
      if (_isMember) {
        return _PrimaryActionButton(
          label: 'OPEN EXPEDITION',
          icon: CupertinoIcons.arrow_right,
          onPressed: _openExpeditionMap,
        );
      }

      return const _InactiveAction(
        label: 'EXPEDITION ALREADY ACTIVE',
        color: Color(0xFF858783),
      );
    }

    if (_isMember) {
      return const _InactiveAction(
        label: 'YOU ARE JOINED',
        color: Color(0xFF52C47C),
      );
    }

    if (_hasRequested) {
      return const _InactiveAction(
        label: 'JOIN REQUEST SENT',
        color: Color(0xFFD0D1CD),
      );
    }

    if (_ride.isFull) {
      return const _InactiveAction(
        label: 'EXPEDITION FULL',
        color: Color(0xFF858783),
      );
    }

    if (_canRequestToJoin) {
      return _PrimaryActionButton(
        label: 'REQUEST TO JOIN',
        icon: CupertinoIcons.arrow_right,
        loading: _requesting,
        onPressed: _requestToJoin,
      );
    }

    return const _InactiveAction(
      label: 'JOINING UNAVAILABLE',
      color: Color(0xFF777975),
    );
  }

  Widget _buildRideIdentifier() {
    return Text(
      '${_ride.rideId}  ·  '
      '${_ride.visibility.toUpperCase()}',
      style: const TextStyle(
        color: Color(0xFF555754),
        fontSize: 7,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDestination,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDestination
                        ? const Color(0xFFBFC0BC)
                        : const Color(0xFF3A3C39),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 12, color: const Color(0xFFD8D9D5)),
              ),

              const SizedBox(height: 5),

              Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF555754),
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trim().isEmpty ? 'Unnamed location' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE5E6E2),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF777975),
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(width: 1, height: 27, color: const Color(0xFF30322F)),
      ),
    );
  }
}

class _TripMetric extends StatelessWidget {
  const _TripMetric({
    required this.label,
    required this.value,
    this.centered = false,
  });

  final String label;
  final String value;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF777975),
            fontSize: 7,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE0E1DD),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DepartureItem extends StatelessWidget {
  const _DepartureItem({
    required this.label,
    required this.value,
    this.centered = false,
  });

  final String label;
  final String value;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF777975),
            fontSize: 7,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE0E1DD),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _MinimalRiderRow extends StatelessWidget {
  const _MinimalRiderRow({
    required this.name,
    required this.photoUrl,
    required this.isLeader,
    required this.index,
  });

  final String name;
  final String? photoUrl;
  final bool isLeader;
  final int index;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x20232423), width: 1)),
      ),
      child: Row(
        children: [
          _RiderAvatar(
            name: name,
            initial: initial,
            photoUrl: photoUrl,
            isLeader: isLeader,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE5E6E2),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  isLeader
                      ? 'RIDE LEADER'
                      : 'RIDER ${(index + 1).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFF777975),
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),

          if (isLeader)
            const Text(
              'LEADER',
              style: TextStyle(
                color: Color(0xFF8E908C),
                fontSize: 7,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestedRiderRow extends StatelessWidget {
  const _RequestedRiderRow({
    required this.name,
    required this.photoUrl,
    required this.index,
    required this.processing,
    required this.onAccept,
    required this.onReject,
  });

  final String name;
  final String? photoUrl;
  final int index;
  final bool processing;

  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x20232423), width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _RiderAvatar(
                name: name,
                initial: initial,
                photoUrl: photoUrl,
                isLeader: false,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE5E6E2),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'REQUEST ${(index + 1).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Color(0xFF777975),
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                'PENDING',
                style: TextStyle(
                  color: Color(0xFFD0D1CD),
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          if (processing)
            const SizedBox(
              height: 34,
              child: Center(
                child: SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.2,
                    color: Color(0xFFD8D9D5),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: TextButton(
                      onPressed: onReject,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB95F5F),
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(color: Color(0x332A2A2A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'REJECT',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: TextButton(
                      onPressed: onAccept,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF080909),
                        backgroundColor: const Color(0xFFF1F2EE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'ACCEPT',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RiderAvatar extends StatelessWidget {
  const _RiderAvatar({
    required this.name,
    required this.initial,
    required this.photoUrl,
    required this.isLeader,
  });

  final String name;
  final String initial;
  final String? photoUrl;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isLeader ? const Color(0xFF777975) : const Color(0xFF303230),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.trim().isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _fallback();
                },
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF171817),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFFE7E8E4),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBFC0BC),
        fontSize: 8,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: Icon(icon, color: const Color(0xFFE8E9E5), size: 18),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF1F2EE),
          foregroundColor: const Color(0xFF080909),
          disabledBackgroundColor: const Color(0xFF777975),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: loading
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 1.3,
                  color: Color(0xFF080909),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),

                  const SizedBox(width: 9),

                  Icon(icon, size: 12),
                ],
              ),
      ),
    );
  }
}

class _ActiveActionButton extends StatelessWidget {
  const _ActiveActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF52C47C),
          foregroundColor: const Color(0xFF080909),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'OPEN EXPEDITION',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
            SizedBox(width: 9),
            Icon(CupertinoIcons.arrow_right, size: 12),
          ],
        ),
      ),
    );
  }
}

class _QuietDangerAction extends StatelessWidget {
  const _QuietDangerAction({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFB95F5F),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.2,
                  color: Color(0xFFB95F5F),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ),
      ),
    );
  }
}

class _InactiveAction extends StatelessWidget {
  const _InactiveAction({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(width: 9),

          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
