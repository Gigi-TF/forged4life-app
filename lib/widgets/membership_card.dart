import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/f4l_theme.dart';

/// The membership card.
///
/// A brand band across the top carries the wordmark, the way an airline card
/// does — someone holding this out at a counter should be recognisable as a
/// SkillsForge member from arm's length, before anyone reads a word of it.
///
/// Tap to flip: the front is who you are, the back is the rotating QR.
class MembershipCard extends StatelessWidget {
  const MembershipCard({
    super.key,
    required this.name,
    required this.cardNumber,
    required this.tier,
    this.isDayPass = false,
    this.expiresLabel,
    this.showQr = false,
    this.token,
    this.secondsLeft = 60,
    this.onTap,
  });

  final String name;
  final String cardNumber;
  final String tier;
  final bool isDayPass;
  final String? expiresLabel;
  final bool showQr;
  final String? token;
  final int secondsLeft;
  final VoidCallback? onTap;

  static const _rail = 46.0;
  static const _band = 0.30; // share of the card's height

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.62,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) {
              // A real flip rather than a fade — it reads as turning the card
              // over, which is what the gesture is.
              final rotate = Tween(begin: 3.14159, end: 0.0).animate(anim);
              return AnimatedBuilder(
                animation: rotate,
                child: child,
                builder: (context, child) {
                  final showing = ValueKey(showQr) == child?.key;
                  final tilt =
                      showing ? rotate.value : (3.14159 - rotate.value) * -1;
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(tilt),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
              );
            },
            child: showQr
                ? _back(context, const ValueKey(true))
                : _front(context, const ValueKey(false)),
          ),
        ),
      );

  // ------------------------------------------------------------- front

  Widget _front(BuildContext context, Key key) => LayoutBuilder(
        key: key,
        builder: (context, box) {
          final bandHeight = box.maxHeight * _band;

          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: _shell(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _railStrip(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _brandBand(bandHeight),
                      Expanded(child: _details(context)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  /// The band. Dark teal, the wordmark centred and large.
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
                    Color(0xFF046B60)
                  ],
                ),
              ),
            ),

            // A faint arc so the band is not a flat slab.
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
                  const Text(
                    'DEVELOPING SKILLS FOR LIFE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.4,
                      color: Color(0xFF94BEBE),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _details(BuildContext context) => Stack(
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
                        color: isDayPass ? const Color(0xFFB07A0E) : F4L.orange,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(tier.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(name,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0E3437))),
                ),
                const SizedBox(height: 3),
                Text(cardNumber,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.9,
                        color: F4L.teal)),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Text('TALENT FORGED. PURPOSE LIVED.',
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.9,
                              color: Color(0xFF7C9698))),
                    ),
                    if (expiresLabel != null)
                      Text(expiresLabel!,
                          style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFFB07A0E))),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  // -------------------------------------------------------------- back

  Widget _back(BuildContext context, Key key) => Container(
        key: key,
        clipBehavior: Clip.antiAlias,
        decoration: _shell(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _railStrip(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: F4L.teal.withValues(alpha: 0.18)),
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: token == null
                              ? const Center(
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)))
                              : QrImageView(
                                  data: token!,
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF0E3437),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF0E3437),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),

                    Text(cardNumber,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                            color: Color(0xFF0E3437))),
                    const SizedBox(height: 4),

                    // The countdown is the reassurance that matters at a till:
                    // a code that looks static is a code people assume is
                    // broken when it fails.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(
                            value: secondsLeft / 60,
                            strokeWidth: 2,
                            backgroundColor: F4L.teal.withValues(alpha: 0.15),
                            valueColor:
                                const AlwaysStoppedAnimation(F4L.orange),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text('Refreshes in ${secondsLeft}s',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7C9698))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      );

  // ------------------------------------------------------------ shared

  BoxDecoration _shell() => BoxDecoration(
        gradient: isDayPass ? F4L.dayTint : F4L.cardTint,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: F4L.teal.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      );

  Widget _railStrip() => Container(
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
      );
}

/// The 360 arcs on the body.
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

/// A whisper of the same arcs inside the brand band.
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
