import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/weather_models.dart';
import '../providers/weather_provider.dart';
import 'forecast_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final weather = provider.currentWeather;
    final temperatureUnit = provider.temperatureUnit;
    final windUnit = provider.windUnit;

    if (weather == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: provider.isRefreshing || provider.isInitializing
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 18),
                        Text('Loading local weather…'),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 54,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage ??
                              'Weather is unavailable right now.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: provider.refreshWeather,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                        TextButton.icon(
                          onPressed: () => _openCitySearch(context),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Choose a city'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    final isNight = WeatherUtils.isNight(
      weather.currentTime,
      weather.sunrise,
      weather.sunset,
    );
    String tempFormatter(double value) =>
        WeatherUtils.formatTemperature(value, temperatureUnit);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refreshWeather,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openCitySearch(context),
                        child: Text(
                          provider.currentCityName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openCitySearch(context),
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  WeatherUtils.formatDateLong(weather.currentTime),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha((255 * 0.2).round()),
                        AppColors.secondary.withAlpha((255 * 0.14).round()),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tempFormatter(weather.temperature),
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    WeatherUtils.getWeatherIcon(
                                      weather.weatherCode,
                                      isNight: isNight,
                                    ),
                                    size: 30,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    WeatherUtils.getWeatherLabel(
                                      weather.weatherCode,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(
                            WeatherUtils.getWeatherIcon(
                              weather.weatherCode,
                              isNight: isNight,
                            ),
                            size: 86,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'H: ${tempFormatter(weather.dailyForecast.first.maxTemperature)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'L: ${tempFormatter(weather.dailyForecast.first.minTemperature)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'Feels like ${tempFormatter(weather.feelsLike)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: weather.hourlyForecast.take(12).length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final hourly = weather.hourlyForecast[index];
                      final isCurrent = index == 0;
                      return GestureDetector(
                        onTap: () =>
                            _openHourlyDetails(context, weather, hourly),
                        child: Container(
                          width: 88,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primary.withAlpha(
                                    (255 * 0.12).round(),
                                  )
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                WeatherUtils.formatTime(hourly.time),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                WeatherUtils.getWeatherIcon(
                                  hourly.weatherCode,
                                  isNight: isNight,
                                ),
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tempFormatter(hourly.temperature),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${hourly.precipitationProbability.round()}%',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.mutedText),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '7-Day Forecast',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => _openForecast(context, weather),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...weather.dailyForecast.take(7).map((day) {
                  final label = WeatherUtils.formatWeekday(day.date);
                  final line = '${day.date.day}/${day.date.month}';
                  return GestureDetector(
                    onTap: () => _openDayDetails(context, day),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 66,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  line,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.mutedText),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            WeatherUtils.getWeatherIcon(day.weatherCode),
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  WeatherUtils.getWeatherLabel(day.weatherCode),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  '${day.precipitationProbability.round()}% rain',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.mutedText),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${tempFormatter(day.minTemperature)} / ${tempFormatter(day.maxTemperature)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoPill(
                      label: 'Wind',
                      value: WeatherUtils.formatWind(
                        weather.windSpeed,
                        windUnit,
                      ),
                    ),
                    _InfoPill(
                      label: 'Humidity',
                      value: '${weather.humidity.round()}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCitySearch(BuildContext context) {
    final provider = context.read<WeatherProvider>();
    provider.searchCities('');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _CitySearchSheet(),
    );
  }

  void _openHourlyDetails(
    BuildContext context,
    WeatherSnapshot weather,
    WeatherHour hourly,
  ) {
    _openForecast(context, weather, initiallyHourly: true);
  }

  void _openDayDetails(BuildContext context, WeatherDay day) {
    final weather = context.read<WeatherProvider>().currentWeather;
    if (weather != null) {
      _openForecast(context, weather, initiallyHourly: false);
    }
  }

  void _openForecast(
    BuildContext context,
    WeatherSnapshot weather, {
    bool initiallyHourly = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForecastDetailScreen(
          weather: weather,
          initiallyHourly: initiallyHourly,
        ),
      ),
    );
  }
}

class _CitySearchSheet extends StatefulWidget {
  const _CitySearchSheet();

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom - 36;
    final maxHeight = mediaQuery.size.height * 0.8;
    final sheetHeight = availableHeight < maxHeight
        ? availableHeight
        : maxHeight;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: mediaQuery.viewInsets.bottom + 18,
      ),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Search city',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Enter city name',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: provider.searchCities,
            ),
            const SizedBox(height: 16),
            if (provider.isSearching)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (provider.searchError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  provider.searchError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!provider.isSearching && provider.searchResults.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _controller.text.trim().length < 2
                      ? 'Type at least 2 letters to search for a city.'
                      : 'No matching cities found.',
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ),
            if (provider.searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final city = provider.searchResults[index];
                    return ListTile(
                      title: Text(city.name),
                      subtitle: Text(city.country),
                      onTap: () async {
                        final selected = await provider.selectCity(city);
                        if (!context.mounted) return;
                        if (selected) {
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.errorMessage ??
                                    'Unable to load this city.',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
