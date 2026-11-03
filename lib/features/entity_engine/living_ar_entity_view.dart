import 'dart:math';
import 'package:flutter/material.dart';
import 'procedural_entity_spawner.dart';
import '../camera/camera_shader_controller.dart';

/// Renders a living, high-fidelity, fully animated AR apparition in physical room space.
/// Combines authentic high-resolution concept details with living breathing physics,
/// multi-layered spectral aura bloom, flickering specular eye/candle flares,
/// and camera mode color grading (Night Vision, Thermal, VHS, Normal).
class LivingAREntityView extends StatelessWidget {
  final ProceduralEntityInstance entity;
  final double animationValue;
  final ActiveFilterType cameraFilter;

  const LivingAREntityView({
    super.key,
    required this.entity,
    required this.animationValue,
    required this.cameraFilter,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenX = entity.screenPosition.dx * screenSize.width;
    final screenY = entity.screenPosition.dy * screenSize.height;

    // 1. Organic levitation and breathing physics
    final floatY = sin(animationValue * 3.5) * 8.0;
    final driftX = cos(animationValue * 2.2) * 5.0;
    final breathe = 1.0 + 0.035 * sin(animationValue * 4.0);
    final tiltAngle = sin(animationValue * 2.8) * 0.035;

    // Dynamic distance scaling
    final double distScale = (3.4 / entity.distance).clamp(0.65, 1.85) * entity.scale * breathe;

    // Base dimensions by archetype
    double baseWidth;
    double baseHeight;
    String spriteAsset;
    Color auraColor;

    if (entity.archetype == 6.0) {
      // Haunt Drone (Winged Demon)
      baseWidth = 290.0 * distScale;
      baseHeight = 215.0 * distScale;
      spriteAsset = 'assets/images/entities/haunt_drone_sprite.png';
      auraColor = const Color(0xFFFFB703);
    } else if (entity.archetype == 7.0) {
      // Emperor Paul I (Tricorn hat with candle)
      baseWidth = 195.0 * distScale;
      baseHeight = 245.0 * distScale;
      spriteAsset = 'assets/images/entities/paul_first_sprite.png';
      auraColor = const Color(0xFF00E5FF);
    } else if (entity.archetype == 5.0) {
      // Inverted Raven
      baseWidth = 150.0 * distScale;
      baseHeight = 250.0 * distScale;
      spriteAsset = 'assets/images/entities/inverted_raven_sprite.png';
      auraColor = const Color(0xFFFF5400);
    } else if (entity.archetype == 4.0) {
      // White Cemetery Watcher (Ethereal humanoid guardian)
      baseWidth = 185.0 * distScale;
      baseHeight = 265.0 * distScale;
      spriteAsset = 'assets/images/entities/white_cemetery_watcher_sprite.png';
      auraColor = const Color(0xFFF0F8FF);
    } else {
      // Flying Morok (Floating skull with smoke trail)
      baseWidth = 280.0 * distScale;
      baseHeight = 195.0 * distScale;
      spriteAsset = 'assets/images/entities/flying_head_phantom_sprite.png';
      auraColor = const Color(0xFF52B788);
    }

    final double alpha = ((1.0 - entity.banishProgress) * (0.88 + 0.12 * sin(animationValue * 5.0)))
        .clamp(0.0, 1.0);

    return Positioned(
      left: screenX - (baseWidth / 2) + driftX,
      top: screenY - (baseHeight / 2) + floatY,
      width: baseWidth,
      height: baseHeight,
      child: Transform.rotate(
        angle: tiltAngle,
        child: IgnorePointer(
          child: Opacity(
            opacity: alpha,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ========================================================
                // 1. LAYER 1: PULSATING SPECTRAL AURA & ECTOPLASM HALO
                // ========================================================
                Container(
                  width: baseWidth * 1.05,
                  height: baseHeight * 1.05,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        auraColor.withValues(alpha: 0.28 + 0.08 * sin(animationValue * 6.0)),
                        auraColor.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),

                // ========================================================
                // 2. LAYER 2: HIGH-RESOLUTION SEAMLESS AR APPARITION
                // ========================================================
                _buildModeFilteredSprite(spriteAsset, baseWidth, baseHeight),

                // ========================================================
                // 3. LAYER 3: SPECULAR LIVING FIRE (EYES / CANDLE FLAME)
                // ========================================================
                if (entity.archetype == 6.0) ...[
                  // Haunt Drone: Burning yellow demonic eyes at head level
                  _buildDemonEyeFlares(baseWidth, baseHeight),
                ] else if (entity.archetype == 7.0) ...[
                  // Paul I: Radiant candle flame flare with organic flicker
                  _buildCandleFlameFlare(baseWidth, baseHeight),
                ] else if (entity.archetype == 5.0) ...[
                  // Inverted Raven: Piercing amber eye glint
                  _buildRavenEyeGlint(baseWidth, baseHeight),
                ],

                // ========================================================
                // 4. LAYER 4: SACRED EXORCISM DISSOLUTION EMBERS
                // ========================================================
                if (entity.banishProgress > 0.0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.amberAccent.withValues(alpha: (0.90 * entity.banishProgress).clamp(0.0, 1.0)),
                            Colors.white.withValues(alpha: (0.75 * entity.banishProgress).clamp(0.0, 1.0)),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.40, 1.0],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Adapts entity appearance to active viewfinder sensor mode
  Widget _buildModeFilteredSprite(String asset, double width, double height) {
    Widget img = Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );

    // Apply sensory color grading based on camera mode
    switch (cameraFilter) {
      case ActiveFilterType.nightVision:
        // Night Vision: Phosphor infrared luminescence
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.15, 0.70, 0.15, 0.0,  0.0,
            0.10, 1.15, 0.10, 0.0, 15.0,
            0.05, 0.60, 0.15, 0.0,  0.0,
            0.00, 0.00, 0.00, 1.0,  0.0,
          ]),
          child: img,
        );
      case ActiveFilterType.thermal:
        // Thermal Mode: Heat-signature false color
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.20, 0.20, 0.00, 0.0, 30.0,
            0.30, 0.90, 0.00, 0.0, 10.0,
            0.00, 0.10, 0.80, 0.0,  0.0,
            0.00, 0.00, 0.00, 1.0,  0.0,
          ]),
          child: img,
        );
      case ActiveFilterType.vhs:
        // VHS Mode: Analog tape color bleed
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.95, 0.08, 0.05, 0.0, 12.0,
            0.05, 0.90, 0.08, 0.0, 10.0,
            0.08, 0.08, 0.82, 0.0,  8.0,
            0.00, 0.00, 0.00, 1.0,  0.0,
          ]),
          child: img,
        );
      case ActiveFilterType.normal:
        return img;
    }
  }

  /// Piercing demonic yellow eyes flickering with living fire
  Widget _buildDemonEyeFlares(double w, double h) {
    final flicker = 0.82 + 0.18 * sin(animationValue * 16.0);
    final eyeSize = 14.0 * flicker;

    return Positioned(
      top: h * 0.40, // At demon eye level on head
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFirePoint(eyeSize, const Color(0xFFFFD166)),
          SizedBox(width: w * 0.045),
          _buildFirePoint(eyeSize, const Color(0xFFFFD166)),
        ],
      ),
    );
  }

  /// Paul I: Warm flickering candle flame bloom
  Widget _buildCandleFlameFlare(double w, double h) {
    final flicker = 0.85 + 0.15 * sin(animationValue * 12.0 + cos(animationValue * 7.0));
    final flameRadius = 22.0 * flicker;

    return Positioned(
      left: w * 0.16,
      top: h * 0.45,
      child: Container(
        width: flameRadius * 2,
        height: flameRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFFFFDF5), // Core incandescent white
              const Color(0xFFFFD700).withValues(alpha: 0.85), // Warm gold
              const Color(0xFFFF6F00).withValues(alpha: 0.35), // Amber rim
              Colors.transparent,
            ],
            stops: const [0.0, 0.25, 0.60, 1.0],
          ),
        ),
      ),
    );
  }

  /// Inverted Raven: Burning amber eye glint
  Widget _buildRavenEyeGlint(double w, double h) {
    final flicker = 0.85 + 0.15 * sin(animationValue * 10.0);
    final glintSize = 10.0 * flicker;

    return Positioned(
      left: w * 0.48,
      top: h * 0.77, // Eye position near downward beak
      child: _buildFirePoint(glintSize, const Color(0xFFFF6F00)),
    );
  }

  Widget _buildFirePoint(double size, Color coreColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white,
            coreColor.withValues(alpha: 0.90),
            coreColor.withValues(alpha: 0.30),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.70, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: coreColor.withValues(alpha: 0.75),
            blurRadius: 8.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
    );
  }
}
