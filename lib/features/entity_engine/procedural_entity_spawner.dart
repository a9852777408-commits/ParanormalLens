import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ProceduralEntityInstance {
  final double seed;
  final double archetype; 
  // 0: Slender, 1: Lurker, 2: Mist, 3: Flying Head, 4: White Cemetery, 5: Inverted Raven
  Offset screenPosition;
  double banishProgress;
  final String entityName;
  final String rarity;

  ProceduralEntityInstance({
    required this.seed,
    required this.archetype,
    required this.screenPosition,
    this.banishProgress = 0.0,
    required this.entityName,
    required this.rarity,
  });
}

/// Advanced Procedural Spawner supporting contextual encounters:
/// - Inverted Raven flying downwards from window frames.
/// - Motionless milky-white watcher when near cemeteries.
/// - Flying severed head drifting with a black smoky tail.
class ProceduralEntitySpawner extends ChangeNotifier {
  static final ProceduralEntitySpawner _instance = ProceduralEntitySpawner._internal();
  factory ProceduralEntitySpawner() => _instance;
  ProceduralEntitySpawner._internal();

  ProceduralEntityInstance? _currentEntity;
  StreamSubscription? _gyroSubscription;
  Timer? _banishAnimationTimer;
  Timer? _ravenFlightTimer;

  ProceduralEntityInstance? get currentEntity => _currentEntity;
  bool get hasActiveEntity => _currentEntity != null;

  void startCameraMotionMonitoring() {
    _gyroSubscription?.cancel();
    try {
      _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
        double rotationRate = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

        if (rotationRate > 1.8 && _currentEntity == null) {
          if (Random().nextDouble() < 0.35) {
            _spawnContextualOrRandomEntity();
          }
        }
      }, onError: (err) {
        debugPrint('[Sensor] Gyroscope event error: $err');
      });
    } catch (e) {
      debugPrint('[Sensor] Gyroscope monitoring failed to start: $e');
    }
  }

  /// 1. Triggered when Computer Vision spots a window in the upper frame
  void triggerWindowRavenEncounter() {
    if (_currentEntity != null) return;

    // Spawns perched at the top frame of the window
    _currentEntity = ProceduralEntityInstance(
      seed: Random().nextDouble() * 50.0,
      archetype: 5.0, // Inverted Raven
      screenPosition: const Offset(0.5, 0.25),
      entityName: 'Инвертированный Ворон',
      rarity: 'rare',
    );

    debugPrint('[Entity] Inverted Raven perched upside-down in window frame!');
    notifyListeners();

    // After 1.2 seconds of stillness, raven detaches and flies DOWNWARDS into the abyss
    _ravenFlightTimer?.cancel();
    _ravenFlightTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentEntity != null && _currentEntity!.archetype == 5.0) {
        // Fly downwards towards y = 1.2
        _currentEntity!.screenPosition = Offset(
          _currentEntity!.screenPosition.dx + 0.003,
          _currentEntity!.screenPosition.dy + 0.018, // Plummets downwards
        );
        notifyListeners();

        if (_currentEntity!.screenPosition.dy > 1.1) {
          timer.cancel();
          _currentEntity = null;
          notifyListeners();
        }
      }
    });
  }

  /// 2. Triggered when Geo-Radar detects a cemetery / graveyard location
  void triggerCemeteryWhiteWatcher() {
    if (_currentEntity != null) return;

    _currentEntity = ProceduralEntityInstance(
      seed: 777.0,
      archetype: 4.0, // White Cemetery Watcher
      screenPosition: const Offset(0.5, 0.45), // Motionless in center
      entityName: 'Белый Кладбищенский Страж',
      rarity: 'mythic',
    );

    debugPrint('[Entity] Cemetery White Watcher manifested. Absolute stillness.');
    notifyListeners();
  }

  /// 3. Triggered during general camera pans
  void _spawnContextualOrRandomEntity() {
    final rand = Random();
    double roll = rand.nextDouble();

    double archetype;
    String name;

    if (roll < 0.30) {
      archetype = 3.0; // Flying Head with Black Trail
      name = 'Летающий Морок (Голова со шлейфом)';
    } else if (roll < 0.65) {
      archetype = 0.0; // Slender Peeker
      name = 'Теневой Человек';
    } else {
      archetype = 1.0; // Low Lurker
      name = 'Барабашка';
    }

    _currentEntity = ProceduralEntityInstance(
      seed: rand.nextDouble() * 100.0,
      archetype: archetype,
      screenPosition: Offset(
        0.35 + rand.nextDouble() * 0.3,
        0.40 + rand.nextDouble() * 0.2,
      ),
      entityName: name,
      rarity: 'uncommon',
    );

    notifyListeners();
  }

  /// Banishment by sacred relics
  void banishActiveEntity({required VoidCallback onComplete}) {
    if (_currentEntity == null) return;

    _banishAnimationTimer?.cancel();
    _ravenFlightTimer?.cancel();

    const duration = Duration(milliseconds: 1400);
    const interval = Duration(milliseconds: 30);
    int totalTicks = duration.inMilliseconds ~/ interval.inMilliseconds;
    int currentTick = 0;

    _banishAnimationTimer = Timer.periodic(interval, (timer) {
      currentTick++;
      if (_currentEntity != null) {
        _currentEntity!.banishProgress = (currentTick / totalTicks).clamp(0.0, 1.0);
        notifyListeners();
      }

      if (currentTick >= totalTicks) {
        timer.cancel();
        _currentEntity = null;
        notifyListeners();
        onComplete();
      }
    });
  }

  void stop() {
    _gyroSubscription?.cancel();
    _banishAnimationTimer?.cancel();
    _ravenFlightTimer?.cancel();
    _currentEntity = null;
    notifyListeners();
  }
}
