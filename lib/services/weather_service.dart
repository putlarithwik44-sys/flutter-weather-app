import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_models.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  static const String _geocodingBase =
      'https://geocoding-api.open-meteo.com/v1';
  static const String _forecastBase = 'https://api.open-meteo.com/v1';
  final http.Client _client;

  Future<List<CitySearchResult>> searchCities(String query) async {
    if (query.trim().length < 2) return const [];
    final normalizedQuery = query.trim().toLowerCase();

    final uri = Uri.parse('$_geocodingBase/search').replace(
      queryParameters: {
        'name': query.trim(),
        'count': '15',
        'language': 'en',
        'format': 'json',
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw WeatherApiException('City search is unavailable. Try again.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? const [])
        .map((item) => CitySearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
    final rankedResults = results.asMap().entries.toList();
    rankedResults.sort((a, b) {
      int rank(CitySearchResult city) {
        final name = city.name.toLowerCase();
        if (name == normalizedQuery) return 0;
        if (name.startsWith(normalizedQuery)) return 1;
        if (name.contains(normalizedQuery)) return 2;
        return 3;
      }

      final nameOrder = rank(a.value).compareTo(rank(b.value));
      return nameOrder == 0 ? a.key.compareTo(b.key) : nameOrder;
    });
    return rankedResults.map((entry) => entry.value).toList();
  }

  Future<WeatherSnapshot> fetchWeatherForCoordinates({
    required double latitude,
    required double longitude,
    required String cityName,
    required String country,
  }) async {
    final uri = Uri.parse('$_forecastBase/forecast').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,visibility,uv_index',
        'hourly': 'temperature_2m,weather_code,precipitation_probability',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,sunrise,sunset',
        'timezone': 'auto',
        'forecast_days': '7',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw WeatherApiException(
        'Weather service returned ${response.statusCode}.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>? ?? const {};
    final hourly = data['hourly'] as Map<String, dynamic>? ?? const {};
    final daily = data['daily'] as Map<String, dynamic>? ?? const {};

    final hourlyTimes = _dateTimes(hourly['time']);
    final hourlyTemps = _numbers(hourly['temperature_2m']);
    final hourlyRain = _numbers(hourly['precipitation_probability']);
    final hourlyCodes = _integers(hourly['weather_code']);
    final dailyTimes = _dateTimes(daily['time']);
    final dailyMax = _numbers(daily['temperature_2m_max']);
    final dailyMin = _numbers(daily['temperature_2m_min']);
    final dailyRain = _numbers(daily['precipitation_probability_max']);
    final dailyWind = _numbers(daily['wind_speed_10m_max']);
    final dailyCodes = _integers(daily['weather_code']);
    final sunriseTimes = _dateTimes(daily['sunrise']);
    final sunsetTimes = _dateTimes(daily['sunset']);

    if (hourlyTimes.isEmpty ||
        dailyTimes.isEmpty ||
        hourlyTemps.length != hourlyTimes.length ||
        dailyMax.length != dailyTimes.length ||
        dailyMin.length != dailyTimes.length) {
      throw WeatherApiException(
        'Weather service returned incomplete forecast data.',
      );
    }

    return WeatherSnapshot(
      cityName: cityName,
      country: country,
      latitude: latitude,
      longitude: longitude,
      currentTime:
          DateTime.tryParse((current['time'] ?? '').toString()) ??
          DateTime.now(),
      temperature: _number(current['temperature_2m']),
      feelsLike: _number(current['apparent_temperature']),
      humidity: _number(current['relative_humidity_2m']),
      windSpeed: _number(current['wind_speed_10m']),
      windDirection: _number(current['wind_direction_10m']),
      precipitation: _number(current['precipitation']),
      weatherCode: _integer(current['weather_code']),
      sunrise: sunriseTimes.isNotEmpty ? sunriseTimes.first : DateTime.now(),
      sunset: sunsetTimes.isNotEmpty ? sunsetTimes.first : DateTime.now(),
      uvIndex: _number(current['uv_index']),
      pressure: _number(current['surface_pressure']),
      visibility: _number(current['visibility']),
      hourlyForecast: List.generate(
        hourlyTimes.length,
        (index) => WeatherHour(
          time: hourlyTimes[index],
          temperature: hourlyTemps[index],
          precipitationProbability: _at(hourlyRain, index),
          weatherCode: _atInt(hourlyCodes, index),
        ),
      ),
      dailyForecast: List.generate(
        dailyTimes.length,
        (index) => WeatherDay(
          date: dailyTimes[index],
          minTemperature: dailyMin[index],
          maxTemperature: dailyMax[index],
          precipitationProbability: _at(dailyRain, index),
          weatherCode: _atInt(dailyCodes, index),
          maxWindSpeed: _at(dailyWind, index),
        ),
      ),
    );
  }

  static List<double> _numbers(dynamic value) =>
      (value as List<dynamic>? ?? const [])
          .map((item) => item is num ? item.toDouble() : 0.0)
          .toList();

  static List<int> _integers(dynamic value) =>
      (value as List<dynamic>? ?? const [])
          .map((item) => item is num ? item.toInt() : 0)
          .toList();

  static List<DateTime> _dateTimes(dynamic value) =>
      (value as List<dynamic>? ?? const [])
          .map((item) => DateTime.tryParse(item.toString()))
          .whereType<DateTime>()
          .toList();

  static double _number(dynamic value) => value is num ? value.toDouble() : 0;
  static int _integer(dynamic value) => value is num ? value.toInt() : 0;
  static double _at(List<double> values, int index) =>
      index < values.length ? values[index] : 0;
  static int _atInt(List<int> values, int index) =>
      index < values.length ? values[index] : 0;
}

class WeatherApiException implements Exception {
  const WeatherApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
