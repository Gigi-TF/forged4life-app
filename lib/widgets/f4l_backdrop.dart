import 'package:flutter/material.dart';
import '../theme/f4l_theme.dart';

/// The app background, behind every screen.
///
/// Light mode is a mint field — deeper in the middle, easing out toward the
/// edges, never reaching white. The white card then has something to sit on
/// instead of vanishing into the page.
class F4LBackdrop extends StatelessWidget {
  const F4LBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      // A solid base under the gradient, so no seam shows during a route
      // transition or overscroll.
      decoration: BoxDecoration(
        color: dark ? F4L.canvas : F4L.mintMid,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: dark
                    ? const RadialGradient(
                        center: Alignment(0, -0.15),
                        radius: 1.3,
                        colors: [Color(0xFF181729), Color(0xFF0B0A12)],
                      )
                    : const RadialGradient(
                        center: Alignment(0, -0.1),
                        radius: 1.15,
                        colors: [
                          F4L.mintCore,
                          F4L.mintMid,
                          F4L.mintRim,
                        ],
                        stops: [0.0, 0.58, 1.0],
                      ),
              ),
            ),
          ),
          if (dark) ...[
            _wash(const Alignment(0.95, -0.85), F4L.tealLift, 0.16),
            _wash(const Alignment(-0.9, 1.0), F4L.orange, 0.14),
          ],
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DotGrid(dark: dark)),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _wash(Alignment centre, Color colour, double opacity) =>
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: centre,
              radius: 0.95,
              colors: [colour.withValues(alpha: opacity), Colors.transparent],
            ),
          ),
        ),
      );
}

/// The faint dot grid from the reference. Low contrast on purpose — texture
/// you feel rather than dots you count.
class _DotGrid extends CustomPainter {
  _DotGrid({required this.dark});

  final bool dark;
  static const _spacing = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dark
          ? Colors.white.withValues(alpha: 0.035)
          : F4L.teal.withValues(alpha: 0.11);

    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      for (var x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGrid old) => old.dark != dark;
}
