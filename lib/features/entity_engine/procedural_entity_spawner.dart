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
  bool isScanned; // Prevents infinite scanning of the same active encounter

  ProceduralEntityInstance({
    required this.seed,
    required this.archetype,
    required this.screenPosition,
    this.banishProgress = 0.0,
    required this.entityName,
    required this.rarity,
    this.distance = 3.5,
    this.scale = 1.0,
    this.isScanned = false,
  });
}

/// Advanced Procedural Spawner supporting:
/// - Real-time 3D AR Gyroscope & Accelerometer spatial anchoring (phantom stays anchored in room space upon phone rotation).
/// - "Темный Летун из темноты" (Haunt Drone archetype gliding from darkness towards the viewer).
/// - Inverted Raven flying downwards from window frames.
/// - Motionless milky-white watcher when near cemeteries.
class ProceduralEntitySpawner extends ChangeNotifier {
  static final ProceduralEntitySpawner _instance = ProceduralEntitySpawner._internal();
  factory ProceduralEntitySpawner() => _instance;
  ProceduralEntitySpawner._internal();

  ProceduralEntityInstance? _currentEntity;
  StreamSubscription? _gyroSubscription;
  StreamSubscription? _accelSubscription;
  Timer? _banishAnimationTimer;
  Timer? _entityApproachTimer;
  DateTime? _lastGyroTime;
  double? _lastAx;
  double? _lastAy;

  ProceduralEntityInstance? get currentEntity => _currentEntity;
  bool get hasActiveEntity => _currentEntity != null;

  void startCameraMotionMonitoring() {
    _gyroSubscription?.cancel();
    _accelSubscription?.cancel();

    // 1. Gyroscope Monitoring (Angular velocity on phones with hardware gyro)
    try {
      _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
        final now = DateTime.now();
        final dt = _lastGyroTime == null
            ? 0.02
            : (now.difference(_lastGyroTime!).inMicroseconds / 1000000.0).clamp(0.005, 0.06);
        _lastGyroTime = now;

        if (_currentEntity != null && _currentEntity!.banishProgress <= 0.0) {
          const sensitivityX = 2.10;
          const sensitivityY = 1.85;

          final yawRate = (event.y * 0.75 + event.z * 0.65);
          final pitchRate = event.x;

          final dxShift = -yawRate * dt * sensitivityX;
          final dyShift = pitchRate * dt * sensitivityY;

          _currentEntity!.screenPosition = Offset(
            _currentEntity!.screenPosition.dx + dxShift,
            _currentEntity!.screenPosition.dy + dyShift,
          );
          notifyListeners();
        }

        // Motion Spawning Trigger on sudden pans
        double rotationRate = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (rotationRate > 2.2 && _currentEntity == null) {
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

    // 2. Accelerometer Fallback & Motion Fusion (works on 100% of Android phones!)
    try {
      _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (_currentEntity != null && _currentEntity!.banishProgress <= 0.0) {
          if (_lastAx != null && _lastAy != null) {
            final dAx = event.x - _lastAx!;
            final dAy = event.y - _lastAy!;

            // Significant tilt/turn movements shift entity in 3D room
            if (dAx.abs() > 0.04 || dAy.abs() > 0.04) {
              final dxShift = -dAx * 0.038;
              final dyShift = dAy * 0.038;

              _currentEntity!.screenPosition = Offset(
                _currentEntity!.screenPosition.dx + dxShift,
                _currentEntity!.screenPosition.dy + dyShift,
              );
              notifyListeners();
            }
          }
          _lastAx = event.x;
          _lastAy = event.y;
        } else {
          _lastAx = event.x;
          _lastAy = event.y;
        }
      }, onError: (err) {
        debugPrint('[Sensor] Accelerometer event error: $err');
      });
    } catch (e) {
      debugPrint('[Sensor] Accelerometer failed to start: $e');
    }
  }

  /// Archetype 6: "Темный Летун из темноты" (Haunt Drone gliding out of darkness towards the player)
  void triggerNightGlider({Offset? initialPosition}) {
    if (_currentEntity != null) return;

    final rand = Random();
    final side = rand.nextBool() ? 1.0 : -1.0;
    final spawnPos = initialPosition ?? Offset(0.5 + side * 0.32, 0.35);

    _currentEntity = ProceduralEntityInstance(
      seed: rand.nextDouble() * 100.0,
      archetype: 6.0, // Dark Glider / Haunt Drone
      screenPosition: spawnPos,
      entityName: 'Темный Летун (Выходящий из тьмы)',
      rarity: 'legendary',
      distance: 6.0,
      scale: 0.6,
    );

    debugPrint('[Entity] Haunt Drone emerged from deep shadows at $spawnPos!');
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
      screenPosition: const Offset(0.5, 0.20),
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

        if (_currentEntity!.screenPosition.dy > 1.3) {
          timer.cancel();
          _currentEntity = null;
          notifyListeners();
        }
      }
    });
  }

  /// Archetype 7: Призрак Павла I (Ghost of Emperor Paul I with Candle)
  void triggerPaulFirst({Offset? initialPosition}) {
    if (_currentEntity != null) return;

    final rand = Random();
    final side = rand.nextBool() ? 1.0 : -1.0;
    final spawnPos = initialPosition ?? Offset(0.5 + side * 0.28, 0.36);

    _currentEntity = ProceduralEntityInstance(
      seed: 1754.0,
      archetype: 7.0, // Ghost of Paul I
      screenPosition: spawnPos,
      entityName: 'Призрак Павла I (Михайловский замок)',
      rarity: 'legendary',
      distance: 3.0,
      scale: 1.0,
    );

    debugPrint('[Entity] Ghost of Paul I manifested with candle at $spawnPos!');
    notifyListeners();
  }

  /// Archetype 3: Летающий Морок (Floating Skull with Smoke Trail)
  void triggerFlyingMorok({Offset? initialPosition}) {
    if (_currentEntity != null) return;

    final rand = Random();
    final side = rand.nextBool() ? 1.0 : -1.0;
    final spawnPos = initialPosition ?? Offset(0.5 + side * 0.30, 0.32);

    _currentEntity = ProceduralEntityInstance(
      seed: rand.nextDouble() * 88.0,
      archetype: 3.0, // Flying Morok Skull
      screenPosition: spawnPos,
      entityName: 'Летающий Морок (Череп в дыму)',
      rarity: 'uncommon',
      distance: 3.2,
      scale: 0.95,
    );

    debugPrint('[Entity] Flying Morok manifested with smoke at $spawnPos!');
    notifyListeners();
  }

  /// Archetype 4: White Cemetery Watcher
  void triggerCemeteryWhiteWatcher() {
    if (_currentEntity != null) return;

    final rand = Random();
    final side = rand.nextBool() ? 1.0 : -1.0;

    _currentEntity = ProceduralEntityInstance(
      seed: 777.0,
      archetype: 4.0, // White Cemetery Watcher
      screenPosition: Offset(0.5 + side * 0.35, 0.38),
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

    if (roll < 0.25) {
      archetype = 6.0;
      name = 'Темный Летун (Из темноты)';
      rarity = 'legendary';
    } else if (roll < 0.45) {
      archetype = 7.0;
      name = 'Призрак Павла I';
      rarity = 'legendary';
    } else if (roll < 0.65) {
      archetype = 3.0;
      name = 'Летающий Морок (Череп со шлейфом)';
      rarity = 'uncommon';
    } else if (roll < 0.85) {
      archetype = 5.0;
      name = 'Инвертированный Ворон';
      rarity = 'rare';
    } else {
      archetype = 4.0;
      name = 'Белый Кладбищенский Страж';
      rarity = 'mythic';
    }

    // Spawn spatially positioned in room (off-center: requiring player to look around)
    final side = rand.nextBool() ? 1.0 : -1.0;
    final spawnX = (0.5 + side * (0.28 + rand.nextDouble() * 0.25));
    final spawnY = (0.30 + rand.nextDouble() * 0.20);

    _currentEntity = ProceduralEntityInstance(
      seed: rand.nextDouble() * 100.0,
      archetype: archetype,
      screenPosition: Offset(spawnX, spawnY),
      entityName: name,
      rarity: rarity,
      distance: archetype == 6.0 ? 5.5 : 3.0,
      scale: archetype == 6.0 ? 0.7 : 1.0,
    );

    if (archetype == 6.0) {
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

    const duration = Duration(milliseconds: 2200);
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

  /// Force spawn for testing or direct summon from Bestiary
  void forceSpawnEntity(double archetype) {
    _currentEntity = null;
    notifyListeners();

    if (archetype == 6.0) {
      triggerNightGlider(initialPosition: const Offset(0.35, 0.35));
    } else if (archetype == 7.0) {
      triggerPaulFirst(initialPosition: const Offset(0.50, 0.36));
    } else if (archetype == 4.0) {
      triggerCemeteryWhiteWatcher();
    } else if (archetype == 5.0) {
      triggerWindowRavenEncounter();
    } else if (archetype == 3.0) {
      triggerFlyingMorok();
    } else {
      _spawnContextualOrRandomEntity();
    }
  }

  void stop() {
    _gyroSubscription?.cancel();
    _accelSubscription?.cancel();
    _banishAnimationTimer?.cancel();
    _entityApproachTimer?.cancel();
    _currentEntity = null;
    notifyListeners();
  }
}
