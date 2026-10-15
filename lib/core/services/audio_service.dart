import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Master audio controller for ParanormalLens:
/// Coordinates procedural ambient drone, reactive EMF Geiger clicks,
/// entity-specific soundscapes, and prank jumpscare audio.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  Timer? _geigerLoopTimer;
  double _currentEmfIntensity = 0.0; // 0.0 to 1.0

  // Asset paths
  static const String sfxAmbient = 'assets/audio/ambient_drone.wav';
  static const String sfxGeiger = 'assets/audio/geiger_tick.wav';
  static const String sfxRaven = 'assets/audio/raven_window.wav';
  static const String sfxWhisper = 'assets/audio/whisper_chills.wav';
  static const String sfxHolyBell = 'assets/audio/holy_dawn_bell.wav';
  static const String sfxScreamer = 'assets/audio/jumpscare_screech.wav';

  void initialize() {
    debugPrint('[Audio] Audio Service initialized with 6 synthesized horror soundscapes.');
    playAmbientDrone();
  }

  void playAmbientDrone() {
    debugPrint('[Audio] Ambient 50Hz drone playing in background.');
    // In production, audio player loops sfxAmbient at 25% volume
  }

  /// Updates radiation / EMF intensity and modulates Geiger clicking frequency
  void updateEmfLevel(double intensity) {
    _currentEmfIntensity = intensity.clamp(0.0, 1.0);
    _geigerLoopTimer?.cancel();

    if (_currentEmfIntensity > 0.15) {
      // Faster intervals as EMF spikes (from 800ms down to 60ms)
      int intervalMs = (800 - (_currentEmfIntensity * 740)).round();
      _geigerLoopTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        _playGeigerTick();
      });
    }
  }

  void _playGeigerTick() {
    // Plays quick Geiger click sound + light haptic tick
    HapticFeedback.selectionClick();
  }

  void playRavenWindowFlight() {
    debugPrint('[Audio] Triggered: Window Raven pecks glass and flies downwards.');
    // Plays sfxRaven
  }

  void playEntityWhispers() {
    debugPrint('[Audio] Triggered: Spatial entity whispers.');
    // Plays sfxWhisper
  }

  void playHolyDawnBell() {
    debugPrint('[Audio] Triggered: Jerusalem church bells chime.');
    // Plays sfxHolyBell
  }

  void playJumpscareScreech() {
    debugPrint('[Audio] Triggered: Deafening 100% volume jumpscare screech!');
    // Plays sfxScreamer + heavy impact
    HapticFeedback.heavyImpact();
  }

  void stop() {
    _geigerLoopTimer?.cancel();
  }
}
