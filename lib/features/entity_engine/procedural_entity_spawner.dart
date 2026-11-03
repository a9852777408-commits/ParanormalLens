import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ProceduralEntityInstance {
  final double seed;
  final double archetype; 
  // 0: Slender, 1: Lurker, 2: Mist, 3: Flying Head, 4: White Cemetery, 5: Inverted Raven, 6: Dark Glider (Haunt Drone), 7: Paul I
  double worldAzimuth; // Fixed horizontal angle in room (radians: -pi to +pi)
  double worldElevation; // Fixed vertical angle in room (radians: -pi/2 to +pi/2)
  Offset screenPosition; // Computed dynamically from world angles and device orientation
  double banishProgress;
  final String entityName;
  final String rarity;
  double distance; // in meters (approach depth)
  double scale;
  bool isScanned; // Prevents infinite scanning of the same active encounter

  ProceduralEntityInstance({
    required this.seed,
    required this.archetype,
    this.worldAzimuth = 0.0,
    this.worldElevation = 0.0,
    this.screenPosition = const Offset(0.5, 0.4),
    this.banishProgress = 0.0,
    required this.entityName,
    required this.rarity,
    this.distance = 3.5,
    this.scale = 1.0,
    this.isScanned = false,
  });
}

/// Advanced Procedural Spawner supporting:
/// - True 3D Spherical AR Spatial Anchoring (azimuth & elevation in physical room space).
/// - Universal Sensor Fusion: integrates hardware Gyroscope with Accelerometer gravity vector.
/// - Drift-free orientation tracking: phantoms stay firmly locked to physical coordinates in the room.
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

  // Real 3D Orientation in Room
  double _deviceYaw = 0.0; // Current phone heading (radians, accumulates from gyro)
  double _devicePitch = 0.0; // Current phone pitch from gravity (radians)
  bool _hasHardwareGyro = false;
  double _lastAccelX = 0.0;

  ProceduralEntityInstance? get currentEntity => _currentEntity;
  bool get hasActiveEntity => _currentEntity != null;
  double get deviceYaw => _deviceYaw;
  double get devicePitch => _devicePitch;

  // Camera field of view in portrait mode: ~62 deg horizontal (1.08 rad), ~79 deg vertical (1.38 rad)
  static const double hFov = 1.08;
  static const double vFov = 1.38;

  /// Mathematically projects fixed 3D room coordinates (azimuth, elevation) to 2D camera viewport (0.0 - 1.0)
  Offset projectToScreen(double azimuth, double elevation) {
    double dYaw = azimuth - _deviceYaw;
    // Normalize angular difference to -pi .. +pi
    while (dYaw > pi) {
      dYaw -= 2 * pi;
    }
    while (dYaw < -pi) {
      dYaw += 2 * pi;
    }

    double dPitch = elevation - _devicePitch;

    final sx = 0.5 + (dYaw / hFov);
    final sy = 0.5 - (dPitch / vFov);
    return Offset(sx, sy);
  }

  /// Converts a target 2D screen coordinate (e.g. from user tap or UI spawn) into fixed 3D room coordinates
  (double azimuth, double elevation) screenToWorld(Offset screenPos) {
    final azimuth = _deviceYaw + (screenPos.dx - 0.5) * hFov;
    final elevation = _devicePitch - (screenPos.dy - 0.5) * vFov;
    return (azimuth, elevation);
  }

  void _updateEntityScreenPosition() {
    if (_currentEntity != null && _currentEntity!.banishProgress <= 0.0) {
      _currentEntity!.screenPosition = projectToScreen(
        _currentEntity!.worldAzimuth,
        _currentEntity!.worldElevation,
      );
      notifyListeners();
    }
  }

  void startCameraMotionMonitoring() {
    _gyroSubscription?.cancel();
    _accelSubscription?.cancel();

    // 1. Gyroscope: integrates angular velocity with zero lag
    try {
      _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
        _hasHardwareGyro = true;
        final now = DateTime.now();
        final dt = _lastGyroTime == null
            ? 0.02
            : (now.difference(_lastGyroTime!).inMicroseconds / 1000000.0).clamp(0.005, 0.08);
        _lastGyroTime = now;

        // In portrait mode: turning left/right rotates around Y/Z axes
        final yawVelocity = (event.y * 0.70 + event.z * 0.70);
        _deviceYaw += yawVelocity * dt;

        _updateEntityScreenPosition();

        // Sudden pan check for random encounter
        double rotationRate = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (rotationRate > 2.6 && _currentEntity == null) {
          if (Random().nextDouble() < 0.25) {
            _spawnContextualOrRandomEntity();
          }
        }
      }, onError: (err) {
        debugPrint('[Sensor] Gyroscope stream error: $err');
      });
    } catch (e) {
      debugPrint('[Sensor] Gyroscope start error: $e');
    }

    // 2. Accelerometer: Absolute pitch reference from gravity vector
    try {
      _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        final gMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (gMagnitude > 2.0) {
          // Absolute tilt forward/backward (pitch) relative to gravity
          final measuredPitch = atan2(-event.y, sqrt(event.x * event.x + event.z * event.z)) - (pi / 2);
          _devicePitch = 0.90 * _devicePitch + 0.10 * measuredPitch;

          // If no hardware gyroscope detected on budget device (Xiaomi/Redmi fallback):
          if (!_hasHardwareGyro) {
            final dX = event.x - _lastAccelX;
            _deviceYaw += -dX * 0.05;
          }
          _lastAccelX = event.x;
        }

        _updateEntityScreenPosition();
      }, onError: (err) {
        debugPrint('[Sensor] Accelerometer stream error: $err');
      });
    } catch (e) {
      debugPrint('[Sensor] Accelerometer start error: $e');
    }
  }

  /// Archetype 6: "Темный Летун из темноты" (Haunt Drone gliding out of darkness towards the player)
  void triggerNightGlider({Offset? initialPosition}) {
    if (_currentEntity != null) return;

    final rand = Random();
    final side = rand.nextBool() ? 1.0 : -1.0;
    final (spawnAzimuth, spawnElevation) = initialPosition != null
        ? screenToWorld(initialPosition)
        : (_deviceYaw + side * 0.42, _devicePitch + 0.05);

    final spawnPos = projectToScreen(spawnAzimuth, spawnElevation);

    _currentEntity = ProceduralEntityInstance(
      seed: rand.nextDouble() * 100.0,
      archetype: 6.0, // Dark Glider / Haunt Drone
      worldAzimuth: spawnAzimuth,
      worldElevation: spawnElevation,
      screenPosition: spawnPos,
      entityName: 'Темный Летун (Выходящий из тьмы)',
      rarity: 'legendary',
      distance: 6.0,
      scale: 0.6,
    );

    debugPrint('[Entity] Haunt Drone emerged at azimuth $spawnAzimuth, pos $spawnPos!');
    notifyListeners();

    // Glides smoothly towards the player out of the dark depth
    _entityApproachTimer?.cancel();
    _entityApproachTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_currentEntity != null && _currentEntity!.archetype == 6.0) {
        if (_currentEntity!.distance > 1.2) {
          _currentEntity!.distance -= 0.035;
          _currentEntity!.scale = (3.5 / _currentEntity!.distance).clamp(0.6, 1.4);
          _updateEntityScreenPosition();
        } else {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Archetype 5: Inverted Raven
  void triggerWindowRavenEncounter({Offset? initialPosition}) {
    if (_currentEntity != null) return;

    final rand = Random();
    final side = rand.nextBool() ? 1.0 : -1.0;
    final (spawnAzimuth, spawnElevation) = initialPosition != null
        ? screenToWorld(initialPosition)
        : (_deviceYaw + side * 0.35, _devicePitch + 0.22); // Perched up on window frame

    final spawnPos = projectToScreen(spawnAzimuth, spawnElevation);

    _currentEntity = ProceduralEntityInstance(
      seed: rand.nextDouble() * 50.0,
      archetype: 5.0, // Inverted Raven
      worldAzimuth: spawnAzimuth,
      worldElevation: spawnElevation,
      screenPosition: spawnPos,
      entityName: 'Инвертированный Ворон',
      rarity: 'rare',
      distance: 2.5,
    );

    debugPrint('[Entity] Inverted Raven perched upside-down at $spawnPos!');
    notifyListeners();

    _entityApproachTimer?.cancel();
    _entityApproachTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentEntity != null && _currentEntity!.archetype == 5.0) {
        _currentEntity!.worldElevation -= 0.015; // Plummets downwards in 3D room
        _updateEntityScreenPosition();

        if (_currentEntity!.worldElevation < _devicePitch - 0.6) {
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
    final (spawnAzimuth, spawnElevation) = initialPosition != null
        ? screenToWorld(initialPosition)
        : (_deviceYaw + side * 0.38, _devicePitch + 0.06);

    final spawnPos = projectToScreen(spawnAzimuth, spawnElevation);

    _currentEntity = ProceduralEntityInstance(
      seed: 1754.0,
      archetype: 7.0, // Ghost of Paul I
      worldAzimuth: spawnAzimuth,
      worldElevation: spawnElevation,
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
    final (spawnAzimuth, spawnElevation) = initialPosition != null
        ? screenToWorld(initialPosition)
        : (_deviceYaw + side * 0.40, _devicePitch + 0.08);

    final spawnPos = projectToScreen(spawnAzimuth, spawnElevation);

    _currentEntity = ProceduralEntityInstance(
      seed: rand.nextDouble() * 88.0,
      archetype: 3.0, // Flying Morok Skull
      worldAzimuth: spawnAzimuth,
      worldElevation: spawnElevation,
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
  void triggerCemeteryWhiteWatcher({Offset? initialPosition}) {
    if (_currentEntity != null) return;

    final rand = Random();
    final side = rand.nextBool() ? 1.0 : -1.0;
    final (spawnAzimuth, spawnElevation) = initialPosition != null
        ? screenToWorld(initialPosition)
        : (_deviceYaw + side * 0.45, _devicePitch + 0.02);

    final spawnPos = projectToScreen(spawnAzimuth, spawnElevation);

    _currentEntity = ProceduralEntityInstance(
      seed: 777.0,
      archetype: 4.0, // White Cemetery Watcher
      worldAzimuth: spawnAzimuth,
      worldElevation: spawnElevation,
      screenPosition: spawnPos,
      entityName: 'Белый Кладбищенский Страж',
      rarity: 'mythic',
      distance: 3.2,
    );

    debugPrint('[Entity] Cemetery White Watcher manifested at $spawnPos. Absolute stillness.');
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
    final spawnAzimuth = _deviceYaw + side * (0.35 + rand.nextDouble() * 0.30);
    final spawnElevation = _devicePitch + (rand.nextDouble() * 0.20 - 0.05);
    final spawnPos = projectToScreen(spawnAzimuth, spawnElevation);

    _currentEntity = ProceduralEntityInstance(
      seed: rand.nextDouble() * 100.0,
      archetype: archetype,
      worldAzimuth: spawnAzimuth,
      worldElevation: spawnElevation,
      screenPosition: spawnPos,
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
            _updateEntityScreenPosition();
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
      triggerCemeteryWhiteWatcher(initialPosition: const Offset(0.40, 0.38));
    } else if (archetype == 5.0) {
      triggerWindowRavenEncounter(initialPosition: const Offset(0.50, 0.25));
    } else if (archetype == 3.0) {
      triggerFlyingMorok(initialPosition: const Offset(0.60, 0.32));
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
