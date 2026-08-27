import 'package:flutter/material.dart';

import '../screens/rewards_screen.dart';
import '../services/rewards_api.dart';
import '../theme/f4l_theme.dart';

/// A compact tier summary, sized to sit under the membership card.
///
/// Loads quietly and shows nothing until it has an answer — a skeleton or a
/// spinner directly under the card would pull attention away from the thing
/// people opened the app to see.
class TierStrip extends StatefulWidget {
  const TierStrip({super.key});

  @override
  State<TierStrip> createState() => _TierStripState();
}

class _TierStripState extends State<TierStrip> {
  Rewards? _r;

  @override
  void initState() {
    super.initState();
    RewardsApi().summary().then((r) {
      if (mounted) setState(() => _r = r);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    if (r == null) return const SizedBox(height: 8);

    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final n = r.next;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RewardsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: F4L.blend,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(r.label.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  // The benefit, not the balance.
                  child: Text('${r.discount}% off everywhere',
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                ),
                Icon(Icons.chevron_right, size: 19, color: mute),
              ]),

              if (n != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    // The gate you are furthest from is the one that decides
                    // when you get there, so that is the one to show.
                    value: n.monthsProgress < n.visitsProgress
                        ? n.monthsProgress
                        : n.visitsProgress,
                    minHeight: 6,
                    backgroundColor:
                        Theme.of(context).dividerColor.withValues(alpha: 0.4),
                    valueColor: const AlwaysStoppedAnimation(F4L.orange),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _nextLine(n),
                  style: TextStyle(fontSize: 12, height: 1.4, color: mute),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text('Top tier — and it is yours for good.',
                    style: TextStyle(fontSize: 12, color: mute)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Names the single thing standing between them and the next tier, rather
  /// than listing both gates. One clear next action beats a status report.
  String _nextLine(NextTier n) {
    if (!n.visitsMet && !n.monthsMet) {
      final visits = n.visitsNeeded - n.visitsHave;
      final months = n.monthsNeeded - n.monthsHave;
      return '$visits more visit${visits == 1 ? '' : 's'} and $months more '
          'month${months == 1 ? '' : 's'} to ${n.label} · ${n.discount}% off';
    }
    if (!n.visitsMet) {
      final visits = n.visitsNeeded - n.visitsHave;
      return '$visits more visit${visits == 1 ? '' : 's'} to ${n.label} · '
          '${n.discount}% off';
    }
    if (!n.monthsMet) {
      final months = n.monthsNeeded - n.monthsHave;
      return '${n.label} in $months month${months == 1 ? '' : 's'} — you have '
          'the visits already';
    }
    return '${n.label} unlocks on your next visit';
  }
}
