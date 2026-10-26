import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ProceduralEntityInstance {
  final double seed;
  final double archetype; 
  // 0: Slender, 1: Lurker, 2: Mist, 3: Flying Head, 4: White Cemetery, 5: Inverted Raven, 6: Dark Glider (Haunt Drone)
  Offset screenPosition;
  double banishProgress;
  final String entityName;
  final String rarity;
  double distance; // in meters (approach depth)
  double scale;

  ProceduralEntityInstance({
    required this.seed,
    required this.archetype,
    required this.screenPosition,
    this.banishProgress = 0.0,
    required this.entityName,
    required this.rarity,
    this.distance = 3.5,
    this.scale = 1.0,
  });
}

/// Advanced Procedural Spawner supporting:
/// - Real-time 3D AR Gyroscope spatial anchoring (phantom stays anchored in room space upon phone rotation).
/// - "Темный Летун из темноты" (Haunt Drone archetype gliding from darkness towards the viewer).
/// - Inverted Raven flying downwards from window frames.
/// - Motionless milky-white watcher when near cemeteries.
class ProceduralEntitySpawner extends ChangeNotifier {
  static final ProceduralEntitySpawner _instance = ProceduralEntitySpawner._internal();
  factory ProceduralEntitySpawner() => _instance;
  ProceduralEntitySpawner._internal();

  ProceduralEntityInstance? _currentEntity;
  StreamSubscription? _gyroSubscription;
  Timer? _banishAnimationTimer;
  Timer? _entityApproachTimer;
  DateTime? _lastGyroTime;

  ProceduralEntityInstance? get currentEntity => _currentEntity;
  bool get hasActiveEntity => _currentEntity != null;

  void startCameraMotionMonitoring() {
    _gyroSubscription?.cancel();
    try {
      _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
        final now = DateTime.now();
        final dt = _lastGyroTime == null
            ? 0.02
            : (now.difference(_lastGyroTime!).inMicroseconds / 1000000.0).clamp(0.005, 0.06);
        _lastGyroTime = now;

        // 1. AR Spatial Anchoring: If an entity is present, anchor it to 3D room coordinates
        if (_currentEntity != null && _currentEntity!.banishProgress <= 0.0) {
          // In phone portrait:
          // event.y is yaw angular rate (horizontal rotation)
          // event.x is pitch angular rate (vertical tilt)
          const sensitivity = 0.82;
          final dxShift = -event.y * dt * sensitivity;
          final dyShift = event.x * dt * sensitivity;

          _currentEntity!.screenPosition = Offset(
            _currentEntity!.screenPosition.dx + dxShift,
            _currentEntity!.screenPosition.dy + dyShift,
          );
          notifyListeners();
        }

        // 2. Motion Spawning Trigger: sudden camera pans when no entity is active
        double rotationRate = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (rotationRate > 1.9 && _currentEntity == null) {
          if (Random().nextDouble() < 0.38) {
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

  /// Archetype 6: "Темный Летун из темноты" (Haunt Drone gliding out of darkness towards the player)
  void triggerNightGlider({Offset? initialPosition}) {
    if (_currentEntity != null) return;

    _currentEntity = ProceduralEntityInstance(
      seed: Random().nextDouble() * 100.0,
      archetype: 6.0, // Dark Glider / Haunt Drone
      screenPosition: initialPosition ?? const Offset(0.5, 0.35),
      entityName: 'Темный Летун (Выходящий из тьмы)',
      rarity: 'legendary',
      distance: 6.0,
      scale: 0.6,
    );

    debugPrint('[Entity] Haunt Drone emerged from deep shadows!');
    notifyListeners();

    // Glides smoothly towards the player out of the dark depth
    _entityApproachTimer?.cancel();
    _entityApproachTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_currentEntity != null && _currentEntity!.archetype == 6.0) {
        if (_currentEntity!.distance > 1.2) {
          _currentEntity!.distance -= 0.035;
          _currentEntity!.scale = (3.5 / _currentEntity!.distance).clamp(0.6, 1.4);
          notifyListeners();
        } else {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Archetype 5: Inverted Raven
  void triggerWindowRavenEncounter() {
    if (_currentEntity != null) return;

    _currentEntity = ProceduralEntityInstance(
      seed: Random().nextDouble() * 50.0,
      archetype: 5.0, // Inverted Raven
      screenPosition: const Offset(0.5, 0.25),
      entityName: 'Инвертированный Ворон',
      rarity: 'rare',
      distance: 2.5,
    );

    debugPrint('[Entity] Inverted Raven perched upside-down in window frame!');
    notifyListeners();

    _entityApproachTimer?.cancel();
    _entityApproachTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentEntity != null && _currentEntity!.archetype == 5.0) {
        _currentEntity!.screenPosition = Offset(
          _currentEntity!.screenPosition.dx + 0.003,
          _currentEntity!.screenPosition.dy + 0.018, // Plummets downwards
        );
        notifyListeners();

        if (_currentEntity!.screenPosition.dy > 1.2) {
          timer.cancel();
          _currentEntity = null;
          notifyListeners();
        }
      }
    });
  }

  /// Archetype 4: White Cemetery Watcher
  void triggerCemeteryWhiteWatcher() {
    if (_currentEntity != null) return;

    _currentEntity = ProceduralEntityInstance(
      seed: 777.0,
      archetype: 4.0, // White Cemetery Watcher
      screenPosition: const Offset(0.5, 0.42),
      entityName: 'Белый Кладбищенский Страж',
      rarity: 'mythic',
      distance: 3.2,
    );

    debugPrint('[Entity] Cemetery White Watcher manifested. Absolute stillness.');
    notifyListeners();
  }

  /// Contextual / Random Entity Spawner
  void _spawnContextualOrRandomEntity() {
    final rand = Random();
    double roll = rand.nextDouble();

    double archetype;
    String name;
    String rarity;

    if (roll < 0.28) {
      // Haunt Drone / Glider from the dark
      archetype = 6.0;
      name = 'Темный Летун (Из темноты)';
      rarity = 'legendary';
    } else if (roll < 0.50) {
      // Flying Head with smoke trail
      archetype = 3.0;
      name = 'Летающий Морок (Голова со шлейфом)';
      rarity = 'uncommon';
    } else if (roll < 0.75) {
      // Slender Peeker
      archetype = 0.0;
      name = 'Теневой Человек';
      rarity = 'common';
    } else {
      // Low Lurker
      archetype = 1.0;
      name = 'Барабашка';
      rarity = 'common';
    }

    _currentEntity = ProceduralEntityInstance(
      seed: rand.nextDouble() * 100.0,
      archetype: archetype,
      screenPosition: Offset(
        0.35 + rand.nextDouble() * 0.3,
        0.35 + rand.nextDouble() * 0.2,
      ),
      entityName: name,
      rarity: rarity,
      distance: archetype == 6.0 ? 5.5 : 3.0,
      scale: archetype == 6.0 ? 0.7 : 1.0,
    );

    if (archetype == 6.0) {
      // Start gliding approach towards the viewer
      _entityApproachTimer?.cancel();
      _entityApproachTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
        if (_currentEntity != null && _currentEntity!.archetype == 6.0) {
          if (_currentEntity!.distance > 1.2) {
            _currentEntity!.distance -= 0.035;
            _currentEntity!.scale = (3.5 / _currentEntity!.distance).clamp(0.6, 1.4);
            notifyListeners();
          } else {
            timer.cancel();
          }
        } else {
          timer.cancel();
        }
      });
    }

    notifyListeners();
  }

  /// Banishment by sacred exorcism ritual
  void banishActiveEntity({required VoidCallback onComplete}) {
    if (_currentEntity == null) return;

    _banishAnimationTimer?.cancel();
    _entityApproachTimer?.cancel();

    const duration = Duration(milliseconds: 2200); // 2.2s for solemn prayer & cross ritual
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

  /// Force spawn for testing or direct summon
  void forceSpawnEntity(double archetype) {
    _currentEntity = null;
    notifyListeners();

    if (archetype == 6.0) {
      triggerNightGlider();
    } else if (archetype == 4.0) {
      triggerCemeteryWhiteWatcher();
    } else if (archetype == 5.0) {
      triggerWindowRavenEncounter();
    } else {
      _spawnContextualOrRandomEntity();
    }
  }

  void stop() {
    _gyroSubscription?.cancel();
    _banishAnimationTimer?.cancel();
    _entityApproachTimer?.cancel();
    _currentEntity = null;
    notifyListeners();
  }
}
