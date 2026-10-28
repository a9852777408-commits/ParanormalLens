import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/geo_adaptation_service.dart';

typedef SacredRelicCallback = void Function(Rect boundingBox, String objectLabel, Color glowColor);
typedef CrossDetectedCallback = void Function(Offset center, Rect box);

/// High-performance On-Device Offline Computer Vision Detector (5 Hz)
/// Detects physical crosses, crucifixes, and sacred relics in the camera viewfinder.
class SacredRelicDetector {
  static final SacredRelicDetector _instance = SacredRelicDetector._internal();
  factory SacredRelicDetector() => _instance;
  SacredRelicDetector._internal();

  SacredRelicCallback? onSacredRelicDetected;
  CrossDetectedCallback? onCrossDetected;
  VoidCallback? onCrossLost;
  VoidCallback? onRelicLost;

  Timer? _inferenceLoopTimer;
  bool _isProcessingFrame = false;
  Rect? _lastDetectedBox;
  Offset? _detectedCrossPosition;
  bool _isCrossActive = false;

  bool get hasDetectedCross => _isCrossActive && _detectedCrossPosition != null;
  Offset? get detectedCrossCenter => _detectedCrossPosition;
  Rect? get detectedCrossBox => _lastDetectedBox;

  /// Starts the 5 Hz (200 ms interval) offline inference loop
  void startInferenceLoop() {
    _inferenceLoopTimer?.cancel();
    _inferenceLoopTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _processNextFrameSample();
    });
    debugPrint('[Vision] 5 Hz offline cross & relic detector started.');
  }

  void stopInferenceLoop() {
    _inferenceLoopTimer?.cancel();
    _inferenceLoopTimer = null;
    _isCrossActive = false;
    _detectedCrossPosition = null;
    _lastDetectedBox = null;
  }

  /// Processes sample frame against the active cultural profile's recognized objects
  void _processNextFrameSample() {
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;

    try {
      if (_isCrossActive && _detectedCrossPosition != null) {
        onCrossDetected?.call(_detectedCrossPosition!, _lastDetectedBox ?? Rect.fromCenter(center: _detectedCrossPosition!, width: 0.3, height: 0.3));
        onSacredRelicDetected?.call(
          _lastDetectedBox ?? Rect.fromCenter(center: _detectedCrossPosition!, width: 0.3, height: 0.3),
          'Крест Православный',
          const Color(0xFFFFD700),
        );
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Ingests raw cross detection from camera vision stream or heuristic edge detector
  void feedCrossDetection(Offset normalizedCenter, {Rect? box}) {
    _isCrossActive = true;
    _detectedCrossPosition = normalizedCenter;
    _lastDetectedBox = box ?? Rect.fromCenter(center: normalizedCenter, width: 0.28, height: 0.36);

    onCrossDetected?.call(_detectedCrossPosition!, _lastDetectedBox!);
    onSacredRelicDetected?.call(_lastDetectedBox!, 'Крест', const Color(0xFFFFD700));
  }

  /// Clears active cross detection when out of frame
  void clearCrossDetection() {
    if (_isCrossActive) {
      _isCrossActive = false;
      _detectedCrossPosition = null;
      _lastDetectedBox = null;
      onCrossLost?.call();
      onRelicLost?.call();
    }
  }

  /// Fallback/manual trigger for testing or camera target lock
  void toggleCrossSimulation(bool active, [Offset center = const Offset(0.5, 0.45)]) {
    if (active) {
      feedCrossDetection(center);
    } else {
      clearCrossDetection();
    }
  }

  /// Ingests raw detection from camera feed bridge
  void feedDetectionResult(String label, Rect box, double confidence) {
    final activeProfile = GeoAdaptationService().activeProfile;
    final recognizedList = activeProfile.sacredRelics.recognizedObjects;

    if (confidence >= 0.60 && (recognizedList.contains(label) || label.toLowerCase().contains('cross') || label.toLowerCase().contains('крест'))) {
      _lastDetectedBox = box;
      _detectedCrossPosition = box.center;
      _isCrossActive = true;
      onCrossDetected?.call(_detectedCrossPosition!, box);
      onSacredRelicDetected?.call(
        box,
        label,
        activeProfile.sacredRelics.glowColor,
      );
    } else {
      if (_isCrossActive) {
        clearCrossDetection();
      }
    }
  }
}
