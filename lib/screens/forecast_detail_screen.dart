import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/weather_models.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';

class ForecastDetailScreen extends StatefulWidget {
  const ForecastDetailScreen({
    super.key,
    required this.weather,
    this.initiallyHourly = false,
  });

  final WeatherSnapshot weather;
  final bool initiallyHourly;

  @override
  State<ForecastDetailScreen> createState() => _ForecastDetailScreenState();
}

class _ForecastDetailScreenState extends State<ForecastDetailScreen> {
  late bool showHourly = widget.initiallyHourly;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final weather = widget.weather;
    final unit = provider.temperatureUnit;
    final values = (showHourly ? weather.hourlyForecast : weather.dailyForecast)
        .take(showHourly ? 12 : 7)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(weather.cityName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '7-day forecast',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => setState(() => showHourly = true),
                      style: FilledButton.styleFrom(
                        backgroundColor: showHourly
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.surface,
                        foregroundColor: showHourly
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      child: const Text('Hourly'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => setState(() => showHourly = false),
                      style: FilledButton.styleFrom(
                        backgroundColor: !showHourly
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.surface,
                        foregroundColor: !showHourly
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      child: const Text('Daily'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (showHourly)
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 4,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withAlpha(
                              (255 * 0.12).round(),
                            ),
                          ),
                          spots: values
                              .asMap()
                              .entries
                              .map(
                                (entry) => FlSpot(
                                  entry.key.toDouble(),
                                  WeatherUtils.convertTemperature(
                                    (showHourly
                                        ? (entry.value as WeatherHour)
                                              .temperature
                                        : (entry.value as WeatherDay)
                                              .maxTemperature),
                                    unit,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 4,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withAlpha(
                              (255 * 0.12).round(),
                            ),
                          ),
                          spots: values
                              .asMap()
                              .entries
                              .map(
                                (entry) => FlSpot(
                                  entry.key.toDouble(),
                                  WeatherUtils.convertTemperature(
                                    (showHourly
                                        ? (entry.value as WeatherHour)
                                              .temperature
                                        : (entry.value as WeatherDay)
                                              .maxTemperature),
                                    unit,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DetailMetric(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Sunrise',
                    value: WeatherUtils.formatTime(weather.sunrise),
                  ),
                  _DetailMetric(
                    icon: Icons.nights_stay_outlined,
                    label: 'Sunset',
                    value: WeatherUtils.formatTime(weather.sunset),
                  ),
                  _DetailMetric(
                    icon: Icons.water_drop_outlined,
                    label: 'Humidity',
                    value: '${weather.humidity.round()}%',
                  ),
                  _DetailMetric(
                    icon: Icons.air_rounded,
                    label: 'Wind',
                    value: WeatherUtils.formatWind(
                      weather.windSpeed,
                      provider.windUnit,
                    ),
                  ),
                  _DetailMetric(
                    icon: Icons.thermostat_rounded,
                    label: 'UV index',
                    value: weather.uvIndex.toStringAsFixed(0),
                  ),
                  _DetailMetric(
                    icon: Icons.compress_rounded,
                    label: 'Pressure',
                    value: '${weather.pressure.round()} hPa',
                  ),
                  _DetailMetric(
                    icon: Icons.visibility_rounded,
                    label: 'Visibility',
                    value: '${weather.visibility.round()} m',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Next 7 days',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...weather.dailyForecast.map(
                (day) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(WeatherUtils.formatWeekday(day.date)),
                      ),
                      Icon(
                        WeatherUtils.getWeatherIcon(day.weatherCode),
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          WeatherUtils.getWeatherLabel(day.weatherCode),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${WeatherUtils.formatTemperature(day.minTemperature, unit)} / ${WeatherUtils.formatTemperature(day.maxTemperature, unit)}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
