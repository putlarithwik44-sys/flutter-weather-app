import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
}
