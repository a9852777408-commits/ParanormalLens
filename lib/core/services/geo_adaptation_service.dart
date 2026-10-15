import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/regional_profile.dart';

/// Implements the two-tier Geolocation & Cultural Adaptation Pipeline:
/// - Passive Tier: Zero-permission country resolution (Locale, SIM MCC, Edge header).
/// - Active Tier: Explicit user action for Geomagnetic Anomaly Radar (GPS Fine Location, 500m).
class GeoAdaptationService extends ChangeNotifier {
  static final GeoAdaptationService _instance = GeoAdaptationService._internal();
  factory GeoAdaptationService() => _instance;
  GeoAdaptationService._internal();

  RegionalProfile _activeProfile = RegionalProfiles.cisSlavic; // Safe default
  Position? _currentActivePosition;
  bool _isRadarActive = false;

  RegionalProfile get activeProfile => _activeProfile;
  Position? get currentPosition => _currentActivePosition;
  bool get isRadarActive => _isRadarActive;

  /// Initializes Passive Tier resolution on app launch without asking permissions
  void initializePassiveTier() {
    String resolvedCountryCode = _resolvePassiveCountryCode();
    _activeProfile = _matchProfileByCountryCode(resolvedCountryCode);
    debugPrint('[GeoAdaptation] Passive Tier resolved country: $resolvedCountryCode -> Profile: ${_activeProfile.profileKey}');
    notifyListeners();
  }

  /// Priority 1: System Locale, Priority 2: SIM / Network Country
  String _resolvePassiveCountryCode() {
    try {
      final Locale systemLocale = PlatformDispatcher.instance.locale;
      if (systemLocale.countryCode != null && systemLocale.countryCode!.isNotEmpty) {
        return systemLocale.countryCode!.toUpperCase();
      }
    } catch (e) {
      debugPrint('[GeoAdaptation] Error reading system locale: $e');
    }

    // Fallback: Check system language code
    final lang = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    if (lang == 'ar') return 'SA';
    if (lang == 'ru' || lang == 'be' || lang == 'kk') return 'RU';
    return 'US'; // Default fallback
  }

  RegionalProfile _matchProfileByCountryCode(String code) {
    for (final profile in RegionalProfiles.all) {
      if (profile.targetRegions.contains(code)) {
        return profile;
      }
    }
    // Default to Western Gothic for unrecognized regions
    return RegionalProfiles.westernGothic;
  }

  /// Active Tier: Triggered explicitly when user taps "Geomagnetic Anomaly Radar"
  Future<bool> activateGeomagneticRadar() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[GeoAdaptation] Location services disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    _currentActivePosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _isRadarActive = true;
    debugPrint('[GeoAdaptation] Active Tier Radar engaged at (${_currentActivePosition?.latitude}, ${_currentActivePosition?.longitude})');
    notifyListeners();
    return true;
  }
}
