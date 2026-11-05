import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skycast/models/weather_models.dart';
import 'package:skycast/providers/weather_provider.dart';
import 'package:skycast/screens/saved_cities_screen.dart';

void main() {
  testWidgets('saved city cards fit on narrow phone screens', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = _TestWeatherProvider()
      ..savedCities = [
        SavedCity(
          id: 1254757,
          name: 'Tenali',
          country: 'India',
          countryCode: 'IN',
          admin1: 'Andhra Pradesh',
          admin2: 'Guntur District',
          latitude: 16.24253,
          longitude: 80.63982,
          isFavorite: false,
          temperature: 29,
          weatherCode: 2,
          lastUpdated: DateTime(2026, 11, 5, 9),
        ),
      ];

    addTearDown(provider.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<WeatherProvider>.value(
        value: provider,
        child: MaterialApp(home: SavedCitiesScreen(onCitySelected: () {})),
      ),
    );
    await tester.pump();

    expect(find.text('Tenali'), findsOneWidget);
    expect(find.textContaining('Guntur District'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestWeatherProvider extends WeatherProvider {
  @override
  Future<void> initialize() async {}
}
