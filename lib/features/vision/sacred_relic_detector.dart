import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../core/services/geo_adaptation_service.dart';

typedef SacredRelicCallback = void Function(Rect boundingBox, String objectLabel, Color glowColor);

/// High-performance On-Device Offline Computer Vision Detector (5 Hz)
/// Dispatches onSacredRelicDetected events adapted to the user's active regional profile.
class SacredRelicDetector {
  static final SacredRelicDetector _instance = SacredRelicDetector._internal();
  factory SacredRelicDetector() => _instance;
  SacredRelicDetector._internal();

  SacredRelicCallback? onSacredRelicDetected;
  VoidCallback? onRelicLost;

  Timer? _inferenceLoopTimer;
  bool _isProcessingFrame = false;
  Rect? _lastDetectedBox;

  /// Starts the 5 Hz (200 ms interval) offline inference loop
  void startInferenceLoop() {
    _inferenceLoopTimer?.cancel();
    _inferenceLoopTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _processNextFrameSample();
    });
    debugPrint('[Vision] 5 Hz offline object detector started.');
  }

  void stopInferenceLoop() {
    _inferenceLoopTimer?.cancel();
    _inferenceLoopTimer = null;
  }

  /// Processes sample frame against the active cultural profile's recognized objects
  void _processNextFrameSample() {
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;

    try {
      final activeProfile = GeoAdaptationService().activeProfile;
      final recognizedList = activeProfile.sacredRelics.recognizedObjects;

      // In production, Google ML Kit / TFLite feeds detected labels here.
      // Example simulation of detection when confidence > 0.7:
      // bool found = checkModelInference(frame, recognizedList);

      // When a regional relic is present:
      if (_lastDetectedBox != null) {
        onSacredRelicDetected?.call(
          _lastDetectedBox!,
          recognizedList.first,
          activeProfile.sacredRelics.glowColor,
        );
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Ingests raw detection from camera feed bridge
  void feedDetectionResult(String label, Rect box, double confidence) {
    final activeProfile = GeoAdaptationService().activeProfile;
    final recognizedList = activeProfile.sacredRelics.recognizedObjects;

    if (confidence >= 0.65 && recognizedList.contains(label)) {
      _lastDetectedBox = box;
      onSacredRelicDetected?.call(
        box,
        label,
        activeProfile.sacredRelics.glowColor,
      );
    } else {
      if (_lastDetectedBox != null) {
        _lastDetectedBox = null;
        onRelicLost?.call();
      }
    }
  }
}
