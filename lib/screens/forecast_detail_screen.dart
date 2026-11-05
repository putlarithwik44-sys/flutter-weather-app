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

    return Scaffold(
      appBar: AppBar(title: Text(weather.cityName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                showHourly ? 'Hourly forecast' : '5-day forecast',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                showHourly
                    ? 'Temperature and rain chances for the next hours'
                    : 'Daily high and low temperatures at a glance',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Hourly')),
                  ButtonSegment(value: false, label: Text('5 days')),
                ],
                selected: {showHourly},
                onSelectionChanged: (selection) {
                  setState(() => showHourly = selection.first);
                },
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.025),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: showHourly
                    ? _HourlyForecast(
                        key: const ValueKey('hourly'),
                        weather: weather,
                        temperatureUnit: unit,
                      )
                    : _DailyForecast(
                        key: const ValueKey('daily'),
                        weather: weather,
                        temperatureUnit: unit,
                        windUnit: provider.windUnit,
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                'Current conditions',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
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
                    label: 'Feels like',
                    value: WeatherUtils.formatTemperature(
                      weather.feelsLike,
                      unit,
                    ),
                  ),
                  _DetailMetric(
                    icon: Icons.wb_sunny_outlined,
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
                    value:
                        '${(weather.visibility / 1000).toStringAsFixed(1)} km',
                  ),
                  _DetailMetric(
                    icon: Icons.wb_twilight_rounded,
                    label: 'Sunrise',
                    value: WeatherUtils.formatTime(weather.sunrise),
                  ),
                  _DetailMetric(
                    icon: Icons.nights_stay_outlined,
                    label: 'Sunset',
                    value: WeatherUtils.formatTime(weather.sunset),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyForecast extends StatelessWidget {
  const _DailyForecast({
    super.key,
    required this.weather,
    required this.temperatureUnit,
    required this.windUnit,
  });

  final WeatherSnapshot weather;
  final TemperatureUnit temperatureUnit;
  final WindUnit windUnit;

  @override
  Widget build(BuildContext context) {
    final days = weather.dailyForecast.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DailyTemperatureChart(
          days: days,
          temperatureUnit: temperatureUnit,
          windUnit: windUnit,
        ),
        const SizedBox(height: 20),
        Text(
          'Daily details',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...days.asMap().entries.map(
          (entry) => _DaySummary(
            day: entry.value,
            isToday: entry.key == 0,
            temperatureUnit: temperatureUnit,
          ),
        ),
      ],
    );
  }
}

class _DailyTemperatureChart extends StatelessWidget {
  const _DailyTemperatureChart({
    required this.days,
    required this.temperatureUnit,
    required this.windUnit,
  });

  final List<WeatherDay> days;
  final TemperatureUnit temperatureUnit;
  final WindUnit windUnit;

  static const double _columnWidth = 72;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final minCelsius = days
        .map((day) => day.minTemperature)
        .reduce((a, b) => a < b ? a : b);
    final maxCelsius = days
        .map((day) => day.maxTemperature)
        .reduce((a, b) => a > b ? a : b);
    final minY = WeatherUtils.convertTemperature(minCelsius, temperatureUnit);
    final maxY = WeatherUtils.convertTemperature(maxCelsius, temperatureUnit);
    final padding = ((maxY - minY) * 0.2).clamp(2.0, 8.0);
    final chartMinY = minY - padding;
    final chartMaxY = maxY + padding;
    final width = days.length * _columnWidth + 8;
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          height: 370,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: List.generate(
                    days.length,
                    (index) => Container(
                      width: _columnWidth,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? AppColors.primary.withAlpha(20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                child: Column(
                  children: [
                    Row(
                      children: days.asMap().entries.map((entry) {
                        final day = entry.value;
                        return SizedBox(
                          width: _columnWidth,
                          child: Column(
                            children: [
                              Text(
                                entry.key == 0
                                    ? 'Today'
                                    : WeatherUtils.formatWeekday(day.date),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${day.date.day}/${day.date.month}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.mutedText),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: days.map((day) {
                        return SizedBox(
                          width: _columnWidth,
                          child: Icon(
                            WeatherUtils.getWeatherIcon(day.weatherCode),
                            color: AppColors.primary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: days.map((day) {
                        return SizedBox(
                          width: _columnWidth,
                          child: Text(
                            WeatherUtils.formatTemperature(
                              day.maxTemperature,
                              temperatureUnit,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        );
                      }).toList(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: (days.length - 1).toDouble().clamp(
                              1,
                              double.infinity,
                            ),
                            minY: chartMinY,
                            maxY: chartMaxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 5,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withAlpha(70),
                                strokeWidth: 0.7,
                              ),
                            ),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              _temperatureLine(
                                days,
                                isHigh: true,
                                color: AppColors.sunnyAccent,
                              ),
                              _temperatureLine(
                                days,
                                isHigh: false,
                                color: AppColors.rainAccent,
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeInOutCubic,
                        ),
                      ),
                    ),
                    Row(
                      children: days.map((day) {
                        return SizedBox(
                          width: _columnWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 7,
                                color: AppColors.rainAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                WeatherUtils.formatTemperature(
                                  day.minTemperature,
                                  temperatureUnit,
                                ),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: days.map((day) {
                        return SizedBox(
                          width: _columnWidth,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.water_drop_outlined,
                                    size: 12,
                                    color: AppColors.rainAccent,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${day.precipitationProbability.round()}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: AppColors.mutedText),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                WeatherUtils.formatWind(
                                  day.maxWindSpeed,
                                  windUnit,
                                ),
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.mutedText),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _temperatureLine(
    List<WeatherDay> values, {
    required bool isHigh,
    required Color color,
  }) {
    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: color,
        ),
      ),
      spots: values.asMap().entries.map((entry) {
        final celsius = isHigh
            ? entry.value.maxTemperature
            : entry.value.minTemperature;
        return FlSpot(
          entry.key.toDouble(),
          WeatherUtils.convertTemperature(celsius, temperatureUnit),
        );
      }).toList(),
    );
  }
}

class _HourlyForecast extends StatelessWidget {
  const _HourlyForecast({
    super.key,
    required this.weather,
    required this.temperatureUnit,
  });

  final WeatherSnapshot weather;
  final TemperatureUnit temperatureUnit;

  @override
  Widget build(BuildContext context) {
    final hours = weather.hourlyForecast.take(12).toList();
    if (hours.isEmpty) {
      return const SizedBox.shrink();
    }
    final temps = hours
        .map(
          (hour) => WeatherUtils.convertTemperature(
            hour.temperature,
            temperatureUnit,
          ),
        )
        .toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final padding = ((maxTemp - minTemp) * 0.2).clamp(2.0, 8.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (hours.length - 1).toDouble().clamp(1, double.infinity),
              minY: minTemp - padding,
              maxY: maxTemp + padding,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withAlpha(70),
                  strokeWidth: 0.7,
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withAlpha(24),
                  ),
                  spots: temps
                      .asMap()
                      .entries
                      .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                      .toList(),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Next hours',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...hours.map(
          (hour) => _HourSummary(hour: hour, temperatureUnit: temperatureUnit),
        ),
      ],
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.day,
    required this.isToday,
    required this.temperatureUnit,
  });

  final WeatherDay day;
  final bool isToday;
  final TemperatureUnit temperatureUnit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              isToday ? 'Today' : WeatherUtils.formatWeekday(day.date),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Icon(
            WeatherUtils.getWeatherIcon(day.weatherCode),
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              WeatherUtils.getWeatherLabel(day.weatherCode),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            '${WeatherUtils.formatTemperature(day.minTemperature, temperatureUnit)}  /  ${WeatherUtils.formatTemperature(day.maxTemperature, temperatureUnit)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HourSummary extends StatelessWidget {
  const _HourSummary({required this.hour, required this.temperatureUnit});

  final WeatherHour hour;
  final TemperatureUnit temperatureUnit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              WeatherUtils.formatTime(hour.time),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Icon(
            WeatherUtils.getWeatherIcon(hour.weatherCode),
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              WeatherUtils.getWeatherLabel(hour.weatherCode),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Icon(
            Icons.water_drop_outlined,
            size: 14,
            color: AppColors.rainAccent,
          ),
          const SizedBox(width: 4),
          Text('${hour.precipitationProbability.round()}%'),
          const SizedBox(width: 12),
          Text(
            WeatherUtils.formatTemperature(hour.temperature, temperatureUnit),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
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
