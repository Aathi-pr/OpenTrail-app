import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:open_trail/features/weather/painters/clouds_painter.dart';
import 'package:open_trail/features/weather/painters/fog_painter.dart';
import 'package:open_trail/features/weather/painters/glow_painter.dart';
import 'package:open_trail/features/weather/painters/rain_painter.dart';
import 'package:open_trail/features/weather/painters/snow_painter.dart';
import 'package:open_trail/features/weather/painters/thunder_painter.dart';
import 'package:open_trail/features/weather/painters/wind_painter.dart';
import 'package:open_trail/features/weather/weather_condition.dart';
import 'package:open_trail/features/weather/weather_theme.dart';

class DynamicWeatherBackground extends StatefulWidget {
  final WeatherCondition condition;

  const DynamicWeatherBackground({
    super.key,
    this.condition = WeatherCondition.clearDark,
  });

  @override
  State<DynamicWeatherBackground> createState() =>
      _DynamicWeatherBackgroundState();
}

class _DynamicWeatherBackgroundState extends State<DynamicWeatherBackground>
    with TickerProviderStateMixin {
  late AnimationController _flowController;
  late AnimationController _particleController;
  late AnimationController _thunderController;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _thunderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _triggerThunderLoop();
  }

  void _triggerThunderLoop() async {
    while (mounted) {
      await Future.delayed(Duration(seconds: 3 + _random.nextInt(6)));
      final theme = WeatherTheme.of(widget.condition);
      if (mounted && theme.showThunder) {
        await _thunderController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    _particleController.dispose();
    _thunderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = WeatherTheme.of(widget.condition);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _flowController,
        _particleController,
        _thunderController,
      ]),
      builder: (context, child) {
        final flowValue = _flowController.value;
        final angle = flowValue * 2 * math.pi;

        return Container(
          color: const Color(0xFF0A0A0A),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 420,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: [0, .65, 1],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.5 + (math.sin(angle) * 0.3), -1.0),
                        end: Alignment(-0.5 + (math.cos(angle) * 0.3), 1.0),
                        colors: theme.gradientColors,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(math.sin(angle) * 0.5, -1.0),
                      end: Alignment(math.cos(angle) * 0.5, 1.0),
                      colors: [theme.ambientSweep, Colors.transparent],
                    ),
                  ),
                ),
              ),

              if (theme.showSunGlow || theme.showMoonGlow)
                Positioned.fill(
                  child: CustomPaint(
                    painter: GlowPainter(
                      progress: flowValue,
                      isSun: theme.showSunGlow,
                    ),
                  ),
                ),

              if (theme.showFog)
                Positioned.fill(
                  child: CustomPaint(painter: FogPainter(progress: flowValue)),
                ),

              if (theme.showWind)
                Positioned.fill(
                  child: CustomPaint(painter: WindPainter(progress: flowValue)),
                ),

              if (theme.showClouds)
                Positioned.fill(
                  child: CustomPaint(
                    painter: CloudsPainter(progress: flowValue),
                  ),
                ),

              if (theme.showSnow)
                Positioned.fill(
                  child: CustomPaint(
                    painter: SnowPainter(progress: _particleController.value),
                  ),
                ),

              if (theme.showRain)
                Positioned.fill(
                  child: CustomPaint(
                    painter: RainPainter(
                      progress: _particleController.value,
                      isHeavy:
                          widget.condition == WeatherCondition.heavyRain ||
                          widget.condition == WeatherCondition.thunderstorm ||
                          widget.condition == WeatherCondition.hail,
                    ),
                  ),
                ),

              if (theme.showThunder)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ThunderPainter(progress: _thunderController.value),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
