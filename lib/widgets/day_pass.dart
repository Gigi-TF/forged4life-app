import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/f4l_theme.dart';

/// The day pass.
///
/// A ticket, not a card. A boarding pass is the right model because that is
/// what this actually is — a document for one journey, on one date, that
/// stops meaning anything afterwards. A wallet card implies permanence the
/// pass does not have, and a member who upgrades gets a real card anyway.
class DayPass extends StatelessWidget {
  const DayPass({
    super.key,
    required this.reference,
    required this.name,
    required this.date,
    required this.validUntil,
    this.token,
    this.room,
    this.purpose,
    this.company,
    this.vehicleReg,
    this.purgeDays = 30,
  });

  /// Short human code — DP-4U2X. Read aloud at a gate.
  final String reference;
  final String name;
  final String date;
  final String validUntil;

  /// The rotating scan token. Null while it loads.
  final String? token;

  final String? room;
  final String? purpose;
  final String? company;
  final String? vehicleReg;
  final int purgeDays;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: F4L.teal.withValues(alpha: 0.20),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _band(),
            _stub(context),
            const _Perforation(),
            _details(context),
            Container(height: 4, decoration: const BoxDecoration(gradient: F4L.rail)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9),
              child: Text('TALENT FORGED. PURPOSE LIVED.',
                  style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: Color(0xFF7C9698))),
            ),
          ],
        ),
      );

  Widget _band() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF013A3D), Color(0xFF02656A), Color(0xFF046B60)],
          ),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(TextSpan(children: [
                const TextSpan(
                  text: 'SkillsForge',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1),
                ),
                TextSpan(
                  text: '360',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: F4L.orange.withValues(alpha: 0.95),
                      height: 1),
                ),
              ])),
            ),
            const SizedBox(height: 5),
            const Text('DEVELOPING SKILLS FOR LIFE',
                style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: Color(0xFF94BEBE))),
          ],
        ),
      );

  Widget _stub(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          children: [
            const Text('Day Pass',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: F4L.teal)),
            const SizedBox(height: 4),
            Text(reference,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4.5,
                    color: Color(0xFF0E3437))),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFD4E3E3)),
              ),
              child: SizedBox(
                width: 132,
                height: 132,
                child: token == null
                    ? const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)))
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
            const SizedBox(height: 12),
            const Text('Show this at reception on arrival',
                style: TextStyle(fontSize: 11, color: Color(0xFF7C9698))),
          ],
        ),
      );

  Widget _details(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
        child: Column(
          children: [
            _row('VISITOR', name, 'DATE', date),
            _row('VALID UNTIL', validUntil, 'ROOM', room ?? '—'),
            if (purpose != null || company != null)
              _row('PURPOSE', purpose ?? '—', 'WITH', company ?? '—',
                  last: vehicleReg == null),

            if (vehicleReg != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6EE),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VEHICLE',
                              style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                  color: Color(0xFFB07A0E))),
                          const SizedBox(height: 3),
                          Text(vehicleReg!,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0E3437))),
                        ],
                      ),
                    ),
                    // Said on the pass itself, not buried in a policy page.
                    // Someone handing over a plate number should be able to
                    // see what happens to it.
                    Text('deleted after $purgeDays days',
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFFB07A0E))),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _row(String l1, String v1, String l2, String v2, {bool last = false}) =>
      Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l1,
                        style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Color(0xFF7C9698))),
                    const SizedBox(height: 4),
                    Text(v1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E3437))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l2,
                        style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Color(0xFF7C9698))),
                    const SizedBox(height: 4),
                    Text(v2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: F4L.teal)),
                  ],
                ),
              ),
            ],
          ),
          if (!last) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFEAF1F1)),
            const SizedBox(height: 12),
          ],
        ],
      );
}

/// The tear line, with notches bitten out of each edge.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    // Matches the app background so the notches read as holes rather than
    // grey circles printed on the ticket.
    final bg = Theme.of(context).brightness == Brightness.dark
        ? F4L.canvas
        : const Color(0xFFD3E9E8);

    return SizedBox(
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _Dashes(),
            ),
          ),
          Positioned(
            left: -13,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: -13,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7D8D8)
      ..strokeWidth = 1.6;

    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 12;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
