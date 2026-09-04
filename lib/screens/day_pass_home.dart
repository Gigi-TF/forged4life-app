import 'package:flutter/material.dart';

import '../services/loyalty_api.dart';
import '../services/upgrade_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';

/// What a day visitor sees instead of the loyalty stack.
///
/// Not a zeroed version of the member screen. A balance of 0 and a progress
/// bar that never moves reads as "you are failing"; this reads as "here is
/// what you are not in yet, and it is free".
class DayPassHome extends StatefulWidget {
  const DayPassHome({
    super.key,
    required this.perks,
    required this.onUpgraded,
  });

  final MemberPerks perks;
  final Future<void> Function() onUpgraded;

  @override
  State<DayPassHome> createState() => _DayPassHomeState();
}

class _DayPassHomeState extends State<DayPassHome> {
  bool _busy = false;

  Future<void> _upgrade() async {
    setState(() => _busy = true);

    try {
      final msg = await UpgradeApi().toMember();
      await widget.onUpgraded();

      if (!mounted) return;
      setState(() => _busy = false);

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Welcome in'),
          content: Text('$msg\n\nYour card no longer expires, and you start '
              'earning from today.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(c),
              style: FilledButton.styleFrom(backgroundColor: F4L.orange),
              child: const Text('Good'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final p = widget.perks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
            border: Border.all(
                color: const Color(0xFFB07A0E).withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            ForgeIcons.dayPass.tile(size: 44),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You are on a day pass',
                      style: TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w800)),
                  Text('Full access today. It ends tonight.',
                      style: TextStyle(fontSize: 12.5, color: mute)),
                ],
              ),
            ),
          ]),
        ),

        const SizedBox(height: 20),
        Text('WHAT MEMBERS GET',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: mute)),
        const SizedBox(height: 12),

        // The rates, stated plainly. More persuasive than a balance of zero,
        // and it is the truth rather than a marketing line.
        _perk(context, ForgeIcons.card, '${p.discount}% off, straight away',
            'The café, the bookstore, room bookings and every partner — '
            'rising to ${p.topDiscount}% as you go.', mute),
        _perk(context, (Icons.local_fire_department_rounded, ForgeTone.ember),
            '${p.checkIn} sparks a day',
            'Just for opening the app. ${p.visit} more every time you are '
            'scanned in at reception.', mute),
        _perk(context, ForgeIcons.perks, 'Sparks buy real things',
            'Coffee, passport photos, a free conference room hour — the '
            'rewards store is members only.', mute),
        _perk(context, (Icons.card_giftcard_rounded, ForgeTone.gold),
            '${p.signup} sparks to start',
            'Credited the moment you join.', mute),

        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              F4L.teal.withValues(alpha: 0.10),
              F4L.orange.withValues(alpha: 0.08),
            ]),
            border: Border.all(color: F4L.teal.withValues(alpha: 0.32)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Membership is free.',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'You already have an account and a password. There is nothing '
                'to fill in — one tap and your card stops expiring.',
                style: TextStyle(fontSize: 13.5, height: 1.55, color: mute),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _upgrade,
                style: FilledButton.styleFrom(
                  backgroundColor: F4L.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.3, color: Colors.white))
                    : const Text('Become a member',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _perk(BuildContext c, (IconData, ForgeTone) spec, String title,
          String body, Color? mute) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(c).colorScheme.surface.withValues(alpha: 0.85),
            border: Border.all(
                color: Theme.of(c).dividerColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            spec.tile(size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(body,
                      style: TextStyle(
                          fontSize: 12.5, height: 1.45, color: mute)),
                ],
              ),
            ),
          ]),
        ),
      );
}
