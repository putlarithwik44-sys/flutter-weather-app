class CitySearchResult {
  const CitySearchResult({
    required this.id,
    required this.name,
    required this.country,
    required this.admin1,
    required this.latitude,
    required this.longitude,
    this.admin2 = '',
    this.countryCode = '',
  });

  final int id;
  final String name;
  final String country;
  final String admin1;
  final double latitude;
  final double longitude;
  final String admin2;
  final String countryCode;

  String get displayName =>
      [name, admin2, admin1, country].where((e) => e.isNotEmpty).join(', ');

  factory CitySearchResult.fromJson(Map<String, dynamic> json) {
    return CitySearchResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      admin1: (json['admin1'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      admin2: (json['admin2'] ?? '').toString(),
      countryCode: (json['country_code'] ?? '').toString(),
    );
  }
}

class WeatherHour {
  const WeatherHour({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  final DateTime time;
  final double temperature;
  final double precipitationProbability;
  final int weatherCode;
}

class WeatherDay {
  const WeatherDay({
    required this.date,
    required this.minTemperature,
    required this.maxTemperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.maxWindSpeed,
  });

  final DateTime date;
  final double minTemperature;
  final double maxTemperature;
  final double precipitationProbability;
  final int weatherCode;
  final double maxWindSpeed;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.cityName,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.currentTime,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.precipitation,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
    required this.uvIndex,
    required this.pressure,
    required this.visibility,
    required this.hourlyForecast,
    required this.dailyForecast,
  });

  final String cityName;
  final String country;
  final double latitude;
  final double longitude;
  final DateTime currentTime;
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final double windDirection;
  final double precipitation;
  final int weatherCode;
  final DateTime sunrise;
  final DateTime sunset;
  final double uvIndex;
  final double pressure;
  final double visibility;
  final List<WeatherHour> hourlyForecast;
  final List<WeatherDay> dailyForecast;
}

class SavedCity {
  const SavedCity({
    required this.id,
    required this.name,
    required this.country,
    required this.admin1,
    required this.latitude,
    required this.longitude,
    required this.isFavorite,
    required this.temperature,
    required this.weatherCode,
    required this.lastUpdated,
    this.admin2 = '',
    this.countryCode = '',
  });

  final int id;
  final String name;
  final String country;
  final String admin1;
  final double latitude;
  final double longitude;
  final bool isFavorite;
  final double temperature;
  final int weatherCode;
  final DateTime lastUpdated;
  final String admin2;
  final String countryCode;

  String get displayName =>
      [name, admin2, admin1, country].where((e) => e.isNotEmpty).join(', ');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'admin1': admin1,
    'admin2': admin2,
    'countryCode': countryCode,
    'latitude': latitude,
    'longitude': longitude,
    'isFavorite': isFavorite,
    'temperature': temperature,
    'weatherCode': weatherCode,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory SavedCity.fromJson(Map<String, dynamic> json) => SavedCity(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: (json['name'] ?? '').toString(),
    country: (json['country'] ?? '').toString(),
    admin1: (json['admin1'] ?? '').toString(),
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    isFavorite: json['isFavorite'] as bool? ?? false,
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
    weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 0,
    lastUpdated:
        DateTime.tryParse((json['lastUpdated'] ?? '').toString()) ??
        DateTime.now(),
    admin2: (json['admin2'] ?? '').toString(),
    countryCode: (json['countryCode'] ?? '').toString(),
  );
}

enum TemperatureUnit { celsius, fahrenheit }

enum WindUnit { kmh, mph, ms }

enum AppThemeMode { light, dark, system }
