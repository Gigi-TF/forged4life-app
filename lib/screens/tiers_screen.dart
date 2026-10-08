import 'package:flutter/material.dart';

import '../services/tiers_api.dart';
import '../theme/f4l_theme.dart';

/// How the ladder works.
///
/// Every number comes from the server, which reads it from config — so this
/// screen cannot drift from the real rules. A hardcoded "25 sparks a day"
/// becomes a lie the first time someone tunes the economy, and a loyalty
/// scheme that misstates its own rules is worse than one that explains
/// nothing.
class TiersScreen extends StatefulWidget {
  const TiersScreen({super.key});

  @override
  State<TiersScreen> createState() => _TiersScreenState();
}

class _TiersScreenState extends State<TiersScreen> {
  late Future<TierInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = TiersApi().load();
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('How tiers work')),
      body: FutureBuilder<TierInfo>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData) {
            return Center(
              child: Text('Could not load the tiers.',
                  style: TextStyle(color: mute)),
            );
          }

          final info = snap.data!;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                children: [
                  const BlendText('Two things, not one.',
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          height: 1.25)),
                  const SizedBox(height: 12),
                  Text(
                    'Your tier is how much you save. Your sparks are what you '
                    'spend. They move independently — redeeming a reward never '
                    'costs you your tier.',
                    style: TextStyle(fontSize: 15, height: 1.65, color: mute),
                  ),
                  const SizedBox(height: 26),
                  _head('THE LADDER', mute),
                  const SizedBox(height: 4),
                  Text(
                    'Your tier rises on everything you have ever earned, and '
                    'never falls when you spend.',
                    style: TextStyle(fontSize: 13.5, height: 1.6, color: mute),
                  ),
                  const SizedBox(height: 16),
                  ...info.tiers.map((t) => _TierCard(
                        tier: t,
                        lifetime: info.lifetime,
                        showProgress: info.loyalty,
                      )),
                  const SizedBox(height: 26),
                  _head('EARNING SPARKS', mute),
                  const SizedBox(height: 14),
                  ...info.earn.map((e) => _EarnRow(rule: e)),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: F4L.teal.withValues(alpha: 0.07),
                      border:
                          Border.all(color: F4L.teal.withValues(alpha: 0.25)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Why spending does not cost you a tier',
                            style: TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 7),
                        Text(
                          'If redeeming dropped your tier, the sensible move '
                          'would be to hoard sparks and never use them. So it '
                          'does not. Your tier counts everything you have ever '
                          'earned; your balance is what is left to spend.',
                          style: TextStyle(
                              fontSize: 13.5, height: 1.6, color: mute),
                        ),
                      ],
                    ),
                  ),
                  if (!info.loyalty) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: F4L.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Day passes do not earn sparks or hold a tier. Become '
                        'a member and you start at the first rung with a '
                        'welcome bonus.',
                        style:
                            TextStyle(fontSize: 13.5, height: 1.6, color: mute),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _head(String t, Color? mute) => Text(t,
      style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
          color: mute));
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.lifetime,
    required this.showProgress,
  });

  final TierStep tier;
  final int lifetime;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final here = tier.current && showProgress;
    final done = tier.reached && showProgress;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: here
              ? F4L.orange.withValues(alpha: 0.09)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
          border: Border.all(
            color: here
                ? F4L.orange.withValues(alpha: 0.55)
                : Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: here ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: done || here ? F4L.blend : null,
              color: done || here
                  ? null
                  : Theme.of(context).dividerColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('${tier.discount}%',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: done || here ? Colors.white : mute)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(tier.label,
                      style: const TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.w800)),
                  if (here) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: F4L.orange,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text('YOU',
                          style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(
                  tier.threshold == 0
                      ? '${tier.discount}% off from the day you join'
                      : '${tier.discount}% off · '
                          '${_n(tier.threshold)} lifetime sparks',
                  style: TextStyle(fontSize: 12.5, color: mute),
                ),
              ],
            ),
          ),
          if (done && !here)
            Icon(Icons.check_circle,
                size: 19, color: F4L.teal.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }

  static String _n(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({required this.rule});
  final EarnRule rule;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 54),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: F4L.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('+${rule.points}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: F4L.orange)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(rule.label,
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 7),
                  Text(rule.repeat,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: mute)),
                ]),
                const SizedBox(height: 2),
                Text(rule.detail,
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: mute)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
