import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide LatLngTween;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_trail/features/maps/helpers/latlng_tween.dart';
import 'package:open_trail/features/maps/helpers/location_filter.dart';
import 'package:open_trail/features/maps/widgets/animated_user_marker.dart';

class UserMarkerLayer extends StatefulWidget {
  const UserMarkerLayer({
    super.key,
    required this.currentPosition,
    required this.navigationPosition,
    required this.userName,
    required this.isLeader,
  });

  final Position? currentPosition;
  final Position? navigationPosition;
  final String userName;
  final bool isLeader;

  @override
  State<UserMarkerLayer> createState() => _UserMarkerLayerState();
}

class _UserMarkerLayerState extends State<UserMarkerLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final LocationFilter _filter = LocationFilter();
  final Distance _distance = const Distance();

  LatLngTween? _positionTween;

  LatLng? _currentLatLng;
  LatLng? _targetLatLng;

  double _currentHeading = 0;
  double _targetHeading = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..value = 1;

    final position = widget.navigationPosition ?? widget.currentPosition;

    if (position == null) return;

    final initial = LatLng(position.latitude, position.longitude);

    _currentLatLng = initial;
    _targetLatLng = initial;

    _positionTween = LatLngTween(begin: initial, end: initial);

    _currentHeading = position.heading;
    _targetHeading = position.heading;
  }

  Duration _animationDuration(double speed) {
    if (speed < 1) {
      return const Duration(milliseconds: 450);
    }

    if (speed < 5) {
      return const Duration(milliseconds: 300);
    }

    if (speed < 15) {
      return const Duration(milliseconds: 180);
    }

    return const Duration(milliseconds: 120);
  }

  @override
  void didUpdateWidget(covariant UserMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final position = widget.navigationPosition ?? widget.currentPosition;

    if (position == null) return;

    final filtered = _filter.filter(
      LatLng(position.latitude, position.longitude),
    );

    if (_targetLatLng == null) {
      _currentLatLng = filtered;
      _targetLatLng = filtered;

      _positionTween = LatLngTween(begin: filtered, end: filtered);

      return;
    }

    // Ignore GPS drift (< 2.5 m)
    if (_distance(filtered, _targetLatLng!) < 2.5 &&
        (position.heading - _targetHeading).abs() < 2) {
      return;
    }

    _currentLatLng =
        _positionTween?.transform(_controller.value) ?? _targetLatLng;

    _currentHeading = _lerpHeading(
      _currentHeading,
      _targetHeading,
      _controller.value,
    );

    _targetLatLng = filtered;
    _targetHeading = position.heading;

    _positionTween = LatLngTween(begin: _currentLatLng!, end: _targetLatLng!);

    _controller.duration = _animationDuration(position.speed);

    _controller
      ..stop()
      ..reset()
      ..forward();
  }

  double _lerpHeading(double from, double to, double t) {
    final delta = ((to - from + 540) % 360) - 180;
    return (from + delta * t + 360) % 360;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_positionTween == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animatedPosition = _positionTween!.transform(_controller.value);

        final animatedHeading = _lerpHeading(
          _currentHeading,
          _targetHeading,
          _controller.value,
        );

        return MarkerLayer(
          markers: [
            Marker(
              point: animatedPosition,
              width: 120,
              height: 80,
              alignment: Alignment.topCenter,
              child: AnimatedUserMarker(
                position: animatedPosition,
                heading: animatedHeading,
                userName: widget.userName,
                isLeader: widget.isLeader,
              ),
            ),
          ],
        );
      },
    );
  }
}

