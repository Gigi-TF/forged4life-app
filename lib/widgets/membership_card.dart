import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/f4l_theme.dart';

/// The card, exactly as designed: white plate, vertical LOYALTY CARD rail,
/// SkillsForge360 lockup, 360 arcs bleeding off the bottom-right.
///
/// Flips to the QR on tap. The card stays white in both themes on purpose —
/// it is the brightest thing on screen, which is right for an object you hold
/// up at a counter.
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
    this.secondsLeft,
    this.onTap,
  });

  final String name;
  final String cardNumber;
  final String tier;
  final bool isDayPass;
  final String? expiresLabel;
  final bool showQr;
  final String? token;
  final int? secondsLeft;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          decoration: BoxDecoration(
            gradient: isDayPass ? F4L.dayTint : F4L.cardTint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: F4L.tealDeep.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: F4L.tealDeep.withValues(alpha: 0.22),
                blurRadius: 44,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 360 arcs, echoing the logo's open ring
              Positioned.fill(child: CustomPaint(painter: _ArcPainter())),

              // the rail
              Positioned(
                left: 0, top: 0, bottom: 0, width: 36,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDayPass
                        ? const LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Color(0xFFB07A0E), Color(0xFFD98F14), F4L.orange])
                        : F4L.rail,
                  ),
                  child: const Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'LOYALTY CARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(52, 15, 16, 15),
                child: showQr ? _qrFace() : _detailFace(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailFace() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Image.asset('assets/images/logo-icon.png', height: 46),
            const SizedBox(width: 11),
            Container(width: 1, height: 34, color: F4L.teal.withValues(alpha: 0.30)),
            const SizedBox(width: 11),
            Flexible(child: Image.asset('assets/images/logo-word.png', height: 26)),
          ]),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CARDHOLDER',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700,
                      letterSpacing: 1.7, color: Color(0xFF6C8486))),
              const Spacer(),
              _chip(tier),
            ],
          ),
          const SizedBox(height: 2),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800,
                  color: Color(0xFF00393B))),
          Text(cardNumber,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                  letterSpacing: 1.9, color: F4L.teal)),
          const Spacer(),
          Row(children: [
            const Expanded(
              child: Text('TALENT FORGED. PURPOSE LIVED.',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                      letterSpacing: 0.9, color: Color(0xFF6C8486))),
            ),
            if (isDayPass && expiresLabel != null)
              Text(expiresLabel!,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: Color(0xFFB07A0E))),
          ]),
        ],
      );

  Widget _qrFace() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: F4L.tealDeep.withValues(alpha: 0.12)),
              ),
              child: QrImageView(
                data: token ?? '',
                size: 116,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
            const SizedBox(height: 7),
            Text(cardNumber,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                    letterSpacing: 1.6, color: F4L.teal)),
            if (secondsLeft != null)
              Text('Refreshes in ${secondsLeft}s',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6C8486))),
          ],
        ),
      );

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDayPass ? const Color(0xFFB07A0E) : F4L.orange,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 8.5,
                fontWeight: FontWeight.w800, letterSpacing: 1.4)),
      );
}

/// Two concentric arcs sweeping off the bottom-right, in both brand colours.
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void arc(double radius, Offset centre, Color colour, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        start, sweep, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colour,
      );
    }

    final c = Offset(size.width + 26, size.height + 30);
    arc(118, c, F4L.orange.withValues(alpha: 0.38), 3.4, 1.5);
    arc(118, c, F4L.teal.withValues(alpha: 0.30), 4.9, 1.2);
    arc(86, c, F4L.teal.withValues(alpha: 0.24), 3.6, 1.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
