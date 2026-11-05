import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skycast/models/weather_models.dart';
import 'package:skycast/providers/weather_provider.dart';
import 'package:skycast/screens/forecast_detail_screen.dart';

void main() {
  testWidgets(
    'forecast screen clearly switches between daily and hourly views',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(),
          child: MaterialApp(
            home: ForecastDetailScreen(weather: _sampleWeather()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5-day forecast'), findsOneWidget);
      expect(find.text('Daily details'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Hourly'));
      await tester.pumpAndSettle();

      expect(find.text('Hourly forecast'), findsOneWidget);
      expect(find.text('Next hours'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

WeatherSnapshot _sampleWeather() {
  final now = DateTime(2026, 11, 5, 9);
  return WeatherSnapshot(
    cityName: 'Guntur',
    country: 'India',
    latitude: 16.3,
    longitude: 80.4,
    currentTime: now,
    temperature: 29,
    feelsLike: 31,
    humidity: 65,
    windSpeed: 10,
    windDirection: 90,
    precipitation: 0,
    weatherCode: 2,
    sunrise: DateTime(2026, 11, 5, 6),
    sunset: DateTime(2026, 11, 5, 18),
    uvIndex: 4,
    pressure: 1012,
    visibility: 10000,
    hourlyForecast: List.generate(
      12,
      (index) => WeatherHour(
        time: now.add(Duration(hours: index)),
        temperature: 24 + index * 0.5,
        precipitationProbability: 5,
        weatherCode: 2,
      ),
    ),
    dailyForecast: List.generate(
      5,
      (index) => WeatherDay(
        date: now.add(Duration(days: index)),
        minTemperature: 22 + index.toDouble(),
        maxTemperature: 30 + index.toDouble(),
        precipitationProbability: 10,
        weatherCode: 2,
        maxWindSpeed: 12,
      ),
    ),
  );
}
