import 'dart:async';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../entity_engine/procedural_entity_spawner.dart';

enum ActiveFilterType { nightVision, thermal, evpStatic, normal }

/// Coordinates live device camera hardware with Flutter Impeller GLSL shaders
class CameraShaderController extends ChangeNotifier {
  static final CameraShaderController _instance = CameraShaderController._internal();
  factory CameraShaderController() => _instance;
  CameraShaderController._internal();

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;

  ActiveFilterType _activeFilter = ActiveFilterType.nightVision;
  ActiveFilterType get activeFilter => _activeFilter;
  CameraController? get controller => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isFrontCamera => _availableCameras.isNotEmpty &&
      _availableCameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;

  // Loaded Shader Programs
  ui.FragmentShader? _nightVisionShader;
  ui.FragmentShader? _thermalShader;
  ui.FragmentShader? _evpStaticShader;
  ui.FragmentShader? _proceduralShadowShader;

  Future<void> initialize() async {
    // 1. Always load fragment shaders first so UI and shaders function even without a camera
    await _loadFragmentShaders();

    // 2. Safely initialize hardware camera
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        await _setupCameraController(_availableCameras[_selectedCameraIndex]);
      } else {
        debugPrint('[Camera] No hardware cameras detected.');
      }
    } catch (e) {
      debugPrint('[Camera] Camera hardware initialization error: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    try {
      await _cameraController?.dispose();
      _cameraController = CameraController(
        description,
        ResolutionPreset.medium, // 480p / 720p for 60 FPS mobile efficiency
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
    } catch (e) {
      debugPrint('[Camera] Error initializing CameraController: $e');
      _cameraController = null;
    }
  }

  Future<void> _loadFragmentShaders() async {
    try {
      final nvProgram = await ui.FragmentProgram.fromAsset('shaders/green_phosphor_grain.frag');
      _nightVisionShader = nvProgram.fragmentShader();

      final thermalProgram = await ui.FragmentProgram.fromAsset('shaders/thermal_palette.frag');
      _thermalShader = thermalProgram.fragmentShader();

      final evpProgram = await ui.FragmentProgram.fromAsset('shaders/crt_scanline_noise.frag');
      _evpStaticShader = evpProgram.fragmentShader();

      final shadowProgram = await ui.FragmentProgram.fromAsset('shaders/procedural_shadow.frag');
      _proceduralShadowShader = shadowProgram.fragmentShader();

      debugPrint('[Shaders] All 4 fragment shader programs successfully compiled and loaded.');
    } catch (e) {
      debugPrint('[Shaders] Loading shaders error: $e');
    }
  }

  /// Toggles between Rear World Camera and Front Selfie Camera
  Future<void> toggleCameraLens() async {
    if (_availableCameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _setupCameraController(_availableCameras[_selectedCameraIndex]);
    notifyListeners();
  }

  void setFilter(ActiveFilterType filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  ui.FragmentShader? getActiveShader() {
    switch (_activeFilter) {
      case ActiveFilterType.nightVision:
        return _nightVisionShader;
      case ActiveFilterType.thermal:
        return _thermalShader;
      case ActiveFilterType.evpStatic:
        return _evpStaticShader;
      case ActiveFilterType.normal:
        return null;
    }
  }

  ui.FragmentShader? get proceduralShadowShader => _proceduralShadowShader;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}

/// CustomPainter that renders live camera post-processing shaders and procedural entities
class ShaderPostProcessingPainter extends CustomPainter {
  final ui.FragmentShader? shader;
  final double time;
  final ProceduralEntityInstance? entity;
  final ui.FragmentShader? shadowShader;

  ShaderPostProcessingPainter({
    required this.shader,
    required this.time,
    this.entity,
    this.shadowShader,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Camera Post-Processing Shader (Night Vision, Thermal, EVP)
    if (shader != null) {
      shader!.setFloat(0, size.width);
      shader!.setFloat(1, size.height);
      shader!.setFloat(2, time);

      final paint = Paint()..shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }

    // 2. Draw Procedural Shadow Entity (if present)
    if (entity != null && shadowShader != null) {
      shadowShader!.setFloat(0, size.width);
      shadowShader!.setFloat(1, size.height);
      shadowShader!.setFloat(2, time);
      shadowShader!.setFloat(3, entity!.seed);
      shadowShader!.setFloat(4, entity!.archetype);
      shadowShader!.setFloat(5, entity!.banishProgress);
      shadowShader!.setFloat(6, entity!.screenPosition.dx);
      shadowShader!.setFloat(7, entity!.screenPosition.dy);

      final entityPaint = Paint()..shader = shadowShader;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), entityPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ShaderPostProcessingPainter oldDelegate) => true;
}
