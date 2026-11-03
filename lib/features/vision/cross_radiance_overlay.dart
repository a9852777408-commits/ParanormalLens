import 'dart:math';
import 'package:flutter/material.dart';
import '../entity_engine/procedural_entity_spawner.dart';
import 'sacred_relic_detector.dart';

/// Renders radiant golden neon contour illumination and localized holy halo
/// along the exact physical geometry of the detected Christian / Orthodox Cross in the camera feed.
/// Does NOT draw fake static cross icons or full-screen blinding sunbursts.
class CrossRadianceOverlay extends StatelessWidget {
  final DetectedCrossContour? crossContour;
  final Offset crossCenter; // Fallback normalized coordinates (0.0 - 1.0)
  final double animationValue; // Continuous ticker value for pulsing
  final ProceduralEntityInstance? targetEntity;

  const CrossRadianceOverlay({
    super.key,
    this.crossContour,
    required this.crossCenter,
    required this.animationValue,
    this.targetEntity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CrossRadiancePainter(
          crossContour: crossContour,
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
  final DetectedCrossContour? crossContour;
  final Offset crossCenter;
  final double animationValue;
  final ProceduralEntityInstance? targetEntity;

  _CrossRadiancePainter({
    this.crossContour,
    required this.crossCenter,
    required this.animationValue,
    this.targetEntity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Resolve physical cross endpoints in screen pixel coordinates
    final Offset pJunction;
    final Offset pTop;
    final Offset pBottom;
    final Offset pLeft;
    final Offset pRight;

    if (crossContour != null) {
      pJunction = Offset(crossContour!.junction.dx * size.width, crossContour!.junction.dy * size.height);
      pTop = Offset(crossContour!.stemTop.dx * size.width, crossContour!.stemTop.dy * size.height);
      pBottom = Offset(crossContour!.stemBottom.dx * size.width, crossContour!.stemBottom.dy * size.height);
      pLeft = Offset(crossContour!.barLeft.dx * size.width, crossContour!.barLeft.dy * size.height);
      pRight = Offset(crossContour!.barRight.dx * size.width, crossContour!.barRight.dy * size.height);
    } else {
      pJunction = Offset(crossCenter.dx * size.width, crossCenter.dy * size.height);
      const topExtent = 48.0;
      const botExtent = 115.0;
      const barExtent = 65.0;
      pTop = Offset(pJunction.dx, pJunction.dy - topExtent);
      pBottom = Offset(pJunction.dx, pJunction.dy + botExtent);
      pLeft = Offset(pJunction.dx - barExtent, pJunction.dy);
      pRight = Offset(pJunction.dx + barExtent, pJunction.dy);
    }

    final pulse = 0.88 + 0.12 * sin(animationValue * 3.5);

    // 2. Localized Holy Halo (Нимб) centered strictly at the cross junction
    final haloRadius = 42.0 * pulse;
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFBE6), // Core brilliant white-gold
          const Color(0xFFFFD700).withValues(alpha: 0.65), // Divine Gold
          const Color(0xFFFF9800).withValues(alpha: 0.20), // Warm Amber
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: pJunction, radius: haloRadius));

    canvas.drawCircle(pJunction, haloRadius, haloPaint);

    // 3. Physical Cross Contour Golden Neon Glow (Подсветка реального контура)
    // Layer A: Wide atmospheric gold aura
    final auraPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: (0.35 * pulse).clamp(0.15, 0.55))
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    canvas.drawLine(pTop, pBottom, auraPaint);
    canvas.drawLine(pLeft, pRight, auraPaint);

    // Layer B: Focused Golden Neon Glow
    final neonPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.88)
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    canvas.drawLine(pTop, pBottom, neonPaint);
    canvas.drawLine(pLeft, pRight, neonPaint);

    // Layer C: Core brilliant sacred white-gold thread
    final corePaint = Paint()
      ..color = const Color(0xFFFFFDF5)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pTop, pBottom, corePaint);
    canvas.drawLine(pLeft, pRight, corePaint);

    // Subtle holy flare crosslets at arm ends
    final tipGlow = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);
    canvas.drawCircle(pTop, 3.5, tipGlow);
    canvas.drawCircle(pBottom, 3.5, tipGlow);
    canvas.drawCircle(pLeft, 3.5, tipGlow);
    canvas.drawCircle(pRight, 3.5, tipGlow);

    // 4. Divine Strike Light Beam to Target Phantom (if phantom is active in room)
    if (targetEntity != null && targetEntity!.banishProgress < 1.0) {
      final ghostPixel = Offset(
        targetEntity!.screenPosition.dx * size.width,
        targetEntity!.screenPosition.dy * size.height,
      );

      final beamPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFFDF5),
            const Color(0xFFFFD700).withValues(alpha: 0.85),
            const Color(0xFFFF9800).withValues(alpha: 0.45),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.75, 1.0],
        ).createShader(Rect.fromPoints(pJunction, ghostPixel))
        ..strokeWidth = 4.0 + 2.0 * sin(animationValue * 8.0)
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5.0);

      canvas.drawLine(pJunction, ghostPixel, beamPaint);

      // Holy banishing impact flare on the phantom
      final impactRadius = 38.0 * (0.8 + 0.2 * sin(animationValue * 12.0));
      final impactPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFBE6),
            const Color(0xFFFFD700).withValues(alpha: 0.60),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: ghostPixel, radius: impactRadius));

      canvas.drawCircle(ghostPixel, impactRadius, impactPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrossRadiancePainter oldDelegate) => true;
}
