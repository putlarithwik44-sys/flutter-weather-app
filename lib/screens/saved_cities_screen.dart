import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/weather_models.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';

class SavedCitiesScreen extends StatefulWidget {
  const SavedCitiesScreen({super.key, required this.onCitySelected});

  final VoidCallback onCitySelected;

  @override
  State<SavedCitiesScreen> createState() => _SavedCitiesScreenState();
}

class _SavedCitiesScreenState extends State<SavedCitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  String _query = '';
  int? _openingCityId;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final query = _query.trim().toLowerCase();
    final filteredCities =
        provider.savedCities.where((city) {
          return city.displayName.toLowerCase().contains(query);
        }).toList()..sort(
          (a, b) => (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0),
        );
    final showRemoteResults = _query.trim().length >= 2;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refreshSavedCities,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 400 ? 16 : 24,
              20,
              MediaQuery.sizeOf(context).width < 400 ? 16 : 24,
              28,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved cities',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.savedCities.length} locations saved',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Refresh saved city weather',
                    onPressed: provider.isRefreshingSavedCities
                        ? null
                        : provider.refreshSavedCities,
                    icon: provider.isRefreshingSavedCities
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Search for a city to add',
                    onPressed: () => _searchFocusNode.requestFocus(),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search city, district or state',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              if (showRemoteResults) ...[
                const SizedBox(height: 16),
                Text(
                  'Search results',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (provider.isSearching)
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.searchError != null)
                  _MessageCard(
                    icon: Icons.cloud_off_outlined,
                    message: provider.searchError!,
                    actionLabel: 'Try again',
                    onAction: () => provider.searchCities(_query),
                  )
                else if (provider.searchResults.isEmpty)
                  const _MessageCard(
                    icon: Icons.search_off_rounded,
                    message: 'No matching places found. Check the spelling and try again.',
                  )
                else
                  ...provider.searchResults.map(
                    (city) => _searchResultTile(context, city),
                  ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      showRemoteResults ? 'Your saved places' : 'Your places',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (provider.savedCities.isNotEmpty)
                    TextButton.icon(
                      onPressed: provider.isRefreshingSavedCities
                          ? null
                          : provider.refreshSavedCities,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Update'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (filteredCities.isEmpty)
                _MessageCard(
                  icon: query.isEmpty
                      ? Icons.location_city_outlined
                      : Icons.search_off_rounded,
                  message: query.isEmpty
                      ? 'No cities saved yet. Search for a city above and tap Add.'
                      : 'No saved city matches “$_query”.',
                )
              else
                ...filteredCities.map((city) => _savedCityCard(context, city)),
              const SizedBox(height: 12),
              Text(
                'Weather data provided by Open-Meteo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    final query = value.trim();
    context.read<WeatherProvider>().searchCities('');
    if (query.length < 2) {
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) context.read<WeatherProvider>().searchCities(query);
    });
  }

  Widget _searchResultTile(BuildContext context, CitySearchResult city) {
    final provider = context.read<WeatherProvider>();
    final alreadySaved = provider.isCitySaved(city);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1F2878C8),
          child: Icon(Icons.location_on_outlined, color: AppColors.primary),
        ),
        title: Text(
          city.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (city.country.isNotEmpty)
              city.countryCode.isEmpty
                  ? city.country
                  : '${city.country} · ${city.countryCode}',
          ].where((part) => part.isNotEmpty).join(', '),
          style: const TextStyle(color: AppColors.mutedText),
        ),
        trailing: alreadySaved
            ? const Chip(label: Text('Saved'))
            : IconButton.filledTonal(
                tooltip: 'Add ${city.name}',
                onPressed: () => _addCity(context, city),
                icon: const Icon(Icons.add_rounded),
              ),
        onTap: alreadySaved ? null : () => _addCity(context, city),
      ),
    );
  }

  Widget _savedCityCard(BuildContext context, SavedCity city) {
    final provider = context.read<WeatherProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCityWeather(context, city),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    WeatherUtils.getWeatherIcon(city.weatherCode),
                    size: 34,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            city.admin2,
                            city.admin1,
                            city.country,
                          ].where((part) => part.isNotEmpty).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.mutedText),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          WeatherUtils.getWeatherLabel(city.weatherCode),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    WeatherUtils.formatTemperature(
                      city.temperature,
                      provider.temperatureUnit,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _openingCityId == city.id
                          ? 'Loading forecast…'
                          : 'Updated ${WeatherUtils.formatTime(city.lastUpdated)}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppColors.mutedText),
                    ),
                  ),
                  if (_openingCityId == city.id)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    IconButton(
                      tooltip: city.isFavorite
                          ? 'Remove favorite'
                          : 'Mark favorite',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => provider.toggleFavorite(city.id),
                      icon: Icon(
                        city.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: city.isFavorite
                            ? AppColors.sunnyAccent
                            : AppColors.mutedText,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove ${city.name}',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _removeCity(context, city),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addCity(BuildContext context, CitySearchResult city) async {
    try {
      await context.read<WeatherProvider>().addSavedCity(city);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${city.name} added to saved cities.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add ${city.name}: $error')),
      );
    }
  }

  Future<void> _removeCity(BuildContext context, SavedCity city) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove saved city?'),
        content: Text('Remove ${city.name} from your saved places?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    await context.read<WeatherProvider>().removeSavedCity(city.id);
  }

  Future<void> _openCityWeather(BuildContext context, SavedCity city) async {
    setState(() => _openingCityId = city.id);
    final provider = context.read<WeatherProvider>();
    final selected = await provider.selectSavedCity(city);
    if (!context.mounted) return;
    if (selected) {
      widget.onCitySelected();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Could not load ${city.name}.',
          ),
        ),
      );
    }
    if (mounted) setState(() => _openingCityId = null);
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 38, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}
