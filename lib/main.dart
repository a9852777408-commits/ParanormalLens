import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1000),
    )..repeat();

    _initializeSubsystems();
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

  @override
  void dispose() {
    _tickerController.dispose();
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

                  // Dynamic Authentic Mode Overlays matching reference photo
                  _buildModeSpecificOverlay(camera.activeFilter),

                  // Offline / Missing camera banner
                  if (!isCameraReady)
                    Positioned(
                      top: 75,
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

          // 2. Top HUD Bar (Positioned strictly at top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
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

                    // Test mode: All Features Unlocked Badge
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

          // 3. Bottom Controls (Zero-Overflow Responsive Layout)
          Positioned(
            bottom: 12,
            left: 10,
            right: 10,
            child: SafeArea(
              child: Column(
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

                      // Exorcism Banish Button
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
                          onPressed: () {
                            AudioService().playHolyDawnBell();
                            spawner.banishActiveEntity(onComplete: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✨ Сущность изгнана священным светом!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            });
                          },
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
              ),
            ),
          ),

          // 4. Jumpscare Screamer Overlay
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
          camera.setFilter(filterType);
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

  /// Authentic OSD overlays matching the 4 quadrants of horror_camera_filters_1791799886078.jpg
  Widget _buildModeSpecificOverlay(ActiveFilterType mode) {
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
              top: 55,
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
              top: 55,
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
              top: 55,
              right: 18,
              child: Text(
                'SP  -0:12:44',
                style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            const Positioned(
              bottom: 110,
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
              top: 55,
              left: 18,
              child: Text(
                'NIGHT VISION',
                style: TextStyle(color: Color(0xFF4EFE7B), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0),
              ),
            ),
            const Positioned(
              top: 55,
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
              bottom: 110,
              left: 18,
              child: Text(
                'GAIN: +18dB • PHOSPHOR P-43',
                style: TextStyle(color: Color(0xFF4EFE7B), fontSize: 9, letterSpacing: 1.0),
              ),
            ),
          ],
        );

      case ActiveFilterType.thermal:
        // Bottom-Right: FLIR Ironbow Thermal False-Color & Holy Glow + Temperature Scale Bar
        return Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              top: 55,
              left: 18,
              child: Text(
                'THERMAL & HOLY GLOW',
                style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
            ),
            const Positioned(
              top: 55,
              right: 18,
              child: Text(
                'MAX 38.2°C • MIN 18.0°C',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            // Center Reticle with Temperature
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amberAccent, width: 1.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.amberAccent, size: 16),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.black87,
                    child: const Text(
                      '36.6°C',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Vertical FLIR Ironbow Temperature Scale Legend Bar on the right
            Positioned(
              right: 12,
              top: 100,
              bottom: 140,
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
