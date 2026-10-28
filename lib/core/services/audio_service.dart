import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Master audio controller for ParanormalLens / PL:
/// Connects to native Android SoundPool, MediaPlayer and Microphone Speech/Prayer Recognizer
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static const MethodChannel _channel = MethodChannel('com.paranormallens.app/audio');

  Timer? _geigerLoopTimer;
  double _currentEmfIntensity = 0.0;
  bool _isMuted = false;
  bool _isListeningPrayer = false;

  bool get isMuted => _isMuted;
  bool get isListeningPrayer => _isListeningPrayer;

  // Callbacks for prayer voice detection
  Function(String phrase, String source)? onPrayerDetected;
  Function(double energy)? onVoiceEnergy;

  void initialize() {
    _channel.setMethodCallHandler(_handleNativeCall);
    playAmbientDrone();
    startPrayerListening();
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onPrayerRecognized':
        final phrase = call.arguments['phrase']?.toString() ?? '«СВЯЩЕННАЯ МОЛИТВА»';
        final source = call.arguments['source']?.toString() ?? 'speech';
        debugPrint('[Audio] Sacred prayer heard by mic: $phrase (source: $source)');
        onPrayerDetected?.call(phrase, source);
        break;
      case 'onVoiceEnergy':
        final energy = (call.arguments['energy'] as num?)?.toDouble() ?? 0.0;
        onVoiceEnergy?.call(energy);
        break;
      default:
        break;
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stopAmbient();
      _geigerLoopTimer?.cancel();
    } else {
      playAmbientDrone();
    }
  }

  Future<void> playAmbientDrone() async {
    if (_isMuted) return;
    try {
      await _channel.invokeMethod('playAmbient');
    } catch (e) {
      debugPrint('[Audio] Error playing ambient drone: $e');
    }
  }

  Future<void> stopAmbient() async {
    try {
      await _channel.invokeMethod('stopAmbient');
    } catch (e) {
      debugPrint('[Audio] Error stopping ambient: $e');
    }
  }

  Future<void> playSfx(String name) async {
    if (_isMuted) return;
    try {
      await _channel.invokeMethod('playSfx', {'name': name});
    } catch (e) {
      debugPrint('[Audio] Error playing SFX $name: $e');
    }
  }

  /// Starts listening for sacred prayers through the microphone
  Future<void> startPrayerListening() async {
    try {
      _isListeningPrayer = true;
      await _channel.invokeMethod('startPrayerListening');
      debugPrint('[Audio] Microphone sacred prayer listener active.');
    } catch (e) {
      debugPrint('[Audio] Error starting prayer listening: $e');
    }
  }

  /// Stops listening for sacred prayers
  Future<void> stopPrayerListening() async {
    try {
      _isListeningPrayer = false;
      await _channel.invokeMethod('stopPrayerListening');
      debugPrint('[Audio] Microphone sacred prayer listener stopped.');
    } catch (e) {
      debugPrint('[Audio] Error stopping prayer listening: $e');
    }
  }

  /// Updates radiation / EMF intensity and modulates Geiger clicking frequency
  void updateEmfLevel(double intensity) {
    _currentEmfIntensity = intensity.clamp(0.0, 1.0);
    _geigerLoopTimer?.cancel();

    if (_currentEmfIntensity > 0.12 && !_isMuted) {
      int intervalMs = (700 - (_currentEmfIntensity * 630)).round().clamp(70, 800);
      _geigerLoopTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        _playGeigerTick();
      });
    }
  }

  void _playGeigerTick() {
    HapticFeedback.selectionClick();
    playSfx('geiger_tick');
  }

  void playRavenWindowFlight() {
    playSfx('raven_window');
  }

  void playEntityWhispers() {
    playSfx('whisper_chills');
  }

  void playHolyDawnBell() {
    HapticFeedback.mediumImpact();
    playSfx('holy_dawn_bell');
  }

  void playJumpscareScreech() {
    HapticFeedback.heavyImpact();
    playSfx('jumpscare_screech');
  }

  void stop() {
    _geigerLoopTimer?.cancel();
    stopAmbient();
    stopPrayerListening();
  }
}
