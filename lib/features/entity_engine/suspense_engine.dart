import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/models/regional_profile.dart';
import '../../core/services/geo_adaptation_service.dart';

enum SuspenseState { idle, scanning, tensionBuilding, entityManifested, banished }

/// Suspense-based pacing engine:
/// Requires 25-60s scan time, darkness threshold > 0.7, and phone stillness.
class SuspenseEngine extends ChangeNotifier {
  static final SuspenseEngine _instance = SuspenseEngine._internal();
  factory SuspenseEngine() => _instance;
  SuspenseEngine._internal();

  SuspenseState _state = SuspenseState.idle;
  double _tensionProgress = 0.0; // 0.0 to 1.0
  bool _isPhoneStill = true;
  double _currentDarkness = 0.8; // Simulated ambient lighting
  EntitySpawnDefinition? _activeEntity;

  Timer? _pacingTimer;
  StreamSubscription? _accelSubscription;

  SuspenseState get state => _state;
  double get tensionProgress => _tensionProgress;
  EntitySpawnDefinition? get activeEntity => _activeEntity;

  void startPacingSession() {
    _state = SuspenseState.scanning;
    _tensionProgress = 0.0;
    _activeEntity = null;

    // Listen to accelerometer for phone stillness
    _accelSubscription?.cancel();
    try {
      _accelSubscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
        double motionMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        _isPhoneStill = motionMagnitude < 0.85; // Phone is held relatively still
      }, onError: (err) {
        debugPrint('[Sensor] Accelerometer event error: $err');
      });
    } catch (e) {
      debugPrint('[Sensor] Accelerometer failed to start: $e');
    }

    // Pacing loop
    _pacingTimer?.cancel();
    final randomTargetTime = 25 + Random().nextInt(35); // 25 to 60 seconds
    final stepInterval = const Duration(milliseconds: 500);
    double totalSteps = (randomTargetTime * 1000) / 500;

    _pacingTimer = Timer.periodic(stepInterval, (timer) {
      if (_currentDarkness >= 0.7 && _isPhoneStill) {
        _tensionProgress = (_tensionProgress + (1.0 / totalSteps)).clamp(0.0, 1.0);

        if (_tensionProgress >= 0.65 && _state != SuspenseState.tensionBuilding) {
          _state = SuspenseState.tensionBuilding;
          notifyListeners();
        }

        if (_tensionProgress >= 1.0) {
          _manifestEntity();
          timer.cancel();
        }
      } else {
        // Tension slowly fades if player shakes phone or points at light
        _tensionProgress = (_tensionProgress - 0.02).clamp(0.0, 1.0);
      }
      notifyListeners();
    });

    notifyListeners();
  }

  void _manifestEntity() {
    final pool = GeoAdaptationService().activeProfile.spawnPool;
    if (pool.isNotEmpty) {
      _activeEntity = pool[Random().nextInt(pool.length)];
      _state = SuspenseState.entityManifested;
      debugPrint('[EntityEngine] Manifested ${_activeEntity?.name} (${_activeEntity?.rarity})');
      notifyListeners();
    }
  }

  void banishEntity() {
    if (_state == SuspenseState.entityManifested) {
      _state = SuspenseState.banished;
      _tensionProgress = 0.0;
      _activeEntity = null;
      debugPrint('[EntityEngine] Entity banished by sacred relic!');
      notifyListeners();
    }
  }

  void stop() {
    _pacingTimer?.cancel();
    _accelSubscription?.cancel();
    _state = SuspenseState.idle;
    notifyListeners();
  }
}
