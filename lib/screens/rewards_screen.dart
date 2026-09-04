import 'package:flutter/material.dart';

import '../services/loyalty_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import 'my_codes_screen.dart';

/// The store. Sparks in, a code out.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<Reward> _rewards = [];
  Tier? _tier;
  int _points = 0;
  bool _loading = true;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await LoyaltyApi().store();
      if (mounted) setState(() {
        _rewards = r.rewards;
        _points = r.points;
        _tier = r.tier;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _redeem(Reward r) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(r.title),
        content: Text('This spends ${r.cost} sparks. You get a code to show '
            'at reception — it does not expire.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Not yet')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              style: FilledButton.styleFrom(backgroundColor: F4L.orange),
              child: const Text('Redeem')),
        ],
      ),
    );
    if (sure != true) return;

    setState(() => _busyId = r.id);

    try {
      final result = await LoyaltyApi().redeem(r.id);
      await _load();
      if (!mounted) return;
      setState(() => _busyId = null);

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Redeemed'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(result.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                gradient: F4L.blend,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(result.code,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Colors.white)),
            ),
            const SizedBox(height: 14),
            Text('Show this at reception. It is saved under My codes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(c).textTheme.bodySmall?.color)),
          ]),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(c),
                style: FilledButton.styleFrom(backgroundColor: F4L.orange),
                child: const Text('Got it')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busyId = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        actions: [
          IconButton(
            tooltip: 'My codes',
            icon: const Icon(Icons.confirmation_number_outlined, size: 21),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MyCodesScreen()))
                .then((_) => _load()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
                    children: [
                      _balanceCard(mute),
                      const SizedBox(height: 20),
                      if (_rewards.isEmpty)
                        _empty(mute)
                      else
                        ..._rewards.map((r) => _RewardCard(
                              reward: r,
                              points: _points,
                              tierRank: _tier?.rank ?? 1,
                              busy: _busyId == r.id,
                              onRedeem: () => _redeem(r),
                            )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _balanceCard(Color? mute) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: F4L.blend,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: F4L.orange.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('YOUR SPARKS',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: Colors.white)),
              const Spacer(),
              if (_tier != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(_tier!.label.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
            ]),
            const SizedBox(height: 12),
            Text('$_points',
                style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text(
                _tier == null
                    ? 'Spend them below.'
                    : 'Plus ${_tier!.discount}% off everywhere, automatically.',
                style: const TextStyle(
                    fontSize: 13.5, height: 1.5, color: Color(0xF0FFFFFF))),
          ],
        ),
      );

  Widget _empty(Color? mute) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: [
          ForgeIcons.perks.tile(size: 46),
          const SizedBox(height: 14),
          const Text('The store opens with the Forge.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Keep earning — every spark you collect now is one you can spend '
            'in October.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.55, color: mute),
          ),
        ]),
      );
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.points,
    required this.tierRank,
    required this.busy,
    required this.onRedeem,
  });

  final Reward reward;
  final int points;
  final int tierRank;
  final bool busy;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final short = reward.cost - points;
    final tierLocked = tierRank < reward.minTierRank;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ForgeIcon(Icons.confirmation_number_rounded,
                  tone: tierLocked ? ForgeTone.slate : ForgeTone.gold,
                  size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.title,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w800)),
                    Text(reward.category,
                        style: TextStyle(fontSize: 12.5, color: mute)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${reward.cost}',
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                  Text('SPARKS',
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: mute)),
                ],
              ),
            ]),

            const SizedBox(height: 12),
            Text(reward.description,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: mute)),

            const SizedBox(height: 12),
            Row(children: [
              _chip(context, reward.valueLabel, F4L.teal),
              const SizedBox(width: 8),
              _chip(context, '${reward.minTierLabel}+', mute ?? F4L.teal),
            ]),

            const SizedBox(height: 14),
            if (busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                      height: 19,
                      width: 19,
                      child: CircularProgressIndicator(strokeWidth: 2.3)),
                ),
              )
            // The label carries the reason. A greyed button saying "Redeem"
            // tells you nothing about what to do next.
            else if (tierLocked)
              _locked(context, 'Unlock at ${reward.minTierLabel}',
                  Icons.lock_outline)
            else if (short > 0)
              _locked(context, '$short more sparks needed', null)
            else
              FilledButton(
                onPressed: onRedeem,
                style: FilledButton.styleFrom(
                  backgroundColor: F4L.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Redeem now',
                    style: TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext c, String label, Color colour) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: colour)),
      );

  Widget _locked(BuildContext c, String label, IconData? icon) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(c).dividerColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15, color: Theme.of(c).textTheme.bodySmall?.color),
              const SizedBox(width: 7),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(c).textTheme.bodySmall?.color)),
          ],
        ),
      );
}
