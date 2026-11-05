import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skycast/models/weather_models.dart';
import 'package:skycast/services/weather_service.dart';

void main() {
  test(
    'city search prioritizes exact names and keeps region details',
    () async {
      final service = WeatherService(
        client: MockClient((request) async {
          expect(request.url.queryParameters['name'], 'Guntur');
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 3,
                  'name': 'Guntur Junction',
                  'country': 'India',
                  'admin1': 'Andhra Pradesh',
                  'latitude': 16.3,
                  'longitude': 80.4,
                },
                {
                  'id': 1,
                  'name': 'Guntur',
                  'country': 'India',
                  'country_code': 'IN',
                  'admin1': 'Andhra Pradesh',
                  'admin2': 'Guntur district',
                  'latitude': 16.3,
                  'longitude': 80.4,
                },
              ],
            }),
            200,
          );
        }),
      );

      final results = await service.searchCities(' Guntur ');

      expect(results.first.name, 'Guntur');
      expect(
        results.first.displayName,
        'Guntur, Guntur district, Andhra Pradesh, India',
      );
      expect(results.first.countryCode, 'IN');
      expect(results.last.name, 'Guntur Junction');
    },
  );

  test('corrects the geocoder spelling for Tenali, Andhra Pradesh', () async {
    final service = WeatherService(
      client: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'results': [
                {
                  'id': 1254757,
                  'name': 'Thenali',
                  'country': 'India',
                  'country_code': 'IN',
                  'admin1': 'Andhra Pradesh',
                  'admin2': 'Guntūr District',
                  'latitude': 16.24253,
                  'longitude': 80.63982,
                },
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final results = await service.searchCities('Tenali');
    final savedCity = SavedCity.fromJson({
      'id': 1254757,
      'name': 'Thenali',
      'country': 'India',
      'countryCode': 'IN',
      'admin1': 'Andhra Pradesh',
    });

    expect(results.single.name, 'Tenali');
    expect(
      results.single.displayName,
      'Tenali, Guntūr District, Andhra Pradesh, India',
    );
    expect(savedCity.name, 'Tenali');
  });

  test('reuses recent city search results', () async {
    var requestCount = 0;
    final service = WeatherService(
      client: MockClient((request) async {
        requestCount++;
        return http.Response('{"results":[]}', 200);
      }),
    );

    await service.searchCities('Tenali');
    await service.searchCities(' tenali ');

    expect(requestCount, 1);
  });
}
