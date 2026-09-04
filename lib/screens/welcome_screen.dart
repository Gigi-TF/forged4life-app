import 'package:flutter/material.dart';

import '../theme/f4l_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/card_specimen.dart';
import 'auth_screen.dart';

/// Leads with what SkillsForge360 does, then shows the card as the way in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// The five cohort schools.
  ///
  /// Names rather than counts. "19 programmes" is wrong the first time one is
  /// added or retired, and nobody remembers to change a number buried in an
  /// app — whereas a sixth forge is a line added here, deliberately.
  static const _forges = [
    'Launch',
    'Professional',
    'Leadership',
    'Life',
    'Experience',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: theme.toggle,
                    tooltip: dark ? 'Light mode' : 'Dark mode',
                    icon: Icon(
                      dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 21,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: BlendText(
                        'Talent Forged.\nPurpose Lived.',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      dark
                          ? 'assets/images/logo-icon-reverse.png'
                          : 'assets/images/logo-icon.png',
                      height: 78,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'A coaching, mentoring and experiential learning hub in Harare. '
                  'Transformational journeys for every professional season — '
                  'contextualised for Zimbabwe, built for the world.',
                  style: TextStyle(fontSize: 15, height: 1.62, color: mute),
                ),
                const SizedBox(height: 22),
                Text('THE FIVE FORGES',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: mute)),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _forges.map((f) => _ForgeChip(name: f)).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Built on the PATHWAY™ framework, and every journey ends '
                  'with a personal Scorecard.',
                  style: TextStyle(fontSize: 13.5, height: 1.55, color: mute),
                ),
                const SizedBox(height: 28),
                Text('YOUR WAY IN',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: mute)),
                const SizedBox(height: 14),
                const _FloatingCard(),
                const SizedBox(height: 16),
                Text(
                  'One card for every programme, the cafeteria, the bookstore, '
                  'room bookings and every partner in the network. Free to join.',
                  style: TextStyle(fontSize: 14.5, height: 1.6, color: mute),
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AuthScreen(startOnSignUp: true)),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: F4L.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Get my card — it’s free',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                const SizedBox(height: 9),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('I already have a card',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text('A PRODUCT OF SKILLSFORGE360',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: mute)),
                      const SizedBox(height: 4),
                      Text('Harare · Zimbabwe',
                          style: TextStyle(fontSize: 12.5, color: mute)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgeChip extends StatelessWidget {
  const _ForgeChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text.rich(TextSpan(children: [
          const TextSpan(
            text: 'FORGE ',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: F4L.orange),
          ),
          TextSpan(
            text: name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ])),
      );
}

class _FloatingCard extends StatefulWidget {
  const _FloatingCard();

  @override
  State<_FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<_FloatingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // A specimen, not a made-up member. Showing a stranger someone else's
    // name three seconds before they hand over their own details is exactly
    // the wrong feeling.
    const card = CardSpecimen();

    if (reduceMotion) {
      return Transform.rotate(angle: -0.07, child: card);
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -13 * t),
          child: Transform.rotate(angle: -0.075 + 0.02 * t, child: child),
        );
      },
      child: card,
    );
  }
}
