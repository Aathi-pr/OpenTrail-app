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
      // --- CLEAR STATES ---
      case WeatherCondition.clearDay:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF3A1C00), // Soft Amber Warmth
            Color(0xFF1E0E00), // Warm Dark Shadow
            Color(0xFF0A0A0A), // Pitch Black Base
          ],
          ambientSweep: Color(0x33FF9100),
          showSunGlow: true,
        );

      case WeatherCondition.clearDark:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1B202D), // Deep Midnight Indigo Tint
            Color(0xFF10131C),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x222A2D34),
          showMoonGlow: true,
        );

      // --- CLOUD STATES ---
      case WeatherCondition.partlyCloudyDay:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF2E2219), // Dusky Amber Slate
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
            Color(0xFF181F2B), // Deep Cosmic Indigo
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
            Color(0xFF1E282D), // Soft Blue-Grey Tint
            Color(0xFF11171A),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x2278909C),
          showClouds: true,
        );

      case WeatherCondition.overcast:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1A1E21), // Muted Low-Light Lead
            Color(0xFF0F1214),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x22546E7A),
          showClouds: true,
        );

      // --- PRECIPITATION STATES ---
      case WeatherCondition.drizzle:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1B242A), // Soft Moist Slate
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
            Color(0xFF1C252A), // Slate Grey Gradient Top
            Color(0xFF10171A), // Dark Slate Shadow
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x2278909C),
          showRain: true,
          showClouds: true,
        );

      case WeatherCondition.heavyRain:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF131B21), // Deep Steel Dark
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
            Color(0xFF1A122B), // Storm Electric Indigo Top
            Color(0xFF0E0B1A), // Deep Storm Base
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x33512DA8),
          showRain: true,
          showThunder: true,
          showClouds: true,
        );

      // --- WINTER STATES ---
      case WeatherCondition.snowy:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF1C2530), // Cool Frost Tint
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
            Color(0xFF1A232A), // Icy Blue-Grey
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
            Color(0xFF181E24), // Harsh Cold Steel
            Color(0xFF0E1216),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x33B0BEC5),
          showRain: true,
          showSnow: true,
          showThunder: true,
          showClouds: true,
        );

      // --- ATMOSPHERIC STATES ---
      case WeatherCondition.foggy:
        return const WeatherTheme(
          gradientColors: [
            Color(0xFF222629), // Diffused Low-Contrast Grey
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
            Color(0xFF1A262B), // Crisp Aerodynamic Teal-Grey
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
            Color(0xFF28201A), // Warm Sepia-Dust Tint
            Color(0xFF16120E),
            Color(0xFF0A0A0A),
          ],
          ambientSweep: Color(0x22BCAAA4),
          showFog: true,
        );
    }
  }
}
