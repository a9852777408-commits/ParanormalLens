import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/models/regional_profile.dart';
import 'core/services/geo_adaptation_service.dart';
import 'features/camera/camera_shader_controller.dart';
import 'features/bestiary/bestiary_screen.dart';
import 'features/entity_engine/procedural_entity_spawner.dart';
import 'features/entity_engine/suspense_engine.dart';
import 'features/prank/prank_engine.dart';
import 'features/vision/sacred_relic_detector.dart';
import 'core/services/audio_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParanormalLensApp());
}

class ParanormalLensApp extends StatelessWidget {
  const ParanormalLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    final geo = GeoAdaptationService();
    final profile = geo.activeProfile;

    return MaterialApp(
      title: 'PL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: profile.aesthetic.background,
        primaryColor: profile.aesthetic.primary,
        colorScheme: ColorScheme.dark(
          primary: profile.aesthetic.primary,
          secondary: profile.aesthetic.accent,
        ),
        fontFamily: profile.aesthetic.fontFamily,
      ),
      home: const CameraViewfinderScreen(),
    );
  }
}

class CameraViewfinderScreen extends StatefulWidget {
  const CameraViewfinderScreen({super.key});

  @override
  State<CameraViewfinderScreen> createState() => _CameraViewfinderScreenState();
}

class _CameraViewfinderScreenState extends State<CameraViewfinderScreen> with SingleTickerProviderStateMixin {
  int _secretPrankTapCount = 0;
  late AnimationController _tickerController;

  // 3-Second Scanning Lock-on State
  Timer? _scanTimer;
  double _scanProgress = 0.0; // 0.0 to 1.0 (3 seconds = 1.0)
  bool _isLockingOn = false;

  // Sacred Exorcism Ritual State
  bool _isExorcismActive = false;
  double _exorcismAnimProgress = 0.0;
  Timer? _exorcismTimer;
  String _currentPrayerText = '«ДА ВОСКРЕСНЕТЪ БОГЪ, И РАЗТОЧАТСЯ ВРАЗИ ЕГО...»';

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1000),
    )..repeat();

    _initializeSubsystems();
    _startTargetingLoop();
  }

  void _initializeSubsystems() async {
    try {
      GeoAdaptationService().initializePassiveTier();
    } catch (e) {
      debugPrint('[Init] Geo error: $e');
    }
    try {
      await CameraShaderController().initialize();
    } catch (e) {
      debugPrint('[Init] Camera error: $e');
    }
    try {
      SacredRelicDetector().startInferenceLoop();
    } catch (e) {
      debugPrint('[Init] Relic detector error: $e');
    }
    try {
      ProceduralEntitySpawner().startCameraMotionMonitoring();
    } catch (e) {
      debugPrint('[Init] Spawner error: $e');
    }
    try {
      AudioService().initialize();
    } catch (e) {
      debugPrint('[Init] Audio error: $e');
    }
    try {
      SuspenseEngine().startPacingSession();
    } catch (e) {
      debugPrint('[Init] Suspense error: $e');
    }
  }

  /// 3-Second Scanning Check Loop: tracks if viewfinder crosshair is aimed at active ghost
  void _startTargetingLoop() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final spawner = ProceduralEntitySpawner();
      final entity = spawner.currentEntity;

      if (entity != null && entity.banishProgress <= 0.0) {
        // Distance from screen center (0.5, 0.5) to ghost position
        final distToCenter = (entity.screenPosition - const Offset(0.5, 0.5)).distance;

        // If crosshair is within ghost radius (0.24)
        if (distToCenter < 0.24) {
          if (!_isLockingOn) {
            _isLockingOn = true;
          }
          _scanProgress += 0.1 / 3.0; // 3 seconds to reach 1.0
          if (_scanProgress >= 1.0) {
            _scanProgress = 1.0;
            _onGhostScannedSuccessfully(entity);
          }
          if (mounted) setState(() {});
        } else {
          if (_isLockingOn) {
            _isLockingOn = false;
            _scanProgress = 0.0;
            if (mounted) setState(() {});
          }
        }
      } else {
        if (_isLockingOn) {
          _isLockingOn = false;
          _scanProgress = 0.0;
          if (mounted) setState(() {});
        }
      }
    });
  }

  void _onGhostScannedSuccessfully(ProceduralEntityInstance entity) {
    _scanProgress = 0.0;
    _isLockingOn = false;

    // Map archetype to Bestiary ID
    String bestiaryId = 'haunt_drone';
    if (entity.archetype == 0.0) bestiaryId = 'paul_first';
    if (entity.archetype == 1.0) bestiaryId = 'domestic_poltergeist';
    if (entity.archetype == 3.0) bestiaryId = 'flying_head_phantom';
    if (entity.archetype == 4.0) bestiaryId = 'white_cemetery_watcher';
    if (entity.archetype == 5.0) bestiaryId = 'inverted_raven';
    if (entity.archetype == 6.0) bestiaryId = 'haunt_drone';

    final isNew = BestiaryService().captureEntity(bestiaryId);

    HapticFeedback.heavyImpact();
    AudioService().playSfx('holy_dawn_bell');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B2E24),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isNew
                      ? '🎯 [АНОМАЛИЯ «${entity.entityName}» ИССЛЕДОВАНА И ДОБАВЛЕНА В БЕСТИАРИЙ!]'
                      : '✅ [ДАННЫЕ «${entity.entityName}» ОБНОВЛЕНЫ В АРХИВЕ]',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Sacred Exorcism Ritual with Orthodox Cross & Church Slavonic Prayers
  void _triggerSacredExorcismRitual() {
    final spawner = ProceduralEntitySpawner();
    if (!spawner.hasActiveEntity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Нет активных аномалий для освящения в поле зрения.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _isExorcismActive = true;
      _exorcismAnimProgress = 0.0;
      _currentPrayerText = '«ДА ВОСКРЕСНЕТЪ БОГЪ, И РАЗТОЧАТСЯ ВРАЗИ ЕГО...»';
    });

    // Sound: resounding dawn cathedral bells
    AudioService().playHolyDawnBell();
    HapticFeedback.heavyImpact();

    // Strobe camera torch if available
    final camera = CameraShaderController();
    camera.toggleTorch();

    _exorcismTimer?.cancel();
    const totalDurationMs = 2400;
    const intervalMs = 40;
    int ticks = 0;
    final totalTicks = totalDurationMs ~/ intervalMs;

    _exorcismTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      ticks++;
      _exorcismAnimProgress = (ticks / totalTicks).clamp(0.0, 1.0);

      if (_exorcismAnimProgress > 0.35 && _exorcismAnimProgress < 0.70) {
        _currentPrayerText = '«ЯКО ТАЕТЪ ВОСКЪ ОТЪ ЛИЦА ОГНЯ, ТАКО ДА ПОГИБНУТЪ БѢСИ...»';
      } else if (_exorcismAnimProgress >= 0.70) {
        _currentPrayerText = '«СВЯТЫЙ БОЖЕ, СВЯТЫЙ КРѢПКIЙ, СВЯТЫЙ БЕЗСМЕРТНЫЙ, ПОМИЛУЙ НАСЪ!»';
      }

      if (ticks >= totalTicks) {
        timer.cancel();
        setState(() {
          _isExorcismActive = false;
        });
        if (camera.isTorchOn) {
          camera.toggleTorch();
        }
      } else {
        if (mounted) setState(() {});
      }
    });

    // Banish entity with golden embers
    spawner.banishActiveEntity(onComplete: () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2E2414),
            content: Row(
              children: [
                Icon(Icons.flare, color: Colors.amber),
                SizedBox(width: 8),
                Text('✨ Сущность изгнана Животворящим Крестом и молитвой!'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _scanTimer?.cancel();
    _exorcismTimer?.cancel();
    super.dispose();
  }

  void _onHeaderTapped() {
    _secretPrankTapCount++;
    if (_secretPrankTapCount >= 5) {
      _secretPrankTapCount = 0;
      PrankEngine().armPrank(15);
      AudioService().playJumpscareScreech();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ [СКРЫТЫЙ СКРИМЕР АКТИВИРОВАН: 15 сек]'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = GeoAdaptationService().activeProfile;
    final camera = CameraShaderController();
    final spawner = ProceduralEntitySpawner();
    final prank = PrankEngine();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Stream + GPU Color Matrix + Shaders
          AnimatedBuilder(
            animation: Listenable.merge([camera, spawner, _tickerController]),
            builder: (context, child) {
              final isCameraReady = camera.isInitialized &&
                  camera.controller != null &&
                  camera.controller!.value.isInitialized;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Base Camera preview filtered with hardware GPU Color Matrix
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(camera.activeColorMatrix),
                    child: isCameraReady
                        ? CameraPreview(camera.controller!)
                        : const SimulatedViewfinder(),
                  ),

                  // GLSL Shader Post-Processing (Grain, Scanlines, Procedural Shadows)
                  CustomPaint(
                    painter: ShaderPostProcessingPainter(
                      shader: camera.getActiveShader(),
                      time: _tickerController.value * 1000.0,
                      entity: spawner.currentEntity,
                      shadowShader: camera.proceduralShadowShader,
                    ),
                  ),

                  // Dynamic Authentic Mode Overlays (with clean offsets, zero overlap!)
                  _buildModeSpecificOverlay(camera.activeFilter, spawner),

                  // 3-Second Locking-on Ring HUD (when aiming at ghost)
                  if (_isLockingOn && spawner.currentEntity != null)
                    _buildTargetLockRing(spawner.currentEntity!),

                  // Offline / Missing camera banner
                  if (!isCameraReady)
                    Positioned(
                      top: 100,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: profile.aesthetic.accent.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.videocam_off, color: profile.aesthetic.accent, size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Камера не подключена (эмулятор). Визор активен.',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ),
                            TextButton(
                              onPressed: () => camera.initialize(),
                              child: const Text('Повторить', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // 2. Sacred Exorcism Overlay (Golden Orthodox Cross & Prayer Chants)
          if (_isExorcismActive)
            _buildSacredExorcismRitualOverlay(),

          // 3. Top HUD Bar (Positioned strictly at top under SafeArea)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand & Secret Tap Header
                    GestureDetector(
                      onTap: _onHeaderTapped,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: profile.aesthetic.accent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.radar, color: profile.aesthetic.accent, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'PL',
                              style: TextStyle(
                                color: profile.aesthetic.accent,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Test mode badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A9D8F), Color(0xFF264653)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A9D8F)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_open, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'ВСЕ ФУНКЦИИ ОТКРЫТЫ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hardware Quick Controls
                    Row(
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            camera.isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                            color: camera.isTorchOn ? Colors.amber : Colors.white70,
                            size: 20,
                          ),
                          onPressed: () => camera.toggleTorch(),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            AudioService().isMuted ? Icons.volume_off : Icons.volume_up,
                            color: AudioService().isMuted ? Colors.redAccent : profile.aesthetic.accent,
                            size: 20,
                          ),
                          onPressed: () => setState(() => AudioService().toggleMute()),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.flip_camera_ios, color: profile.aesthetic.accent, size: 20),
                          onPressed: () => camera.toggleCameraLens(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom Controls (Zero-Overflow Responsive Layout with Sync Highlight!)
          Positioned(
            bottom: 12,
            left: 10,
            right: 10,
            child: SafeArea(
              child: AnimatedBuilder(
                animation: camera,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: 4 Filter Switcher Tabs (25% equal width each)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            _buildFilterTab(
                              label: 'Обычный',
                              icon: Icons.camera_alt,
                              filterType: ActiveFilterType.normal,
                              camera: camera,
                              profile: profile,
                            ),
                            _buildFilterTab(
                              label: 'VHS',
                              icon: Icons.videocam,
                              filterType: ActiveFilterType.vhs,
                              camera: camera,
                              profile: profile,
                            ),
                            _buildFilterTab(
                              label: 'Ночной',
                              icon: Icons.visibility,
                              filterType: ActiveFilterType.nightVision,
                              camera: camera,
                              profile: profile,
                            ),
                            _buildFilterTab(
                              label: 'Термо',
                              icon: Icons.thermostat,
                              filterType: ActiveFilterType.thermal,
                              camera: camera,
                              profile: profile,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Row 2: Action Toolbar (Радар, Бестиарий, Освятить - 33% equal width each)
                      Row(
                        children: [
                          // Radar Button
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14241B),
                                foregroundColor: profile.aesthetic.accent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: profile.aesthetic.accent.withOpacity(0.5)),
                                ),
                              ),
                              onPressed: () async {
                                final success = await GeoAdaptationService().activateGeomagneticRadar();
                                AudioService().updateEmfLevel(0.85);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? '📡 Радар сканирует аномалии в радиусе 500м...'
                                        : '⚠️ Включите геолокацию на устройстве'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.radar, size: 16),
                              label: const Text('Радар', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Bestiary Button
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E1E2E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.white24),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BestiaryScreen()),
                                );
                              },
                              icon: const Icon(Icons.auto_stories, size: 16),
                              label: const Text('Бестиарий', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Sacred Exorcism Button (Now triggers Prayers + Orthodox Cross!)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: profile.aesthetic.accent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _triggerSacredExorcismRitual,
                              icon: const Icon(Icons.flare, size: 16),
                              label: const Text('Освятить', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      const Text(
                        'ParanormalLens • Тестовый режим • Все сенсоры активны',
                        style: TextStyle(color: Colors.white30, fontSize: 8),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 5. Jumpscare Screamer Overlay
          AnimatedBuilder(
            animation: prank,
            builder: (context, child) {
              if (prank.state == PrankState.triggered) {
                return Container(
                  color: Colors.red.shade900,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sentiment_very_dissatisfied, size: 140, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'A A A H H H ! ! !',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required IconData icon,
    required ActiveFilterType filterType,
    required CameraShaderController camera,
    required RegionalProfile profile,
  }) {
    final isSelected = camera.activeFilter == filterType;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            camera.setFilter(filterType);
          });
          AudioService().playSfx('geiger_tick');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? profile.aesthetic.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.black : Colors.white70),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3-Second Scanning Target Lock Ring Overlay
  Widget _buildTargetLockRing(ProceduralEntityInstance entity) {
    return Positioned(
      left: MediaQuery.of(context).size.width * entity.screenPosition.dx - 45,
      top: MediaQuery.of(context).size.height * entity.screenPosition.dy - 45,
      child: SizedBox(
        width: 90,
        height: 90,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: _scanProgress,
              strokeWidth: 3.5,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              backgroundColor: Colors.white24,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.black87,
              child: Text(
                '${(_scanProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sacred Exorcism Ritual with Orthodox Cross & Church Slavonic Prayers
  Widget _buildSacredExorcismRitualOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Radiant Golden Orthodox Cross (☦) with Celestial Rays
            Stack(
              alignment: Alignment.center,
              children: [
                // Expanding celestial halo
                Container(
                  width: 180 * _exorcismAnimProgress + 60,
                  height: 180 * _exorcismAnimProgress + 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.55),
                        blurRadius: 40,
                        spreadRadius: 15,
                      ),
                      BoxShadow(
                        color: Colors.orangeAccent.withOpacity(0.4),
                        blurRadius: 80,
                        spreadRadius: 25,
                      ),
                    ],
                  ),
                ),
                // Glowing Orthodox Cross
                Icon(
                  Icons.church,
                  size: 110,
                  color: Colors.amber.shade200,
                ),
                const Text(
                  '☦',
                  style: TextStyle(
                    fontSize: 90,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.amber, blurRadius: 30),
                      Shadow(color: Colors.orange, blurRadius: 50),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Archaic Church Slavonic Exorcism Prayer Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 16),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'МОЛИТВА ЖИВОТВОРЯЩЕМУ КРЕСТУ',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentPrayerText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Authentic OSD overlays matching reference photo (with clean non-overlapping offsets!)
  Widget _buildModeSpecificOverlay(ActiveFilterType mode, ProceduralEntitySpawner spawner) {
    switch (mode) {
      case ActiveFilterType.normal:
        // Top-Left: Clean 1080p Moody Viewfinder + Framing Brackets + Vignette
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.95,
                  colors: [Colors.transparent, Color(0xAA000000)],
                ),
              ),
            ),
            const Positioned(
              top: 92, // Shifted down to prevent collision with top buttons!
              left: 18,
              child: Text(
                'NORMAL MODE • 1080p MOODY',
                style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1.0),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white38, size: 22),
                ),
              ),
            ),
          ],
        );

      case ActiveFilterType.vhs:
        // Top-Right: Low-Res VHS (360p Vintage, REC red dot, timestamp, SP)
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 92, // Shifted down cleanly below top buttons!
              left: 18,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'REC',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'NOV 13  12:44:31',
                    style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 92,
              right: 18,
              child: Text(
                'SP  -0:12:44',
                style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            const Positioned(
              bottom: 165, // Shifted up above bottom controls!
              left: 18,
              child: Text(
                'TRACKING: AUTO\n360p VINTAGE',
                style: TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ],
        );

      case ActiveFilterType.nightVision:
        // Bottom-Left: Military PVS-14 Monocular Circular Lens Aperture Vignette + Green Phosphor OSD
        return Stack(
          fit: StackFit.expand,
          children: [
            // Circular Optical Aperture Goggle Mask
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.72,
                  colors: [Colors.transparent, Color(0x66000000), Color(0xF8000000)],
                  stops: [0.65, 0.85, 1.0],
                ),
              ),
            ),
            const Positioned(
              top: 92, // Shifted cleanly below top buttons!
              left: 18,
              child: Text(
                'NIGHT VISION',
                style: TextStyle(color: Color(0xFF4EFE7B), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0),
              ),
            ),
            const Positioned(
              top: 92,
              right: 18,
              child: Row(
                children: [
                  Icon(Icons.battery_4_bar, color: Color(0xFF4EFE7B), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'IR-850nm ON',
                    style: TextStyle(color: Color(0xFF4EFE7B), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 165,
              left: 18,
              child: Text(
                'GAIN: +18dB • PHOSPHOR P-43',
                style: TextStyle(color: Color(0xFF4EFE7B), fontSize: 9, letterSpacing: 1.0),
              ),
            ),
          ],
        );

      case ActiveFilterType.thermal:
        // Bottom-Right: FLIR Ironbow Thermal False-Color & Dynamic Temperature / Anomalous Field Warning!
        final entity = spawner.currentEntity;
        final hasGhostInCrosshair = entity != null &&
            entity.banishProgress <= 0.0 &&
            (entity.screenPosition - const Offset(0.5, 0.5)).distance < 0.24;

        // Dynamic Temperature Calculation:
        // If pointing at ghost -> anomalous cold drop to -2.8°C / +1.2°C!
        // If pointing at normal surroundings -> 21.4°C ambient
        final dynamicTemp = hasGhostInCrosshair
            ? '-2.8°C'
            : '${(21.4 + (_tickerController.value * 2.0)).toStringAsFixed(1)}°C';

        return Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              top: 92,
              left: 18,
              child: Text(
                'THERMAL & HOLY GLOW',
                style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
            ),
            const Positioned(
              top: 92,
              right: 18,
              child: Text(
                'MAX 38.2°C • MIN 18.0°C',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),

            // Center Dynamic Temperature Reticle
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: hasGhostInCrosshair ? Colors.redAccent : Colors.amberAccent,
                        width: hasGhostInCrosshair ? 2.0 : 1.2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: hasGhostInCrosshair ? Colors.redAccent : Colors.amberAccent,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Dynamic temperature readout
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.black87,
                    child: Text(
                      dynamicTemp,
                      style: TextStyle(
                        color: hasGhostInCrosshair ? Colors.cyanAccent : Colors.amberAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // ANOMALOUS FIELD WARNING BADGE (when aimed at ghost!)
                  if (hasGhostInCrosshair) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amberAccent, width: 1.4),
                        boxShadow: const [
                          BoxShadow(color: Colors.red, blurRadius: 10, spreadRadius: 1),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '⚠️ АНОМАЛЬНОЕ ПОЛЕ ОБНАРУЖЕНО!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Vertical FLIR Ironbow Temperature Scale Legend Bar on the right
            Positioned(
              right: 12,
              top: 120,
              bottom: 165,
              child: Column(
                children: [
                  const Text('38°C', style: TextStyle(color: Colors.white, fontSize: 8)),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Container(
                      width: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white30, width: 0.8),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.yellow,
                            Colors.orange,
                            Colors.red,
                            Colors.purple,
                            Color(0xFF0A0033),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('18°C', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 8)),
                ],
              ),
            ),
          ],
        );
    }
  }
}

/// Simulated Viewfinder for emulator / devices without camera permissions
class SimulatedViewfinder extends StatelessWidget {
  const SimulatedViewfinder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C130F),
      child: CustomPaint(
        painter: SimulatedViewfinderPainter(),
      ),
    );
  }
}

class SimulatedViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1B2E24)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final cx = size.width / 2;
    final cy = size.height / 2;

    final crossPaint = Paint()
      ..color = const Color(0xFF335C45)
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(cx - 24, cy), Offset(cx + 24, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - 24), Offset(cx, cy + 24), crossPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFF264534)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(Offset(cx, cy), 48, ringPaint);
    canvas.drawCircle(Offset(cx, cy), 110, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
