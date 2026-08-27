import 'dart:async';
import 'package:flutter/material.dart';

import '../services/card_store.dart';
import '../services/card_token.dart';
import '../theme/f4l_theme.dart';
import '../widgets/membership_card.dart';
import '../widgets/tier_strip.dart';

/// The card, as a tab. Sign-out and freeze moved to Profile — this screen does
/// one thing.
class CardTab extends StatefulWidget {
  const CardTab({super.key});

  @override
  State<CardTab> createState() => _CardTabState();
}

class _CardTabState extends State<CardTab> {
  Map<String, dynamic>? _card;
  Map<String, dynamic>? _member;
  String? _token;
  int _left = CardToken.period;
  Timer? _timer;
  bool _showQr = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final card = await CardStore.readCard();
    final member = await CardStore.readMember();
    if (!mounted) return;

    setState(() {
      _card = card;
      _member = member;
      _loading = false;
    });

    if (card != null) {
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    if (!mounted || _card == null) return;
    setState(() {
      _token = CardToken.issue(
        uid: _card!['uid'] as String,
        version: _card!['version'] as int,
        secretHex: _card!['secret'] as String,
      );
      _left = CardToken.secondsRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_card == null) {
      return const Center(child: Text('No card on this device.'));
    }

    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final type = _member?['member_type'] as String? ?? 'member';
    final isDay = type == 'day';

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              const BlendText('Your Forge card',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Show this at reception, the cafeteria till, or any partner. '
                'Works offline — the code refreshes every ${CardToken.period} seconds.',
                style: TextStyle(fontSize: 14.5, height: 1.6, color: mute),
              ),
              const SizedBox(height: 18),
              MembershipCard(
                name: _member?['name'] as String? ?? 'Member',
                cardNumber: _card!['number'] as String,
                tier: _tierLabel(type, _member?['tier'] as String?),
                isDayPass: isDay,
                expiresLabel: isDay ? 'UNTIL 23:59' : null,
                showQr: _showQr,
                token: _token,
                secondsLeft: _left,
                onTap: () => setState(() => _showQr = !_showQr),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => setState(() => _showQr = !_showQr),
                style: FilledButton.styleFrom(
                  backgroundColor: F4L.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_showQr ? 'Show card' : 'Show QR',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const TierStrip(),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                      child: _Stat(
                          label: 'Member since',
                          value: _formatDate(_card!['issued_at']))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Stat(
                          label: 'Tier',
                          value:
                              _tierLabel(type, _member?['tier'] as String?))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    final s = raw?.toString();
    if (s == null || s.length < 10) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final m = int.tryParse(s.substring(5, 7)) ?? 1;
    return '${months[m - 1]} ${s.substring(0, 4)}';
  }

  String _tierLabel(String type, String? tier) => switch (type) {
        'day' => 'Day Pass',
        'community' => 'Community',
        'silver' => 'Silver',
        _ => switch (tier) {
            'forged' => 'Forged',
            'tempered' => 'Tempered',
            _ => 'Ember',
          },
      };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}
