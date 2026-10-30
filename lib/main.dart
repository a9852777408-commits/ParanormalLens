import 'dart:async';
import 'dart:math';
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
import 'features/vision/cross_radiance_overlay.dart';
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

  // Microphone Voice & Prayer Detection State
  bool _isPrayerActive = false;
  double _voiceEnergy = 0.0;
  String _detectedPrayerPhrase = '';
  Timer? _prayerDisplayTimer;

  // Cross in Frame Detection & Golden Radiance State
  bool _isCrossInFrame = false;
  Offset _crossCenter = const Offset(0.5, 0.42);
  Timer? _crossBanishTimer;
  DateTime _lastCrossChimeTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Sacred Exorcism Visual Effect State
  bool _isExorcismActive = false;
  double _exorcismAnimProgress = 0.0;
  Timer? _exorcismTimer;
  String _currentPrayerText = '«ДА ВОСКРЕСНЕТЪ БОГЪ, И РАЗТОЧАТСЯ ВРАЗИ ЕГО...»';
  String _exorcismSource = 'voice'; // 'voice' or 'cross'

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

    // Initialize Cross & Sacred Relics Vision Detector
    try {
      final relicDetector = SacredRelicDetector();
      relicDetector.startInferenceLoop();
      relicDetector.onCrossDetected = (center, box) {
        if (!_isCrossInFrame || (_crossCenter - center).distance > 0.04) {
          _isCrossInFrame = true;
          _crossCenter = center;
          _onCrossDetectedInFrame(center);
          if (mounted) setState(() {});
        }
      };
      relicDetector.onCrossLost = () {
        if (_isCrossInFrame) {
          _isCrossInFrame = false;
          _crossBanishTimer?.cancel();
          if (mounted) setState(() {});
        }
      };
    } catch (e) {
      debugPrint('[Init] Relic detector error: $e');
    }

    try {
      ProceduralEntitySpawner().startCameraMotionMonitoring();
    } catch (e) {
      debugPrint('[Init] Spawner error: $e');
    }

    // Initialize Native Audio Service and Microphone Prayer Listener
    try {
      final audio = AudioService();
      audio.initialize();
      audio.onPrayerDetected = (phrase, source) {
        _onPrayerHeardFromMicrophone(phrase, source);
      };
      audio.onVoiceEnergy = (energy) {
        if (mounted) {
          setState(() {
            _voiceEnergy = energy;
          });
        }
      };
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
  /// Stops infinite scanning: checks `!entity.isScanned` and marks `entity.isScanned = true`
  void _startTargetingLoop() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final spawner = ProceduralEntitySpawner();
      final entity = spawner.currentEntity;

      // Only scan un-researched entities in the current encounter
      if (entity != null && entity.banishProgress <= 0.0 && !entity.isScanned) {
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
            entity.isScanned = true; // Mark as scanned! Halts infinite loop!
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

  /// Called when crosshair was locked on ghost for 3 continuous seconds
  void _onGhostScannedSuccessfully(ProceduralEntityInstance entity) {
    _isLockingOn = false;
    _scanProgress = 0.0;

    AudioService().playHolyDawnBell();
    HapticFeedback.heavyImpact();

    final bestiaryId = entity.archetype == 6.0
        ? 'haunt_drone'
        : entity.archetype == 5.0
            ? 'inverted_raven'
            : entity.archetype == 4.0
                ? 'white_cemetery_watcher'
                : 'shadow_stalker';

    final isNew = BestiaryService().captureEntity(bestiaryId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 125, left: 16, right: 16),
          backgroundColor: const Color(0xFF1B2E1B),
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

  /// 1. Microphone Prayer Detection Handler
  void _onPrayerHeardFromMicrophone(String phrase, String source) {
    final spawner = ProceduralEntitySpawner();
    final hasGhost = spawner.hasActiveEntity;

    setState(() {
      _isPrayerActive = true;
      _detectedPrayerPhrase = phrase;
      _currentPrayerText = phrase.contains('«') ? phrase : '«$phrase»';
      _exorcismSource = 'voice';
    });

    _prayerDisplayTimer?.cancel();
    _prayerDisplayTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isPrayerActive = false;
        });
      }
    });

    AudioService().playHolyDawnBell();
    HapticFeedback.heavyImpact();

    if (hasGhost) {
      _triggerSacredVoiceExorcism(phrase);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 125, left: 16, right: 16),
            backgroundColor: const Color(0xFF1A261A),
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                const Icon(Icons.mic, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('🎙️ [МОЛИТВА УСЛЫШАНА МИКРОФОНОМ: $phrase]'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  /// Sacred voice-driven exorcism (dissolves ghost when user speaks prayer)
  void _triggerSacredVoiceExorcism(String phrase) {
    final spawner = ProceduralEntitySpawner();
    if (!spawner.hasActiveEntity) return;

    setState(() {
      _isExorcismActive = true;
      _exorcismAnimProgress = 0.0;
      _exorcismSource = 'voice';
      _currentPrayerText = phrase.isNotEmpty
          ? (phrase.contains('«') ? phrase : '«$phrase»')
          : '«ДА ВОСКРЕСНЕТЪ БОГЪ, И РАЗТОЧАТСЯ ВРАЗИ ЕГО...»';
    });

    final camera = CameraShaderController();
    camera.toggleTorch();

    _exorcismTimer?.cancel();
    const totalDurationMs = 2400;
    const intervalMs = 40;
    int ticks = 0;
    const totalTicks = totalDurationMs ~/ intervalMs;

    _exorcismTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      ticks++;
      _exorcismAnimProgress = (ticks / totalTicks).clamp(0.0, 1.0);

      if (_exorcismAnimProgress > 0.40 && _exorcismAnimProgress < 0.75) {
        _currentPrayerText = '«ЯКО ТАЕТЪ ВОСКЪ ОТЪ ЛИЦА ОГНЯ, ТАКО ДА ПОГИБНУТЪ БѢСИ...»';
      } else if (_exorcismAnimProgress >= 0.75) {
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

    spawner.banishActiveEntity(onComplete: () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 125, left: 16, right: 16),
            backgroundColor: Color(0xFF2E2414),
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.amber),
                SizedBox(width: 8),
                Text('✨ Сущность изгнана вашей живой молитвой в микрофон!'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  /// 2. Cross Detected in Frame Handler
  void _onCrossDetectedInFrame(Offset center) {
    final now = DateTime.now();
    if (now.difference(_lastCrossChimeTime).inMilliseconds >= 2500) {
      _lastCrossChimeTime = now;
      AudioService().playHolyDawnBell();
      HapticFeedback.mediumImpact();
    }

    final spawner = ProceduralEntitySpawner();
    final entity = spawner.currentEntity;

    if (entity != null && entity.banishProgress <= 0.0) {
      // Golden radiance strikes phantom after 0.5s of focused cross illumination
      _crossBanishTimer?.cancel();
      _crossBanishTimer = Timer(const Duration(milliseconds: 550), () {
        if (_isCrossInFrame && spawner.hasActiveEntity) {
          _triggerCrossRadianceExorcism();
        }
      });
    }
  }

  /// Sacred cross radiance exorcism (banishes ghost when illuminated by cross godrays)
  void _triggerCrossRadianceExorcism() {
    final spawner = ProceduralEntitySpawner();
    if (!spawner.hasActiveEntity) return;

    AudioService().playHolyDawnBell();
    HapticFeedback.heavyImpact();

    setState(() {
      _isExorcismActive = true;
      _exorcismAnimProgress = 0.0;
      _exorcismSource = 'cross';
      _currentPrayerText = '«СВЯТЫЙ КРЕСТЪ ГОСПОДЕНЬ — СИЯНИЕМЪ ТВОИМЪ ИЗГОНИ БѢСА!»';
    });

    final camera = CameraShaderController();
    camera.toggleTorch();

    _exorcismTimer?.cancel();
    const totalDurationMs = 2400;
    const intervalMs = 40;
    int ticks = 0;
    const totalTicks = totalDurationMs ~/ intervalMs;

    _exorcismTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      ticks++;
      _exorcismAnimProgress = (ticks / totalTicks).clamp(0.0, 1.0);

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

    spawner.banishActiveEntity(onComplete: () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 125, left: 16, right: 16),
            backgroundColor: Color(0xFF2E2414),
            content: Row(
              children: [
                Icon(Icons.flare, color: Colors.amber),
                SizedBox(width: 8),
                Text('☦ ✨ Сияние Святого Креста в кадре испепелило призрака!'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  /// Helper to toggle simulated/physical cross for instant testing
  void _toggleCrossTest() {
    final relic = SacredRelicDetector();
    if (_isCrossInFrame) {
      relic.clearCrossDetection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 125, left: 16, right: 16),
          content: Text('☦ Крест убран из поля зрения'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      relic.feedCrossDetection(const Offset(0.5, 0.40));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 125, left: 16, right: 16),
          backgroundColor: Color(0xFF2E2414),
          content: Row(
            children: [
              Icon(Icons.flare, color: Colors.amber),
              SizedBox(width: 8),
              Text('☦ Святой Крест в кадре: Божественное сияние активно!'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _scanTimer?.cancel();
    _exorcismTimer?.cancel();
    _prayerDisplayTimer?.cancel();
    _crossBanishTimer?.cancel();
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
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 125, left: 16, right: 16),
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

                  // 3D Spatial Off-screen directional indicators
                  if (spawner.currentEntity != null && spawner.currentEntity!.banishProgress <= 0.0) ...[
                    if (spawner.currentEntity!.screenPosition.dx < 0.05)
                      Positioned(
                        left: 14,
                        top: MediaQuery.of(context).size.height * 0.45,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.redAccent, width: 1.5),
                            boxShadow: const [BoxShadow(color: Colors.redAccent, blurRadius: 10)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios, color: Colors.yellowAccent, size: 13),
                              SizedBox(width: 4),
                              Text('◀ АНОМАЛИЯ СЛЕВА', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    if (spawner.currentEntity!.screenPosition.dx > 0.95)
                      Positioned(
                        right: 14,
                        top: MediaQuery.of(context).size.height * 0.45,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.redAccent, width: 1.5),
                            boxShadow: const [BoxShadow(color: Colors.redAccent, blurRadius: 10)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('АНОМАЛИЯ СПРАВА ▶', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, color: Colors.yellowAccent, size: 13),
                            ],
                          ),
                        ),
                      ),
                  ],

                  // 2. Divine Golden Radiance Overlay emanating from Cross in Frame
                  if (_isCrossInFrame)
                    CrossRadianceOverlay(
                      crossCenter: _crossCenter,
                      animationValue: _tickerController.value * 10.0,
                      targetEntity: spawner.currentEntity,
                    ),

                  // Offline / Missing camera banner
                  if (!isCameraReady)
                    Positioned(
                      top: 105,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: profile.aesthetic.accent.withValues(alpha: 0.5)),
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

          // 3. Sacred Exorcism / Prayer Overlay (Golden Orthodox Cross & Prayer Chants)
          if (_isExorcismActive)
            _buildSacredExorcismRitualOverlay(),

          // 4. Live Microphone Prayer Voice Ripple Indicator (under top bar, non-overlapping)
          _buildMicPrayerIndicator(),

          // 4b. Cross Detected Active Status Badge
          if (_isCrossInFrame)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2414).withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.amber, blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flare, color: Colors.amber, size: 15),
                      SizedBox(width: 6),
                      Text(
                        '☦ [КРЕСТ ОБНАРУЖЕН: СИЯНИЕ АКТИВНО]',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Top HUD Bar (Zero-overflow responsive layout)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Row(
                  children: [
                    // Brand & Secret Tap Header
                    GestureDetector(
                      onTap: _onHeaderTapped,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: profile.aesthetic.accent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radar, color: profile.aesthetic.accent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'PL',
                              style: TextStyle(
                                color: profile.aesthetic.accent,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Compact Test mode badge (Immune to screen overflow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A9D8F), Color(0xFF264653)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2A9D8F)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_open, color: Colors.white, size: 11),
                          SizedBox(width: 3),
                          Text(
                            'ТЕСТ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Hardware Quick Controls + Cross / Mic Status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cross Presence Status / Manual Toggle
                        IconButton(
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                          tooltip: 'Показать/скрыть Крест',
                          icon: Icon(
                            _isCrossInFrame ? Icons.flare : Icons.church,
                            color: _isCrossInFrame ? Colors.amberAccent : Colors.white70,
                            size: 19,
                          ),
                          onPressed: _toggleCrossTest,
                        ),

                        // Torch
                        IconButton(
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                          icon: Icon(
                            camera.isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                            color: camera.isTorchOn ? Colors.amber : Colors.white70,
                            size: 19,
                          ),
                          onPressed: () => camera.toggleTorch(),
                        ),

                        // Mute Audio
                        IconButton(
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                          icon: Icon(
                            AudioService().isMuted ? Icons.volume_off : Icons.volume_up,
                            color: AudioService().isMuted ? Colors.redAccent : profile.aesthetic.accent,
                            size: 19,
                          ),
                          onPressed: () => setState(() => AudioService().toggleMute()),
                        ),

                        // Flip Camera
                        IconButton(
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                          icon: Icon(Icons.flip_camera_ios, color: profile.aesthetic.accent, size: 19),
                          onPressed: () => camera.toggleCameraLens(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 6. Bottom Controls: NO BUTTON DISAPPEARANCE - CLEAN TWO BUTTON LAYOUT!
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

                      // Row 2: Action Toolbar (Радар 50% & Бестиарий 50% - Screen Exorcism button removed!)
                      Row(
                        children: [
                          // Radar Button (50%)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14241B),
                                foregroundColor: profile.aesthetic.accent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: profile.aesthetic.accent.withValues(alpha: 0.5)),
                                ),
                              ),
                              onPressed: () async {
                                final success = await GeoAdaptationService().activateGeomagneticRadar();
                                AudioService().updateEmfLevel(0.85);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.only(bottom: 125, left: 16, right: 16),
                                    content: Text(success
                                        ? '📡 Радар сканирует аномалии в радиусе 500м...'
                                        : '⚠️ Включите геолокацию на устройстве'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.radar, size: 16),
                              label: const Text('Радар аномалий', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Bestiary Button (50%)
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
                        ],
                      ),

                      const SizedBox(height: 6),
                      // Exorcism instruction pill (Sacred mechanic guide)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic, color: _voiceEnergy > 0.15 ? Colors.greenAccent : Colors.amberAccent, size: 12),
                            const SizedBox(width: 5),
                            const Text(
                              'Изгнание: скажите молитву в микрофон или покажите Крест',
                              style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 0.3),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.flare, color: Colors.amberAccent, size: 12),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 7. Jumpscare Screamer Overlay
          AnimatedBuilder(
            animation: prank,
            builder: (context, child) {
              if (prank.state == PrankState.triggered) {
                return Container(
                  color: Colors.red.shade900,
                  alignment: Alignment.center,
                  child: const Text(
                    '⚠️ АНОМАЛИЯ ⚠️',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
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

  /// Live Microphone Prayer Voice Ripple Indicator
  Widget _buildMicPrayerIndicator() {
    if (_voiceEnergy <= 0.12 && !_isPrayerActive) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _isPrayerActive ? const Color(0xFF2E2414) : Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPrayerActive ? Colors.amberAccent : Colors.greenAccent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isPrayerActive ? Colors.amber : Colors.greenAccent).withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic,
                color: _isPrayerActive ? Colors.amberAccent : Colors.greenAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _isPrayerActive
                    ? '🎙️ МОЛИТВА УСЛЫШАНА: ${_detectedPrayerPhrase.isNotEmpty ? _detectedPrayerPhrase : "«ОТЧЕ НАШ...»"}'
                    : '🎙️ МИКРОФОН СЛУШАЕТ МОЛИТВУ...',
                style: TextStyle(
                  color: _isPrayerActive ? Colors.amberAccent : Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              // Animated Voice Meter Level
              Container(
                width: 24,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white24,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _voiceEnergy.clamp(0.2, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _isPrayerActive ? Colors.amber : Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Single filter button tab builder with synchronized highlight
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
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : Colors.white60,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white60,
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
    if (entity.isScanned) return const SizedBox.shrink();
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
      color: Colors.black.withValues(alpha: 0.65),
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
                        color: Colors.amber.withValues(alpha: 0.55),
                        blurRadius: 40,
                        spreadRadius: 15,
                      ),
                      BoxShadow(
                        color: Colors.orangeAccent.withValues(alpha: 0.4),
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
                    Text(
                      _exorcismSource == 'cross'
                          ? 'СИЯНИЕ СВЯТОГО КРЕСТА'
                          : 'СВЯЩЕННАЯ МОЛИТВА ИЗГНАНИЯ',
                      style: const TextStyle(
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
              top: 96, // Shifted down to prevent collision with top controls & mic badge
              left: 20,
              child: Text(
                '1080p 60FPS • RAW SENSOR',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            // Cinematic framing corners
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: FramingCornersPainter(color: Colors.white30)),
              ),
            ),
          ],
        );

      case ActiveFilterType.vhs:
        // VHS Vintage OSD: Blinking REC dot, NOV 13 1989 timestamp, SP, Play
        return Stack(
          fit: StackFit.expand,
          children: [
            // Top-left: Blinking red REC dot and mode
            Positioned(
              top: 96,
              left: 20,
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _tickerController,
                    builder: (context, child) {
                      final isBlink = sin(_tickerController.value * 6.0) > 0.0;
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isBlink ? Colors.redAccent : Colors.red.shade900.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'SP',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Top-right: PLAY indicator
            const Positioned(
              top: 96,
              right: 20,
              child: Text(
                'PLAY  ▶',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Bottom-left: Authentic Retro Date/Time timestamp (Shifted above bottom bar!)
            Positioned(
              bottom: 165,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOV. 13  1989',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _tickerController,
                    builder: (context, _) {
                      final now = DateTime.now();
                      final timeStr =
                          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}:${(now.millisecond ~/ 100)}';
                      return Text(
                        'PM $timeStr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );

      case ActiveFilterType.nightVision:
        // PVS-14 Green Phosphor OSD: Circular goggle aperture vignette, IR-850nm, GAIN: +38dB
        return Stack(
          fit: StackFit.expand,
          children: [
            // Circular night vision binocular aperture mask
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.88,
                  colors: [Colors.transparent, Color(0xCC001A05), Colors.black],
                  stops: [0.65, 0.85, 1.0],
                ),
              ),
            ),

            // Top Status: IR-850nm ACTIVE, GAIN
            Positioned(
              top: 96,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003311),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6)),
                    ),
                    child: const Text(
                      '⚡ IR-850nm ACTIVE',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const Text(
                    'GAIN: +38dB • AGC',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Bottom-left: Night Vision Battery Indicator
            const Positioned(
              bottom: 165,
              left: 20,
              child: Row(
                children: [
                  Icon(Icons.battery_5_bar, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'NV-BAT: 84% [OK]',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case ActiveFilterType.thermal:
        // Thermal FLIR Ironbow: Dynamic crosshair temperature, gradient legend, anomaly field warning
        final entity = spawner.currentEntity;
        final distToCenter = entity != null
            ? (entity.screenPosition - const Offset(0.5, 0.5)).distance
            : 1.0;
        final isAimingAtEntity = distToCenter < 0.24;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Top: Thermal sensor model
            const Positioned(
              top: 96,
              left: 20,
              child: Text(
                'FLIR IRONBOW MATRIX • 60Hz',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Right: Temperature color gradient legend bar
            Positioned(
              top: 130,
              bottom: 200,
              right: 16,
              width: 18,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white30),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.yellow,
                      Colors.orange,
                      Colors.red,
                      Colors.purple,
                      Color(0xFF000033),
                    ],
                  ),
                ),
              ),
            ),

            // Temperature Legend scale labels
            const Positioned(
              top: 130,
              right: 38,
              child: Text(
                '42°C',
                style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'),
              ),
            ),
            const Positioned(
              bottom: 200,
              right: 38,
              child: Text(
                '-10°C',
                style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'),
              ),
            ),

            // Center Dynamic Crosshair with real-time temperature
            Center(
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(90, 90),
                      painter: CrosshairReticlePainter(
                        color: isAimingAtEntity ? Colors.redAccent : Colors.orangeAccent,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isAimingAtEntity ? Colors.redAccent : Colors.orangeAccent,
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: _tickerController,
                          builder: (context, _) {
                            final dynamicTemp = isAimingAtEntity
                                ? (-2.8 + 0.4 * sin(_tickerController.value * 12.0)).toStringAsFixed(1)
                                : (21.4 + 1.2 * sin(_tickerController.value * 3.0)).toStringAsFixed(1);
                            return Text(
                              '$dynamicTemp°C',
                              style: TextStyle(
                                color: isAimingAtEntity ? Colors.cyanAccent : Colors.orangeAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Prominent Anomalous Field Warning when crosshair is on ghost
            if (isAimingAtEntity)
              Positioned(
                top: 125,
                left: 20,
                right: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellowAccent, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.redAccent, blurRadius: 16),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, color: Colors.yellowAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '⚠️ [АНОМАЛЬНОЕ ПОЛЕ ОБНАРУЖЕНО!]',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
    }
  }
}

/// Dynamic Crosshair Reticle Painter for Thermal Mode
class CrosshairReticlePainter extends CustomPainter {
  final Color color;
  CrosshairReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 18, paint);

    // Cross lines with center gap
    canvas.drawLine(Offset(center.dx - 32, center.dy), Offset(center.dx - 8, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 8, center.dy), Offset(center.dx + 32, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 32), Offset(center.dx, center.dy - 8), paint);
    canvas.drawLine(Offset(center.dx, center.dy + 8), Offset(center.dx, center.dy + 32), paint);
  }

  @override
  bool shouldRepaint(covariant CrosshairReticlePainter oldDelegate) => oldDelegate.color != color;
}

/// Simulated Viewfinder for emulators / devices without camera hardware
class SimulatedViewfinder extends StatelessWidget {
  const SimulatedViewfinder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0xFF0F1A15), Color(0xFF050807), Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera, color: Colors.white.withValues(alpha: 0.15), size: 72),
            const SizedBox(height: 12),
            Text(
              'AR VIEWFINDER SENSOR ACTIVE',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 2.5,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four corner framing brackets painter
class FramingCornersPainter extends CustomPainter {
  final Color color;
  FramingCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const cornerLength = 26.0;
    const pad = 24.0;

    // Top-Left
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + cornerLength, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad, pad + cornerLength), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad - cornerLength, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad, pad + cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad + cornerLength, size.height - pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad, size.height - pad - cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - pad, size.height - pad), Offset(size.width - pad - cornerLength, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad), Offset(size.width - pad, size.height - pad - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant FramingCornersPainter oldDelegate) => false;
}
