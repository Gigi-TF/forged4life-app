import 'package:flutter/material.dart';

import '../theme/f4l_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/membership_card.dart';
import 'join_type_screen.dart';
import 'sign_in_screen.dart';

/// Leads with what SkillsForge360 does, then shows the card as the way in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                  'Thirteen transformational journeys across five forges — '
                  'contextualised for Zimbabwe, built for the world.',
                  style: TextStyle(fontSize: 15, height: 1.62, color: mute),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: _Fact(figure: '13', label: 'programmes')),
                    SizedBox(width: 9),
                    Expanded(child: _Fact(figure: '5', label: 'forges')),
                    SizedBox(width: 9),
                    Expanded(child: _Fact(figure: '1', label: 'PATHWAY™')),
                  ],
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
                    MaterialPageRoute(builder: (_) => const JoinTypeScreen()),
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
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
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
                      Text('Harare · Zimbabwe · Launching October 2026',
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

    const card = MembershipCard(
      name: 'Chiedza Mutasa',
      cardNumber: 'FL 360 · 0447 2291',
      tier: 'Tempered',
    );

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

class _Fact extends StatelessWidget {
  const _Fact({required this.figure, required this.label});
  final String figure;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            BlendText(figure,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      );
}
