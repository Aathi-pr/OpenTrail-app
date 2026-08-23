import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:open_trail/features/weather/weather_condition.dart';
import 'package:open_trail/features/weather/weather_data.dart';

class WeatherService {
  static final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  final Duration _cacheDuration;

  WeatherData? _cachedWeather;
  DateTime? _lastFetchTime;

  final Map<String, _WeatherCacheEntry> _destinationCache = {};

  WeatherService({Duration cacheDuration = const Duration(minutes: 15)})
    : _cacheDuration = cacheDuration;

  bool get _isCacheValid {
    if (_cachedWeather == null || _lastFetchTime == null) {
      return false;
    }

    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  void clearCache() {
    _cachedWeather = null;
    _lastFetchTime = null;
    _destinationCache.clear();
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
  }

  Future<WeatherData> fetchCurrentWeather({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedWeather!;
    }

    try {
      final position = await _determinePosition();

      final weather = await fetchWeatherForCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        forceRefresh: forceRefresh,
      );

      _cachedWeather = weather;
      _lastFetchTime = DateTime.now();

      return weather;
    } catch (e) {
      debugPrint('Weather Service Error: $e');

      return _cachedWeather ??
          const WeatherData(
            condition: WeatherCondition.clearDark,
            temperature: 0,
            feelsLike: 0,
            humidity: 0,
            location: 'Unknown',
            description: 'Unavailable',
          );
    }
  }

  Future<WeatherData> fetchWeatherForCoordinates({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '${latitude.toStringAsFixed(3)},'
        '${longitude.toStringAsFixed(3)}';

    final cached = _destinationCache[cacheKey];

    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheDuration) {
      return cached.weather;
    }

    try {
      if (_apiKey.isEmpty) {
        throw Exception('OPENWEATHER_API_KEY is not configured.');
      }

      final url = Uri.parse(
        '$_baseUrl'
        '?lat=$latitude'
        '&lon=$longitude'
        '&appid=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('OpenWeather request failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final weatherData = data['weather'][0] as Map<String, dynamic>;

      final conditionCode = weatherData['id'] as int;

      final icon = weatherData['icon'] as String;

      final windSpeed = (data['wind']['speed'] as num?)?.toDouble() ?? 0;

      final condition = _mapConditionCodeToEnum(
        code: conditionCode,
        icon: icon,
        windSpeed: windSpeed,
      );

      final weather = WeatherData(
        condition: condition,
        temperature: (data['main']['temp'] as num).toDouble() - 273.15,
        feelsLike: (data['main']['feels_like'] as num).toDouble() - 273.15,
        humidity: (data['main']['humidity'] as num).toInt(),
        location: data['name'] as String? ?? 'Unknown',
        description: weatherData['description'] as String? ?? 'Clear',
      );

      _destinationCache[cacheKey] = _WeatherCacheEntry(
        weather: weather,
        fetchedAt: DateTime.now(),
      );

      return weather;
    } catch (e) {
      debugPrint('Destination Weather Error: $e');

      return const WeatherData(
        condition: WeatherCondition.clearDark,
        temperature: 0,
        feelsLike: 0,
        humidity: 0,
        location: 'Unknown',
        description: 'Unavailable',
      );
    }
  }

  WeatherCondition _mapConditionCodeToEnum({
    required int code,
    required String icon,
    required double windSpeed,
  }) {
    final isNight = icon.endsWith('n');

    if (code == 771 || code == 781 || windSpeed > 10.8) {
      return WeatherCondition.windy;
    }

    if (code >= 200 && code < 300) {
      return WeatherCondition.thunderstorm;
    }

    if (code >= 300 && code < 400) {
      return WeatherCondition.drizzle;
    }

    if (code >= 500 && code < 600) {
      if (code == 511) {
        return WeatherCondition.sleet;
      }

      if (code == 502 ||
          code == 503 ||
          code == 504 ||
          code == 522 ||
          code == 531) {
        return WeatherCondition.heavyRain;
      }

      if (code == 500) {
        return WeatherCondition.drizzle;
      }

      return WeatherCondition.rainy;
    }

    if (code >= 600 && code < 700) {
      if (code >= 611 && code <= 616) {
        return WeatherCondition.sleet;
      }

      return WeatherCondition.snowy;
    }

    if (code >= 700 && code < 800) {
      if (code == 701 || code == 741) {
        return WeatherCondition.foggy;
      }

      return WeatherCondition.hazy;
    }

    if (code == 800) {
      return isNight ? WeatherCondition.clearDark : WeatherCondition.clearDay;
    }

    if (code == 801 || code == 802) {
      return isNight
          ? WeatherCondition.partlyCloudyNight
          : WeatherCondition.partlyCloudyDay;
    }

    if (code == 803) {
      return WeatherCondition.cloudy;
    }

    if (code == 804) {
      return WeatherCondition.overcast;
    }

    return isNight ? WeatherCondition.clearDark : WeatherCondition.clearDay;
  }
}

class _WeatherCacheEntry {
  const _WeatherCacheEntry({required this.weather, required this.fetchedAt});

  final WeatherData weather;
  final DateTime fetchedAt;
}
