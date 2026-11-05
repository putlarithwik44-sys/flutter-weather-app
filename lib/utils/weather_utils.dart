import 'package:flutter/material.dart';

import '../models/weather_models.dart';

class WeatherUtils {
  static String getWeatherLabel(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return 'Rain';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'Snow';
      case 80:
      case 81:
      case 82:
        return 'Heavy rain';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Weather';
    }
  }

  static IconData getWeatherIcon(int code, {bool isNight = false}) {
    switch (code) {
      case 0:
        return isNight ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined;
      case 1:
      case 2:
      case 3:
        return Icons.cloud_queue_outlined;
      case 45:
      case 48:
        return Icons.cloud_outlined;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return Icons.umbrella_outlined;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_outlined;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_outlined;
      default:
        return Icons.wb_cloudy_outlined;
    }
  }

  static double convertTemperature(double celsius, TemperatureUnit unit) {
    switch (unit) {
      case TemperatureUnit.celsius:
        return celsius;
      case TemperatureUnit.fahrenheit:
        return (celsius * 9 / 5) + 32;
    }
  }

  static String formatTemperature(double celsius, TemperatureUnit unit) {
    final value = convertTemperature(celsius, unit);
    return '${value.round()}°${unit == TemperatureUnit.fahrenheit ? 'F' : 'C'}';
  }

  static String formatWind(double kmPerHour, WindUnit unit) {
    switch (unit) {
      case WindUnit.kmh:
        return '${kmPerHour.round()} km/h';
      case WindUnit.mph:
        return '${(kmPerHour * 0.621371).round()} mph';
      case WindUnit.ms:
        return '${(kmPerHour * 0.277778).toStringAsFixed(1)} m/s';
    }
  }

  static String getWindDirection(double degrees) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees / 45) + 0.5).floor() % 8;
    return labels[index];
  }

  static String formatDate(DateTime dt) => '${dt.day}/${dt.month}';

  static String formatWeekday(DateTime dt) => _weekdays[dt.weekday % 7];

  static String formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String formatDateLong(DateTime dt) => '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  static bool isNight(DateTime now, DateTime sunrise, DateTime sunset) {
    return now.isBefore(sunrise) || now.isAfter(sunset);
  }

  static const List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
