import 'package:flutter/material.dart';

import '../screens/tiers_screen.dart';
import '../theme/f4l_theme.dart';

/// The balance card at the top of Rewards.
///
/// Tappable, because the tier badge on it is exactly where someone looks when
/// they wonder "what is Ember?" — not at a question mark in the app bar. The
/// answer should be where the question is asked.
class SparksBalanceCard extends StatelessWidget {
  const SparksBalanceCard({
    super.key,
    required this.balance,
    required this.tierLabel,
    required this.discount,
    this.isDayPass = false,
  });

  final int balance;
  final String tierLabel;
  final int discount;
  final bool isDayPass;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TiersScreen()),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          gradient: F4L.blend,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text('YOUR SPARKS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.7,
                          color: Colors.white70)),
                ),
                if (!isDayPass)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(tierLabel.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Colors.white)),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            Text('$balance',
                style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: Colors.white)),

            const SizedBox(height: 6),

            /*
             * The chevron is what makes the card read as tappable.
             *
             * Without it this is a card with a number on it, and nobody
             * discovers the screen behind it — which is the whole reason the
             * explainer exists.
             */
            Row(children: [
              Flexible(
                child: Text(
                  isDayPass
                      ? 'Day passes do not earn sparks'
                      : 'Plus $discount% off everywhere, automatically.',
                  style: const TextStyle(
                      fontSize: 13.5, height: 1.5, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 7),
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.arrow_forward_ios,
                    size: 11, color: Colors.white70),
              ),
            ]),

            const SizedBox(height: 10),

            Row(children: [
              const Icon(Icons.help_outline, size: 13, color: Colors.white60),
              const SizedBox(width: 6),
              Text(
                isDayPass ? 'See what membership gives you' : 'How tiers work',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white60),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
