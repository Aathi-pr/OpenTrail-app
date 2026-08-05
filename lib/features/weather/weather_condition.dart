enum WeatherCondition {
  // Clear
  clearDay,
  clearDark,

  // Clouds
  partlyCloudyDay,
  partlyCloudyNight,
  cloudy,
  overcast,

  // Rain
  drizzle,
  rainy,
  heavyRain,
  thunderstorm,

  // Winter
  snowy,
  sleet,
  hail,

  // Atmospheric
  foggy,
  windy,
  hazy;

  /// Helper to check if night-time visual rules apply
  bool get isNight => this == WeatherCondition.clearDark ||
                      this == WeatherCondition.partlyCloudyNight;

  /// Helper to check if active precipitation is falling
  bool get hasPrecipitation => const {
        drizzle,
        rainy,
        heavyRain,
        thunderstorm,
        snowy,
        sleet,
        hail,
      }.contains(this);
}
