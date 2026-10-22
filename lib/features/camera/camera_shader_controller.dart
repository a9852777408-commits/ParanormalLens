import 'dart:async';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../entity_engine/procedural_entity_spawner.dart';

enum ActiveFilterType { normal, vhs, nightVision, thermal }

/// Coordinates live device camera hardware with Flutter Impeller GLSL shaders
class CameraShaderController extends ChangeNotifier {
  static final CameraShaderController _instance = CameraShaderController._internal();
  factory CameraShaderController() => _instance;
  CameraShaderController._internal();

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isTorchOn = false;

  ActiveFilterType _activeFilter = ActiveFilterType.nightVision;
  ActiveFilterType get activeFilter => _activeFilter;
  CameraController? get controller => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isTorchOn => _isTorchOn;
  bool get isFrontCamera => _availableCameras.isNotEmpty &&
      _availableCameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;

  // GPU Color Matrices matching the 4 quadrants of horror_camera_filters_1791799886078.jpg:
  // 1. Normal Mode: Clean 1080p neutral grading
  static const List<double> matrixNormal = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  // 2. Low-Res VHS Mode: 360p vintage analog tape color shift
  static const List<double> matrixVhs = [
    0.88, 0.12, 0.08, 0.0, 10.0,
    0.08, 0.85, 0.12, 0.0, 12.0,
    0.10, 0.12, 0.78, 0.0,  8.0,
    0.0,  0.0,  0.0,  1.0,  0.0,
  ];

  // 3. Night Vision: Intense military PVS-14 green phosphor luminance
  static const List<double> matrixNightVision = [
    0.05, 0.12, 0.03, 0.0, -10.0,
    0.45, 1.35, 0.25, 0.0,  18.0,
    0.08, 0.18, 0.06, 0.0,  -8.0,
    0.0,  0.0,  0.0,  1.0,   0.0,
  ];

  // 4. Thermal & Holy Glow: FLIR Ironbow false-color (cold=deep indigo/purple, hot=fire orange/yellow/white)
  static const List<double> matrixThermal = [
    2.1,  0.8, -0.3, 0.0, -25.0,
    0.2,  1.3, -0.9, 0.0, -65.0,
   -1.4, -1.4,  1.3, 0.0, 175.0,
    0.0,  0.0,  0.0,  1.0,   0.0,
  ];

  List<double> get activeColorMatrix {
    switch (_activeFilter) {
      case ActiveFilterType.normal:
        return matrixNormal;
      case ActiveFilterType.vhs:
        return matrixVhs;
      case ActiveFilterType.nightVision:
        return matrixNightVision;
      case ActiveFilterType.thermal:
        return matrixThermal;
    }
  }

  // Loaded Shader Programs
  ui.FragmentShader? _nightVisionShader;
  ui.FragmentShader? _thermalShader;
  ui.FragmentShader? _vhsShader;
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

      final vhsProgram = await ui.FragmentProgram.fromAsset('shaders/crt_scanline_noise.frag');
      _vhsShader = vhsProgram.fragmentShader();

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

  /// Toggles hardware torch / flashlight
  Future<void> toggleTorch() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      _isTorchOn = !_isTorchOn;
      await _cameraController!.setFlashMode(_isTorchOn ? FlashMode.torch : FlashMode.off);
      notifyListeners();
    } catch (e) {
      debugPrint('[Camera] Torch toggle error: $e');
    }
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
      case ActiveFilterType.vhs:
        return _vhsShader;
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
    // 1. Draw Camera Post-Processing Shader (Night Vision, Thermal, VHS)
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
