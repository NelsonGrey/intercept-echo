import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_theme.dart';

/// Subtle signal geometry shared by branded and gameplay surfaces. It is
/// deliberately decorative and excluded from semantics.
class EchoBackdrop extends StatelessWidget {
  const EchoBackdrop({
    super.key,
    required this.palette,
    required this.child,
    this.intensity = 1,
  });

  final GameThemePalette palette;
  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: CustomPaint(
            painter: _EchoPainter(palette, intensity.clamp(0, 1)),
          ),
        ),
        child,
      ],
    );
  }
}

class InterceptEchoWordmark extends StatelessWidget {
  const InterceptEchoWordmark({
    super.key,
    required this.palette,
    this.compact = false,
  });

  final GameThemePalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final echoSize = compact ? 27.0 : 52.0;
    return Semantics(
      header: true,
      label: 'Intercept Echo',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'I N T E R C E P T',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: compact ? 10 : 15,
                fontWeight: FontWeight.w600,
                letterSpacing: compact ? 1.8 : 3.8,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ECHO',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: echoSize,
                    height: .95,
                    fontWeight: FontWeight.w700,
                    letterSpacing: compact ? 2 : 4,
                  ),
                ),
                const SizedBox(width: 5),
                _EchoGlyph(palette: palette, size: echoSize * .72),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EchoGlyph extends StatelessWidget {
  const _EchoGlyph({required this.palette, required this.size});

  final GameThemePalette palette;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _EchoGlyphPainter(palette));
}

class _EchoGlyphPainter extends CustomPainter {
  const _EchoGlyphPainter(this.palette);

  final GameThemePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(0, size.height / 2);
    final paint = Paint()
      ..color = palette.overflowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * .055)
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 3; i++) {
      final r = size.width * (.18 + i * .12);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 3,
        2 * math.pi / 3,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EchoGlyphPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class _EchoPainter extends CustomPainter {
  const _EchoPainter(this.palette, this.intensity);

  final GameThemePalette palette;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .52, size.height * .25);
    final ring = Paint()
      ..color = palette.clockTrack.withValues(alpha: .16 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, size.width * (.11 * i), ring);
    }

    final line = Paint()
      ..color = palette.overflowAccent.withValues(alpha: .20 * intensity)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), line);
    for (var i = 0; i < 8; i++) {
      final x = size.width * (i + 1) / 9;
      canvas.drawCircle(Offset(x, center.dy), i == 4 ? 3 : 1.5, line);
    }
  }

  @override
  bool shouldRepaint(_EchoPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.intensity != intensity;
}
