import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/need.dart';
import 'baby_avatar.dart';

/// Illustrated nursery backdrop + 5-layer [BabyAvatar] stage card.
class NurseryStage extends StatelessWidget {
  const NurseryStage({
    super.key,
    required this.need,
    this.tone = AppConstants.defaultBabyTone,
    this.expression = 'calm',
    this.poseOverride,
    this.height = 216,
    this.avatarSize = 168,
    this.hopAnimation,
    this.topLeftBadge,
    this.showSparkle = false,
  });

  final MaternalNeed need;
  final String tone;
  final String expression;
  final String? poseOverride;
  final double height;
  final double avatarSize;
  final Animation<double>? hopAnimation;
  final Widget? topLeftBadge;
  final bool showSparkle;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Illustrated pastel storybook (Everyday) or twilight nursery (Halloween)
            Positioned.fill(
              child: CustomPaint(
                painter: _StorybookStagePainter(
                  isHalloween: palette.isHalloween,
                  needColor: need.color,
                ),
              ),
            ),

            // Everyday generated pastel nursery window backdrop
            if (!palette.isHalloween)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/stage/pastel-everyday-stage.jpg',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

            // Halloween nursery texture overlay
            if (palette.isHalloween)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.45,
                  child: Image.asset(
                    'assets/images/stage/night-nursery-violet.png',
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),

            // Pumpkin moon accent in Halloween mode
            if (palette.isHalloween)
              Positioned(
                top: 10,
                right: 16,
                child: Image.asset(
                  'assets/images/stage/pumpkin-moon.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

            // Sparkle overlay on check-in celebration
            if (showSparkle && palette.isHalloween)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.7,
                    child: Image.asset(
                      'assets/images/stage/costume-sparkle-cut.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

            // Soft warm ambient glow behind baby so it blends into pastel window
            Positioned(
              bottom: 12,
              child: Container(
                width: avatarSize * 0.85,
                height: avatarSize * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (palette.isHalloween
                              ? palette.moon
                              : const Color(0xFFFFF8EE))
                          .withValues(alpha: palette.isHalloween ? 0.14 : 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Soft ground shadow under baby
            Positioned(
              bottom: 14,
              child: Container(
                width: avatarSize * 0.54,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: palette.isHalloween ? 0.28 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            // 5-layer Baby Paper-Doll
            Positioned(
              bottom: 6,
              child: BabyAvatar(
                need: need,
                tone: tone,
                expression: expression,
                poseOverride: poseOverride,
                size: avatarSize,
                hopAnimation: hopAnimation,
              ),
            ),

            // Top-left floating pill badge
            if (topLeftBadge != null)
              Positioned(top: 12, left: 12, child: topLeftBadge!),
          ],
        ),
      ),
    );
  }
}

/// Paints a soft pastel storybook scene (sky, fluffy clouds, layered hills,
/// delicate blossoms & sparkles) in Everyday mode, or starry twilight in Halloween.
class _StorybookStagePainter extends CustomPainter {
  const _StorybookStagePainter({
    required this.isHalloween,
    required this.needColor,
  });

  final bool isHalloween;
  final Color needColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isHalloween
            ? const [Color(0xFF2B1E42), Color(0xFF1A1228)]
            : const [Color(0xFFDCEBF7), Color(0xFFF3EEF8), Color(0xFFFDF5EC)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    if (!isHalloween) {
      // 2. Soft pastel sun glow (top-right)
      canvas.drawCircle(
        Offset(w * 0.84, h * 0.22),
        22,
        Paint()..color = const Color(0xFFFFE7A8).withValues(alpha: 0.75),
      );
      canvas.drawCircle(
        Offset(w * 0.84, h * 0.22),
        34,
        Paint()..color = const Color(0xFFFFE7A8).withValues(alpha: 0.25),
      );

      // 3. Fluffy pastel clouds
      final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.78);
      _drawCloud(canvas, Offset(w * 0.18, h * 0.28), 1.0, cloudPaint);
      _drawCloud(canvas, Offset(w * 0.76, h * 0.36), 0.78, cloudPaint);

      // 4. Back rolling pastel hill (soft sage-lavender)
      final backHill = Path()
        ..moveTo(0, h * 0.72)
        ..quadraticBezierTo(w * 0.28, h * 0.56, w * 0.58, h * 0.68)
        ..quadraticBezierTo(w * 0.82, h * 0.76, w, h * 0.62)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(
        backHill,
        Paint()..color = const Color(0xFFD6E5D0).withValues(alpha: 0.85),
      );

      // 5. Front rolling pastel meadow (warm sage-cream)
      final frontHill = Path()
        ..moveTo(0, h * 0.80)
        ..quadraticBezierTo(w * 0.32, h * 0.68, w * 0.66, h * 0.78)
        ..quadraticBezierTo(w * 0.86, h * 0.83, w, h * 0.74)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(
        frontHill,
        Paint()..color = const Color(0xFFC7DBBE).withValues(alpha: 0.9),
      );

      // 6. Delicate pastel blossoms on left & right
      _drawBlossom(
        canvas,
        Offset(w * 0.14, h * 0.74),
        const Color(0xFFF3B5C1),
        6,
      );
      _drawBlossom(
        canvas,
        Offset(w * 0.21, h * 0.79),
        const Color(0xFFF7D58B),
        5,
      );
      _drawBlossom(
        canvas,
        Offset(w * 0.85, h * 0.73),
        const Color(0xFFF3B5C1),
        6,
      );
      _drawBlossom(
        canvas,
        Offset(w * 0.79, h * 0.80),
        const Color(0xFFD5C4EB),
        4.5,
      );

      // 7. Gentle 4-point sparkles
      _drawSparkle(
        canvas,
        Offset(w * 0.32, h * 0.24),
        5,
        Colors.white.withValues(alpha: 0.85),
      );
      _drawSparkle(
        canvas,
        Offset(w * 0.68, h * 0.20),
        4,
        Colors.white.withValues(alpha: 0.75),
      );
    } else {
      // Halloween twilight hills & stars
      final starPaint = Paint()
        ..color = const Color(0xFFF6EFE4).withValues(alpha: 0.55);
      _drawSparkle(canvas, Offset(w * 0.20, h * 0.24), 4.5, starPaint.color);
      _drawSparkle(canvas, Offset(w * 0.36, h * 0.16), 3.5, starPaint.color);
      _drawSparkle(canvas, Offset(w * 0.66, h * 0.22), 4.0, starPaint.color);
      _drawSparkle(canvas, Offset(w * 0.78, h * 0.42), 3.5, starPaint.color);

      final hillPath = Path()
        ..moveTo(0, h * 0.78)
        ..quadraticBezierTo(w * 0.35, h * 0.66, w * 0.68, h * 0.77)
        ..quadraticBezierTo(w * 0.88, h * 0.82, w, h * 0.73)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(
        hillPath,
        Paint()..color = const Color(0xFF34244C).withValues(alpha: 0.7),
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 64 * scale, height: 22 * scale),
        Radius.circular(14 * scale),
      ),
      paint,
    );
    canvas.drawCircle(
      center + Offset(-12 * scale, -8 * scale),
      13 * scale,
      paint,
    );
    canvas.drawCircle(
      center + Offset(6 * scale, -11 * scale),
      16 * scale,
      paint,
    );
  }

  void _drawBlossom(Canvas canvas, Offset center, Color color, double r) {
    final stemPaint = Paint()
      ..color = const Color(0xFF8FB084)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + const Offset(0, 14), stemPaint);

    final petalPaint = Paint()..color = color;
    for (final offset in [
      Offset(0, -r * 0.7),
      Offset(r * 0.7, 0),
      Offset(0, r * 0.7),
      Offset(-r * 0.7, 0),
    ]) {
      canvas.drawCircle(center + offset, r * 0.55, petalPaint);
    }
    canvas.drawCircle(
      center,
      r * 0.4,
      Paint()..color = const Color(0xFFFFF5C0),
    );
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StorybookStagePainter oldDelegate) =>
      oldDelegate.isHalloween != isHalloween ||
      oldDelegate.needColor != needColor;
}
