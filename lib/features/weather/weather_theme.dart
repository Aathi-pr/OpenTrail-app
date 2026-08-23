import 'package:flutter/material.dart';
import 'weather_condition.dart';

class WeatherTheme {
  final List<Color> gradientColors;
  final Alignment begin;
  final Alignment end;
  final Color ambientSweep;
  final bool showRain;
  final bool showSnow;
  final bool showThunder;
  final bool showClouds;
  final bool showSunGlow;
  final bool showMoonGlow;
  final bool showFog;
  final bool showWind;

  const WeatherTheme({
    required this.gradientColors,
    this.begin = Alignment.topRight,
    this.end = Alignment.bottomLeft,
    required this.ambientSweep,
    this.showRain = false,
    this.showSnow = false,
    this.showThunder = false,
    this.showClouds = false,
    this.showSunGlow = false,
    this.showMoonGlow = false,
    this.showFog = false,
    this.showWind = false,
  });

  static WeatherTheme of(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clearDay:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF3A1C00),
            Color(0xFF1E0E00),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x33FF9100),
          showSunGlow: true,
        );

      case WeatherCondition.clearDark:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1B202D),
            Color(0xFF10131C),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x222A2D34),
          showMoonGlow: true,
        );

      case WeatherCondition.partlyCloudyDay:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF2E2219),
            Color(0xFF18120D),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x2AFF9100),
          showSunGlow: true,
          showClouds: true,
        );

      case WeatherCondition.partlyCloudyNight:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF181F2B),
            Color(0xFF0F141D),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x223B4861),
          showMoonGlow: true,
          showClouds: true,
        );

      case WeatherCondition.cloudy:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1E282D),
            Color(0xFF11171A),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x2278909C),
          showClouds: true,
        );

      case WeatherCondition.overcast:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1A1E21),
            Color(0xFF0F1214),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x22546E7A),
          showClouds: true,
        );

      case WeatherCondition.drizzle:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1B242A),
            Color(0xFF10161A),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x22607D8B),
          showRain: true,
          showClouds: true,
        );

      case WeatherCondition.rainy:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1C252A),
            Color(0xFF10171A),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x2278909C),
          showRain: true,
          showClouds: true,
        );

      case WeatherCondition.heavyRain:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF131B21),
            Color(0xFF0B1014),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x33455A64),
          showRain: true,
          showClouds: true,
        );

      case WeatherCondition.thunderstorm:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1A122B),
            Color(0xFF0E0B1A),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x33512DA8),
          showRain: true,
          showThunder: true,
          showClouds: true,
        );

      case WeatherCondition.snowy:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1C2530),
            Color(0xFF10161D),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x2290CAF9),
          showSnow: true,
          showClouds: true,
        );

      case WeatherCondition.sleet:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1A232A),
            Color(0xFF0F151A),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x2280DEEA),
          showRain: true,
          showSnow: true,
          showClouds: true,
        );

      case WeatherCondition.hail:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF181E24),
            Color(0xFF0E1216),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x33B0BEC5),
          showRain: true,
          showSnow: true,
          showThunder: true,
          showClouds: true,
        );

      case WeatherCondition.foggy:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF222629),
            Color(0xFF141719),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x229E9E9E),
          showFog: true,
          showClouds: true,
        );

      case WeatherCondition.windy:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1A262B),
            Color(0xFF0F171A),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x2226A69A),
          showWind: true,
          showClouds: true,
        );

      case WeatherCondition.hazy:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF28201A),
            Color(0xFF16120E),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x22BCAAA4),
          showFog: true,
        );
    }
  }
}
