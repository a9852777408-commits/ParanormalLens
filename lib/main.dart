import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'core/models/regional_profile.dart';
import 'core/services/geo_adaptation_service.dart';
import 'core/services/monetization_service.dart';
import 'features/camera/camera_shader_controller.dart';
import 'features/bestiary/bestiary_screen.dart';
import 'features/monetization/paywall_screen.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ [STEALTH PRANK ARMED: 15s]'),
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
    final suspense = SuspenseEngine();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Stream + GLSL Shader Post-Processing
          AnimatedBuilder(
            animation: Listenable.merge([camera, spawner, _tickerController]),
            builder: (context, child) {
              final isCameraReady = camera.isInitialized &&
                  camera.controller != null &&
                  camera.controller!.value.isInitialized;

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (isCameraReady)
                    CameraPreview(camera.controller!)
                  else ...[
                    Container(color: const Color(0xFF0D1410)),
                    CustomPaint(painter: SimulatedViewfinderPainter()),
                  ],
                  CustomPaint(
                    painter: ShaderPostProcessingPainter(
                      shader: camera.getActiveShader(),
                      time: _tickerController.value * 1000.0,
                      entity: spawner.currentEntity,
                      shadowShader: camera.proceduralShadowShader,
                    ),
                  ),
                  if (!isCameraReady)
                    Positioned(
                      top: 70,
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
                                'Камера не обнаружена (режим эмулятора). Визор активен.',
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

          // 2. Top HUD Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _onHeaderTapped,
                    child: Row(
                      children: [
                        Icon(Icons.lens_blur, color: profile.aesthetic.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'PL',
                          style: TextStyle(
                            color: profile.aesthetic.accent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // PRO Badge button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PaywallScreen()),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [profile.aesthetic.accent, profile.aesthetic.primary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star, color: Colors.black, size: 13),
                              SizedBox(width: 4),
                              Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.flip_camera_ios, color: profile.aesthetic.accent, size: 20),
                        onPressed: () => camera.toggleCameraLens(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: profile.aesthetic.primary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: profile.aesthetic.accent.withOpacity(0.4)),
                        ),
                        child: Text(
                          profile.aesthetic.themeName,
                          style: TextStyle(color: profile.aesthetic.accent, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Controls & Filter Mode Switcher
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Filter Switcher Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterButton('NightVision', Icons.visibility, ActiveFilterType.nightVision),
                    const SizedBox(width: 8),
                    _buildFilterButton('Thermal', Icons.thermostat, ActiveFilterType.thermal),
                    const SizedBox(width: 8),
                    _buildFilterButton('EVP Static', Icons.waves, ActiveFilterType.evpStatic),
                    const SizedBox(width: 8),
                    _buildFilterButton('Normal', Icons.camera_alt, ActiveFilterType.normal),
                  ],
                ),
                const SizedBox(height: 14),

                // Radar & Relic Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: profile.aesthetic.primary,
                        foregroundColor: profile.aesthetic.accent,
                      ),
                      onPressed: () => GeoAdaptationService().activateGeomagneticRadar(),
                      icon: const Icon(Icons.radar, size: 16),
                      label: const Text('Радар (500м)'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: profile.aesthetic.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BestiaryScreen()),
                        );
                      },
                      icon: const Icon(Icons.auto_stories, size: 16),
                      label: const Text('Бестиарий'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: profile.aesthetic.accent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        spawner.banishActiveEntity(onComplete: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✨ Сущность изгнана священным светом!')),
                          );
                        });
                      },
                      icon: const Icon(Icons.flare, size: 16),
                      label: const Text('Освятить'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Legal Compliance Disclaimer
                const Text(
                  'For entertainment purposes only. App simulates paranormal detections.',
                  style: TextStyle(color: Colors.white30, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // 4. Jumpscare Overlay
          AnimatedBuilder(
            animation: prank,
            builder: (context, child) {
              if (prank.state == PrankState.triggered) {
                return Container(
                  color: Colors.red.shade900,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
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

  Widget _buildFilterButton(String label, IconData icon, ActiveFilterType filterType) {
    final camera = CameraShaderController();
    final isSelected = camera.activeFilter == filterType;
    final profile = GeoAdaptationService().activeProfile;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? profile.aesthetic.accent : Colors.black54,
        foregroundColor: isSelected ? Colors.black : Colors.white70,
        side: BorderSide(color: profile.aesthetic.accent.withOpacity(0.6)),
      ),
      onPressed: () => camera.setFilter(filterType),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

/// Fallback painter that renders an authentic radar crosshair and grid when camera hardware is unavailable
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

