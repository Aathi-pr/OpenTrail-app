import 'package:open_trail/features/weather/weather_condition.dart';

class WeatherData {
  const WeatherData({
    required this.condition,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.location,
    required this.description,
  });

  final WeatherCondition condition;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String location;
  final String description;
}
