import 'package:flutter/material.dart';

import '../services/rewards_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';

/// What the card is worth, and what it takes to be worth more.
///
/// Leads with the discount rather than the Sparks balance. "1,840 Sparks"
/// means nothing to anyone; "15% off, everywhere" is the reason to care.
/// Points are the mechanism, the discount is the benefit.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late Future<Rewards> _future;
  late Future<List<LedgerEntry>> _ledger;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = RewardsApi().summary();
    _ledger = RewardsApi().activity();
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Your rewards')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _future;
            },
            child: FutureBuilder<Rewards>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ListView(children: [
                    const SizedBox(height: 80),
                    Center(
                        child: Text('Could not load your rewards.',
                            style: TextStyle(color: mute))),
                  ]);
                }

                final r = snap.data!;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                  children: [
                    _headline(context, r, mute),
                    const SizedBox(height: 18),
                    if (r.next != null) _progress(context, r.next!, mute),
                    const SizedBox(height: 20),
                    _stats(context, r, mute),
                    const SizedBox(height: 24),
                    _ladderBlock(context, r, mute),
                    const SizedBox(height: 24),
                    _activityBlock(context, mute),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------- the headline: the discount, big ----------
  Widget _headline(BuildContext context, Rewards r, Color? mute) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: F4L.blend,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: F4L.orange.withValues(alpha: 0.3),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(r.label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.white)),
              if (r.founding) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text('FOUNDING',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.white)),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            Text('${r.discount}% off',
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Colors.white)),
            const SizedBox(height: 4),
            const Text(
              'the cafeteria, the bookstore, room bookings, programmes and '
              'every partner in the network.',
              style: TextStyle(
                  fontSize: 13.5, height: 1.5, color: Color(0xE6FFFFFF)),
            ),
          ],
        ),
      );

  // ---------- both gates, side by side ----------
  Widget _progress(BuildContext context, NextTier n, Color? mute) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NEXT: ${n.label.toUpperCase()} · ${n.discount}% OFF',
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6)),
            const SizedBox(height: 4),
            Text(
              'You need both — time with us, and turning up.',
              style: TextStyle(fontSize: 12.5, color: mute),
            ),
            const SizedBox(height: 14),
            _bar(
              context,
              label: 'Member for',
              have: '${n.monthsHave} of ${n.monthsNeeded} months',
              progress: n.monthsProgress,
              met: n.monthsMet,
            ),
            const SizedBox(height: 12),
            _bar(
              context,
              label: 'Visits',
              have: '${n.visitsHave} of ${n.visitsNeeded} '
                  'in the last ${n.windowDays} days',
              progress: n.visitsProgress,
              met: n.visitsMet,
            ),
          ],
        ),
      );

  Widget _bar(
    BuildContext context, {
    required String label,
    required String have,
    required double progress,
    required bool met,
  }) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (met)
            const Padding(
              padding: EdgeInsets.only(right: 5),
              child: Icon(Icons.check_circle, size: 14, color: F4L.teal),
            ),
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: met ? F4L.teal : null)),
          const Spacer(),
          Text(have, style: TextStyle(fontSize: 12, color: mute)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation(met ? F4L.teal : F4L.orange),
          ),
        ),
      ],
    );
  }

  // ---------- the numbers that make it feel real ----------
  Widget _stats(BuildContext context, Rewards r, Color? mute) => Row(
        children: [
          Expanded(
              child: _stat(context, 'Saved this year',
                  '\$${r.savedYear.toStringAsFixed(2)}', F4L.teal)),
          const SizedBox(width: 10),
          Expanded(
              child: _stat(context, 'Visits', '${r.visitsTotal}', F4L.tealMid)),
          const SizedBox(width: 10),
          Expanded(
              child: _stat(
                  context, 'Sparks', '${r.sparks}', const Color(0xFFB07A0E))),
        ],
      );

  Widget _stat(BuildContext c, String label, String value, Color colour) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(c).colorScheme.surface.withValues(alpha: 0.9),
          border: Border.all(
              color: Theme.of(c).dividerColor.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: colour)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: Theme.of(c).textTheme.bodySmall?.color)),
        ]),
      );

  // ---------- the ladder ----------
  Widget _ladderBlock(BuildContext context, Rewards r, Color? mute) {
    final currentIndex = r.ladder.indexWhere((x) => x.tier == r.tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HOW IT WORKS',
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.7)),
        const SizedBox(height: 10),
        ...r.ladder.asMap().entries.map((e) {
          final i = e.key;
          final rung = e.value;
          final reached = i <= currentIndex;
          final isNow = i == currentIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: isNow
                    ? F4L.orange.withValues(alpha: 0.08)
                    : Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.85),
                border: Border.all(
                  color: isNow
                      ? F4L.orange
                      : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  width: isNow ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(
                  reached ? Icons.check_circle : Icons.circle_outlined,
                  size: 19,
                  color: reached ? F4L.teal : mute,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rung.label,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800)),
                      Text(
                        rung.visits == 0
                            ? 'From the day you join'
                            : '${rung.months} months · ${rung.visits} visits '
                                'in ${rung.windowDays} days',
                        style: TextStyle(fontSize: 12, color: mute),
                      ),
                    ],
                  ),
                ),
                Text('${rung.discount}%',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: reached ? F4L.orange : mute)),
              ]),
            ),
          );
        }),
        const SizedBox(height: 6),
        Text(
          'A visit is a day you used your card anywhere at the Forge — the '
          'cafeteria counts. Once you reach Forged, it is yours for good.',
          style: TextStyle(fontSize: 12, height: 1.55, color: mute),
        ),
      ],
    );
  }

  // ---------- the ledger ----------
  Widget _activityBlock(BuildContext context, Color? mute) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECENT ACTIVITY',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.7)),
          const SizedBox(height: 10),
          FutureBuilder<List<LedgerEntry>>(
            future: _ledger,
            builder: (context, snap) {
              final rows = snap.data ?? [];

              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // The empty state matters more than the full one — at launch
              // this is what almost everyone sees.
              if (rows.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.85),
                    border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    ForgeIcons.card.tile(size: 38),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'Nothing yet — your first visit starts the count. '
                        'Show your card at the cafeteria and it begins there.',
                        style: TextStyle(
                            fontSize: 13, height: 1.5, color: mute),
                      ),
                    ),
                  ]),
                );
              }

              return Column(
                children: rows
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Container(
                              width: 44,
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: (e.delta >= 0 ? F4L.teal : F4L.orange)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                  '${e.delta >= 0 ? '+' : ''}${e.delta}',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: e.delta >= 0
                                          ? F4L.teal
                                          : F4L.orange)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.label,
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700)),
                                  if (e.at != null)
                                    Text(_ago(e.at!),
                                        style: TextStyle(
                                            fontSize: 11.5, color: mute)),
                                ],
                              ),
                            ),
                            Text('${e.balance}',
                                style: TextStyle(
                                    fontSize: 12.5, color: mute)),
                          ]),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      );

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return 'Just now';
  }
}
