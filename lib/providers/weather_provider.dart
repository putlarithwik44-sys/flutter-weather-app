import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_models.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherProvider() {
    initialize();
  }

  final WeatherService _weatherService = WeatherService();
  int _searchRequest = 0;

  TemperatureUnit temperatureUnit = TemperatureUnit.celsius;
  WindUnit windUnit = WindUnit.kmh;
  AppThemeMode themeMode = AppThemeMode.system;
  bool notificationsEnabled = false;
  bool locationPermissionGranted = false;
  bool isInitializing = true;
  bool isSearching = false;
  bool isRefreshing = false;
  bool isRefreshingSavedCities = false;
  String currentCityName = 'Vijayawada';
  String currentCountry = 'India';
  double currentLatitude = 16.5062;
  double currentLongitude = 80.6480;
  WeatherSnapshot? currentWeather;
  List<CitySearchResult> searchResults = const [];
  List<SavedCity> savedCities = const [];
  String? errorMessage;
  String? searchError;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      temperatureUnit = _enumValue(
        TemperatureUnit.values,
        prefs.getString('temperature_unit'),
        TemperatureUnit.celsius,
      );
      windUnit = _enumValue(
        WindUnit.values,
        prefs.getString('wind_unit'),
        WindUnit.kmh,
      );
      themeMode = _enumValue(
        AppThemeMode.values,
        prefs.getString('theme_mode'),
        AppThemeMode.system,
      );
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      final cities = prefs.getStringList('saved_cities') ?? const [];
      savedCities = cities
          .map(
            (value) =>
                SavedCity.fromJson(jsonDecode(value) as Map<String, dynamic>),
          )
          .toList();
      currentCityName = prefs.getString('current_city_name') ?? currentCityName;
      currentCountry = prefs.getString('current_country') ?? currentCountry;
      currentLatitude = prefs.getDouble('current_latitude') ?? currentLatitude;
      currentLongitude =
          prefs.getDouble('current_longitude') ?? currentLongitude;
    } catch (error) {
      errorMessage = 'Could not load saved preferences: $error';
    } finally {
      isInitializing = false;
      notifyListeners();
    }
    await refreshWeather();
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  Future<void> _persistPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temperature_unit', temperatureUnit.name);
    await prefs.setString('wind_unit', windUnit.name);
    await prefs.setString('theme_mode', themeMode.name);
    await prefs.setBool('notifications_enabled', notificationsEnabled);
    await prefs.setStringList(
      'saved_cities',
      savedCities.map((city) => jsonEncode(city.toJson())).toList(),
    );
    await prefs.setString('current_city_name', currentCityName);
    await prefs.setString('current_country', currentCountry);
    await prefs.setDouble('current_latitude', currentLatitude);
    await prefs.setDouble('current_longitude', currentLongitude);
  }

  Future<void> _saveAndNotify() async {
    try {
      await _persistPreferences();
    } catch (error) {
      errorMessage = 'Could not save your changes: $error';
    }
    notifyListeners();
  }

  Future<void> searchCities(String query) async {
    final request = ++_searchRequest;
    if (query.trim().length < 2) {
      searchResults = const [];
      searchError = null;
      isSearching = false;
      notifyListeners();
      return;
    }

    isSearching = true;
    searchError = null;
    notifyListeners();
    try {
      final results = await _weatherService.searchCities(query);
      if (request != _searchRequest) return;
      searchResults = results;
    } catch (error) {
      if (request != _searchRequest) return;
      searchResults = const [];
      searchError = error.toString();
    } finally {
      if (request == _searchRequest) {
        isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<bool> refreshWeather() async {
    isRefreshing = true;
    errorMessage = null;
    notifyListeners();
    try {
      currentWeather = await _weatherService.fetchWeatherForCoordinates(
        latitude: currentLatitude,
        longitude: currentLongitude,
        cityName: currentCityName,
        country: currentCountry,
      );
      isRefreshing = false;
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage =
          'Could not load weather. Check your internet connection and try again. ($error)';
      isRefreshing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> selectCity(CitySearchResult city) async {
    isRefreshing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final weather = await _weatherService.fetchWeatherForCoordinates(
        latitude: city.latitude,
        longitude: city.longitude,
        cityName: city.name,
        country: city.country,
      );
      currentCityName = city.name;
      currentCountry = city.country;
      currentLatitude = city.latitude;
      currentLongitude = city.longitude;
      currentWeather = weather;
      isRefreshing = false;
      await _saveAndNotify();
      return true;
    } catch (error) {
      isRefreshing = false;
      errorMessage =
          'Could not load ${city.name} weather. Please try again. ($error)';
      notifyListeners();
      return false;
    }
  }

  Future<WeatherSnapshot> fetchCityWeather(SavedCity city) {
    return _weatherService.fetchWeatherForCoordinates(
      latitude: city.latitude,
      longitude: city.longitude,
      cityName: city.name,
      country: city.country,
    );
  }

  bool isCitySaved(CitySearchResult city) => savedCities.any(
    (saved) => _samePlace(
      saved.latitude,
      saved.longitude,
      city.latitude,
      city.longitude,
    ),
  );

  Future<void> addSavedCity(CitySearchResult city) async {
    if (isCitySaved(city)) return;
    final weather = await _weatherService.fetchWeatherForCoordinates(
      latitude: city.latitude,
      longitude: city.longitude,
      cityName: city.name,
      country: city.country,
    );
    if (isCitySaved(city)) return;
    savedCities = [
      ...savedCities,
      SavedCity(
        id: city.id,
        name: city.name,
        country: city.country,
        admin1: city.admin1,
        latitude: city.latitude,
        longitude: city.longitude,
        isFavorite: false,
        temperature: weather.temperature,
        weatherCode: weather.weatherCode,
        lastUpdated: weather.currentTime,
      ),
    ];
    await _saveAndNotify();
  }

  Future<void> removeSavedCity(int cityId) async {
    savedCities = savedCities.where((city) => city.id != cityId).toList();
    await _saveAndNotify();
  }

  Future<void> toggleFavorite(int cityId) async {
    savedCities = savedCities
        .map(
          (city) => city.id == cityId
              ? SavedCity(
                  id: city.id,
                  name: city.name,
                  country: city.country,
                  admin1: city.admin1,
                  latitude: city.latitude,
                  longitude: city.longitude,
                  isFavorite: !city.isFavorite,
                  temperature: city.temperature,
                  weatherCode: city.weatherCode,
                  lastUpdated: city.lastUpdated,
                )
              : city,
        )
        .toList();
    await _saveAndNotify();
  }

  Future<void> refreshSavedCities() async {
    if (savedCities.isEmpty || isRefreshingSavedCities) return;
    isRefreshingSavedCities = true;
    notifyListeners();
    try {
      final refreshed = await Future.wait(
        savedCities.map((city) async {
          final weather = await fetchCityWeather(city);
          return SavedCity(
            id: city.id,
            name: city.name,
            country: city.country,
            admin1: city.admin1,
            latitude: city.latitude,
            longitude: city.longitude,
            isFavorite: city.isFavorite,
            temperature: weather.temperature,
            weatherCode: weather.weatherCode,
            lastUpdated: weather.currentTime,
          );
        }),
      );
      savedCities = refreshed;
      errorMessage = null;
      await _persistPreferences();
    } catch (error) {
      errorMessage = 'Could not refresh saved cities: $error';
    } finally {
      isRefreshingSavedCities = false;
      notifyListeners();
    }
  }

  Future<bool> useCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        errorMessage =
            'Turn on location services to use your current location.';
        notifyListeners();
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        errorMessage = 'Location permission was not granted.';
        locationPermissionGranted = false;
        notifyListeners();
        return false;
      }
      locationPermissionGranted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
      currentCityName = 'My location';
      currentCountry = '';
      await _persistPreferences();
      return await refreshWeather();
    } catch (error) {
      errorMessage = 'Could not get your location: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    temperatureUnit = unit;
    await _saveAndNotify();
  }

  Future<void> setWindUnit(WindUnit unit) async {
    windUnit = unit;
    await _saveAndNotify();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    themeMode = mode;
    await _saveAndNotify();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled = enabled;
    await _saveAndNotify();
  }

  static bool _samePlace(double latA, double lonA, double latB, double lonB) =>
      latA.toStringAsFixed(3) == latB.toStringAsFixed(3) &&
      lonA.toStringAsFixed(3) == lonB.toStringAsFixed(3);
}
