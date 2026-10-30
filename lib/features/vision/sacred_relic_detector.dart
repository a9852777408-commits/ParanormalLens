import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/services/geo_adaptation_service.dart';

typedef SacredRelicCallback = void Function(Rect boundingBox, String objectLabel, Color glowColor);
typedef CrossDetectedCallback = void Function(Offset center, Rect box);

/// High-performance On-Device Offline Computer Vision Detector (5-7 Hz)
/// Detects physical crosses, crucifixes, and sacred relics directly in the live camera video stream.
/// Supports dark crosses on bright monitors/walls AND bright/gold crosses in dark rooms.
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
  DateTime _lastFrameTime = DateTime.now();
  int _consecutiveMissedFrames = 0;

  bool get hasDetectedCross => _isCrossActive && _detectedCrossPosition != null;
  Offset? get detectedCrossCenter => _detectedCrossPosition;
  Rect? get detectedCrossBox => _lastDetectedBox;

  /// Starts the 5 Hz (200 ms interval) offline inference loop
  void startInferenceLoop() {
    _inferenceLoopTimer?.cancel();
    _inferenceLoopTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _processNextFrameSample();
    });
    debugPrint('[Vision] Offline cross & relic detector active.');
  }

  void stopInferenceLoop() {
    _inferenceLoopTimer?.cancel();
    _inferenceLoopTimer = null;
    _isCrossActive = false;
    _detectedCrossPosition = null;
    _lastDetectedBox = null;
  }

  void _processNextFrameSample() {
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;

    try {
      if (_isCrossActive && _detectedCrossPosition != null) {
        onCrossDetected?.call(
          _detectedCrossPosition!,
          _lastDetectedBox ?? Rect.fromCenter(center: _detectedCrossPosition!, width: 0.32, height: 0.42),
        );
        onSacredRelicDetected?.call(
          _lastDetectedBox ?? Rect.fromCenter(center: _detectedCrossPosition!, width: 0.32, height: 0.42),
          'Крест Православный',
          const Color(0xFFFFD700),
        );
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Real-time live frame processor: scans camera luminance for cross / crucifix geometries
  void processCameraImage(CameraImage image) {
    final now = DateTime.now();
    // Process at ~6 Hz (every 160ms) to ensure smooth 60fps camera feed
    if (now.difference(_lastFrameTime).inMilliseconds < 160) return;
    _lastFrameTime = now;

    if (image.planes.isEmpty) return;

    try {
      final bytes = image.planes[0].bytes;
      final bytesPerRow = image.planes[0].bytesPerRow;
      final width = image.width;
      final height = image.height;

      // Safe bounds checking helper
      int getLuminance(int px, int py) {
        final cx = px.clamp(0, width - 1);
        final cy = py.clamp(0, height - 1);
        return bytes[cy * bytesPerRow + cx];
      }

      int bestScore = 0;
      int bestX = -1;
      int bestY = -1;

      // Multi-scale step grid: sample candidate cross centers
      final stepX = (width ~/ 36).clamp(10, 26);
      final stepY = (height ~/ 36).clamp(10, 26);

      // Multi-scale radii for cross junctions (handheld, paper, monitor, large crucifix)
      final radii = [12, 22, 36, 60, 95];

      for (int y = stepY * 3; y < height - stepY * 3; y += stepY) {
        for (int x = stepX * 3; x < width - stepX * 3; x += stepX) {
          final centerVal = getLuminance(x, y);

          for (final r in radii) {
            // Cross Arm Pixels:
            final top = getLuminance(x, y - r);
            final bot = getLuminance(x, y + r);
            final left = getLuminance(x - r, y);
            final right = getLuminance(x + r, y);

            final crossMean = (centerVal + top + bot + left + right) / 5.0;

            // Diagonal Background Pixels:
            final tl = getLuminance(x - r, y - r);
            final tr = getLuminance(x + r, y - r);
            final bl = getLuminance(x - r, y + r);
            final br = getLuminance(x + r, y + r);

            final bgMean = (tl + tr + bl + br) / 4.0;

            // Contrast between cross arms and diagonal background
            final contrast = (crossMean - bgMean).abs();
            if (contrast < 15.0) continue; // Sensitive to real-world room lighting & screens

            // Vertical stroke consistency (top and bottom match center more than background)
            final vArmDiff = ((top - centerVal).abs() + (bot - centerVal).abs()) / 2.0;
            // Horizontal stroke consistency (left and right match center more than background)
            final hArmDiff = ((left - centerVal).abs() + (right - centerVal).abs()) / 2.0;

            // In a valid cross, arm variation must be smaller than background contrast
            if (vArmDiff > contrast * 0.90 || hArmDiff > contrast * 0.90) continue;

            final score = (contrast * 2.0 - (vArmDiff + hArmDiff)).toInt();
            if (score > bestScore) {
              bestScore = score;
              bestX = x;
              bestY = y;
            }
          }
        }
      }

      // If a strong cross junction is confirmed
      if (bestScore > 24 && bestX > 0 && bestY > 0) {
        _consecutiveMissedFrames = 0;

        // Sensor orientation on Android portrait: 90° clockwise rotation
        final normX = (bestY / height).clamp(0.05, 0.95);
        final normY = (1.0 - (bestX / width)).clamp(0.05, 0.95);

        feedCrossDetection(
          Offset(normX, normY),
          box: Rect.fromCenter(
            center: Offset(normX, normY),
            width: 0.32,
            height: 0.42,
          ),
        );
      } else {
        _consecutiveMissedFrames++;
        if (_consecutiveMissedFrames >= 4) {
          clearCrossDetection();
        }
      }
    } catch (e) {
      debugPrint('[Vision] Frame processing error: $e');
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
  void toggleCrossSimulation(bool active, [Offset center = const Offset(0.5, 0.42)]) {
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

    if (confidence >= 0.50 &&
        (recognizedList.contains(label) ||
            label.toLowerCase().contains('cross') ||
            label.toLowerCase().contains('крест') ||
            label.toLowerCase().contains('crucifix'))) {
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
