import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/weather_models.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Make SkyCast feel like yours.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 22),
            _SettingsCard(
              title: 'Units',
              icon: Icons.straighten_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _OptionLabel(
                    icon: Icons.thermostat_rounded,
                    title: 'Temperature',
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<TemperatureUnit>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: TemperatureUnit.celsius,
                        label: Text('°C'),
                      ),
                      ButtonSegment(
                        value: TemperatureUnit.fahrenheit,
                        label: Text('°F'),
                      ),
                    ],
                    selected: {provider.temperatureUnit},
                    onSelectionChanged: (value) =>
                        provider.setTemperatureUnit(value.first),
                  ),
                  const SizedBox(height: 20),
                  const _OptionLabel(
                    icon: Icons.air_rounded,
                    title: 'Wind speed',
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<WindUnit>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: WindUnit.kmh, label: Text('km/h')),
                      ButtonSegment(value: WindUnit.mph, label: Text('mph')),
                      ButtonSegment(value: WindUnit.ms, label: Text('m/s')),
                    ],
                    selected: {provider.windUnit},
                    onSelectionChanged: (value) =>
                        provider.setWindUnit(value.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              child: SegmentedButton<AppThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: AppThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: AppThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: AppThemeMode.system,
                    icon: Icon(Icons.settings_brightness_outlined),
                    label: Text('System'),
                  ),
                ],
                selected: {provider.themeMode},
                onSelectionChanged: (value) =>
                    provider.setThemeMode(value.first),
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'Preferences',
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: provider.notificationsEnabled,
                    onChanged: (value) =>
                        provider.setNotificationsEnabled(value),
                    title: const Text('Daily forecast reminders'),
                    subtitle: const Text(
                      'Preference saved on this device. Alert delivery is not configured yet.',
                    ),
                  ),
                  const Divider(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Use current location'),
                    subtitle: Text(
                      provider.locationPermissionGranted
                          ? 'Location permission is available'
                          : 'Allow location access to show local weather',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _useLocation(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'About',
              icon: Icons.info_outline_rounded,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('SkyCast'),
                subtitle: const Text('Weather forecasts powered by Open-Meteo'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'SkyCast',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Weather data provided by Open-Meteo.',
                ),
              ),
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                provider.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _useLocation(BuildContext context) async {
    final provider = context.read<WeatherProvider>();
    final success = await provider.useCurrentLocation();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Showing weather for your current location.'
              : provider.errorMessage ?? 'Could not use your current location.',
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 21),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mutedText),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
