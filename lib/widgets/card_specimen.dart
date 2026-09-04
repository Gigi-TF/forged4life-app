import 'package:flutter/material.dart';
import '../theme/f4l_theme.dart';

/// The card on the welcome screen, before anyone has one.
///
/// Same brand band as the real card, so what a stranger sees here is exactly
/// what lands in their wallet a minute later. The personal lines are left as
/// placeholder bars — showing a made-up name three seconds before someone
/// hands over their own details makes them wonder whose account they are
/// looking at.
class CardSpecimen extends StatelessWidget {
  const CardSpecimen({super.key});

  static const _rail = 46.0;
  static const _band = 0.30;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.62,
        child: LayoutBuilder(
          builder: (context, box) => Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: F4L.cardTint,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: F4L.teal.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: _rail,
                  decoration: const BoxDecoration(gradient: F4L.rail),
                  child: const RotatedBox(
                    quarterTurns: 3,
                    child: Center(
                      child: Text('LOYALTY CARD',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.2,
                            color: Colors.white,
                          )),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _brandBand(box.maxHeight * _band),
                      Expanded(child: _body()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _brandBand(double height) => SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF013A3D),
                    Color(0xFF02656A),
                    Color(0xFF046B60),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -34,
              bottom: -34,
              child: SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(painter: _BandArcs()),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(
                          text: 'SkillsForge',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: '360',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: F4L.orange.withValues(alpha: 0.95),
                            height: 1,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('DEVELOPING SKILLS FOR LIFE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.4,
                        color: Color(0xFF94BEBE),
                      )),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _body() => Stack(
        children: [
          Positioned(
            right: -70,
            bottom: -80,
            child: SizedBox(
              width: 210,
              height: 210,
              child: CustomPaint(painter: _Arcs()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text('CARDHOLDER',
                          style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: Color(0xFF7C9698))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: F4L.orange.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text('YOURS',
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: F4L.orangeDeep)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Placeholder bars rather than a name. Obviously a blank
                // waiting to be filled, and it cannot be mistaken for
                // somebody's account.
                _bar(width: 148, height: 14),
                const SizedBox(height: 8),
                _bar(width: 104, height: 10),

                const Spacer(),

                const Text('TALENT FORGED. PURPOSE LIVED.',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.9,
                        color: Color(0xFF7C9698))),
              ],
            ),
          ),
        ],
      );

  Widget _bar({required double width, required double height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: F4L.teal.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
}

class _Arcs extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    for (final (r, colour, w) in [
      (size.width * 0.46, F4L.orange.withValues(alpha: 0.40), 4.0),
      (size.width * 0.36, F4L.tealMid.withValues(alpha: 0.34), 3.2),
      (size.width * 0.27, F4L.orange.withValues(alpha: 0.22), 2.6),
    ]) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        3.45,
        2.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = colour,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BandArcs extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    for (final (r, colour, w) in [
      (size.width * 0.46, F4L.orange.withValues(alpha: 0.20), 5.0),
      (size.width * 0.32, Colors.white.withValues(alpha: 0.14), 3.5),
    ]) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        3.45,
        2.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = colour,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
