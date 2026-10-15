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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Passive Tier Geo-Adaptation (zero permissions)
  GeoAdaptationService().initializePassiveTier();

  // 2. Initialize Camera & Hardware GLSL Shaders
  await CameraShaderController().initialize();

  // 3. Start 5 Hz Computer Vision Loop & Spawner
  SacredRelicDetector().startInferenceLoop();
  ProceduralEntitySpawner().startCameraMotionMonitoring();

  // 4. Initialize Procedural Audio Landscape
  AudioService().initialize();

  runApp(const ParanormalLensApp());
}

class ParanormalLensApp extends StatelessWidget {
  const ParanormalLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    final geo = GeoAdaptationService();
    final profile = geo.activeProfile;

    return MaterialApp(
      title: 'ParanormalLens',
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
    SuspenseEngine().startPacingSession();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1000),
    )..repeat();
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
              if (!camera.isInitialized || camera.controller == null) {
                return Center(
                  child: CircularProgressIndicator(color: profile.aesthetic.accent),
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(camera.controller!),
                  CustomPaint(
                    painter: ShaderPostProcessingPainter(
                      shader: camera.getActiveShader(),
                      time: _tickerController.value * 1000.0,
                      entity: spawner.currentEntity,
                      shadowShader: camera.proceduralShadowShader,
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
                          'PARANORMAL LENS',
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
