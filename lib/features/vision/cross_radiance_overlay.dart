import 'dart:math';
import 'package:flutter/material.dart';
import '../entity_engine/procedural_entity_spawner.dart';

/// Renders radiant divine golden rays, holy halo, and banishing light beams
/// emanating directly from the detected Cross in the camera viewfinder.
class CrossRadianceOverlay extends StatelessWidget {
  final Offset crossCenter; // Normalized coordinates (0.0 - 1.0)
  final double animationValue; // Continuous ticker value for rotation and pulsing
  final ProceduralEntityInstance? targetEntity;

  const CrossRadianceOverlay({
    super.key,
    required this.crossCenter,
    required this.animationValue,
    this.targetEntity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CrossRadiancePainter(
          crossCenter: crossCenter,
          animationValue: animationValue,
          targetEntity: targetEntity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CrossRadiancePainter extends CustomPainter {
  final Offset crossCenter;
  final double animationValue;
  final ProceduralEntityInstance? targetEntity;

  _CrossRadiancePainter({
    required this.crossCenter,
    required this.animationValue,
    this.targetEntity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerPixel = Offset(
      crossCenter.dx * size.width,
      crossCenter.dy * size.height,
    );

    final maxRadius = max(size.width, size.height) * 0.85;

    // 1. Concentric Pulsing Golden Halos (Нимб)
    final pulse = 0.85 + 0.15 * sin(animationValue * 4.0);
    final haloRadius = 75.0 * pulse;

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFBE6), // Core brilliant white-gold
          const Color(0xFFFFD700).withValues(alpha: 0.75), // Divine Gold
          const Color(0xFFFF9800).withValues(alpha: 0.35), // Warm Amber
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: centerPixel, radius: haloRadius * 1.8));

    canvas.drawCircle(centerPixel, haloRadius * 1.8, haloPaint);

    // 2. Volumetric Rotating Godrays (Божественные лучи от креста)
    const numRays = 16;
    const rayAngle = (2 * pi) / numRays;
    final baseRotation = animationValue * 0.45; // Smooth slow holy rotation

    final rayPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF9D2).withValues(alpha: 0.65),
          const Color(0xFFFFD700).withValues(alpha: 0.35),
          const Color(0xFFFFAB00).withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: centerPixel, radius: maxRadius));

    for (int i = 0; i < numRays; i++) {
      final currentAngle = baseRotation + (i * rayAngle);
      final raySpread = 0.09 + 0.02 * sin(animationValue * 3.0 + i);

      final path = Path();
      path.moveTo(centerPixel.dx, centerPixel.dy);
      path.lineTo(
        centerPixel.dx + cos(currentAngle - raySpread) * maxRadius,
        centerPixel.dy + sin(currentAngle - raySpread) * maxRadius,
      );
      path.lineTo(
        centerPixel.dx + cos(currentAngle + raySpread) * maxRadius,
        centerPixel.dy + sin(currentAngle + raySpread) * maxRadius,
      );
      path.close();

      canvas.drawPath(path, rayPaint);
    }

    // 3. Golden Orthodox Cross Silhouette Overlay at center
    final crossPaint = Paint()
      ..color = const Color(0xFFFFF8E7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    const crossHeight = 46.0;
    const crossWidth = 28.0;

    // Vertical stem
    canvas.drawLine(
      Offset(centerPixel.dx, centerPixel.dy - crossHeight * 0.6),
      Offset(centerPixel.dx, centerPixel.dy + crossHeight * 0.6),
      crossPaint,
    );

    // Main horizontal crossbar
    canvas.drawLine(
      Offset(centerPixel.dx - crossWidth * 0.5, centerPixel.dy - crossHeight * 0.15),
      Offset(centerPixel.dx + crossWidth * 0.5, centerPixel.dy - crossHeight * 0.15),
      crossPaint,
    );

    // Upper title bar
    canvas.drawLine(
      Offset(centerPixel.dx - crossWidth * 0.25, centerPixel.dy - crossHeight * 0.42),
      Offset(centerPixel.dx + crossWidth * 0.25, centerPixel.dy - crossHeight * 0.42),
      crossPaint,
    );

    // Lower slanted footrest bar (Православный косой подножек)
    canvas.drawLine(
      Offset(centerPixel.dx - crossWidth * 0.28, centerPixel.dy + crossHeight * 0.38),
      Offset(centerPixel.dx + crossWidth * 0.28, centerPixel.dy + crossHeight * 0.28),
      crossPaint,
    );

    // 4. Divine Strike Light Beam to Target Phantom (if phantom is active)
    if (targetEntity != null && targetEntity!.banishProgress < 1.0) {
      final ghostPixel = Offset(
        targetEntity!.screenPosition.dx * size.width,
        targetEntity!.screenPosition.dy * size.height,
      );

      // Core blinding holy beam
      final beamPaint = Paint()
        ..color = const Color(0xFFFFFBE8).withValues(alpha: 0.90)
        ..strokeWidth = 7.0 + 3.0 * sin(animationValue * 12.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);

      // Golden outer glow beam
      final outerBeamPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.60)
        ..strokeWidth = 18.0 + 6.0 * sin(animationValue * 10.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);

      canvas.drawLine(centerPixel, ghostPixel, outerBeamPaint);
      canvas.drawLine(centerPixel, ghostPixel, beamPaint);

      // Holy impact flare on the phantom
      final impactRadius = 55.0 + 15.0 * sin(animationValue * 15.0);
      final impactPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            const Color(0xFFFFD700).withValues(alpha: 0.8),
            const Color(0xFFFF6D00).withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: ghostPixel, radius: impactRadius));

      canvas.drawCircle(ghostPixel, impactRadius, impactPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrossRadiancePainter oldDelegate) => true;
}
