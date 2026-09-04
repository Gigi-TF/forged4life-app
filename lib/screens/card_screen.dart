import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/card_store.dart';
import '../services/card_token.dart';
import '../theme/f4l_theme.dart';
import '../widgets/membership_card.dart';
import 'welcome_screen.dart';

/// The screen the whole app exists for. Works in aeroplane mode.
class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
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

  Future<void> _signOut() async {
    await CardStore.wipe();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _freeze() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Freeze this card?'),
        content: const Text(
            'Nothing will scan until reception unfreezes it. Use this if your '
            'phone is lost or stolen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Freeze')),
        ],
      ),
    );

    if (sure != true) return;

    try {
      await ApiClient().freezeCard();
      if (mounted) await _signOut();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_card == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No card on this device.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: _signOut, child: const Text('Sign in again')),
              ],
            ),
          ),
        ),
      );
    }

    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final type = _member?['member_type'] as String? ?? 'member';
    final isDay = type == 'day';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your card'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => v == 'freeze' ? _freeze() : _signOut(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'freeze', child: Text('Freeze my card')),
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            children: [
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
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
              ),

              const SizedBox(height: 24),
              Text('MEMBER SINCE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: mute)),
              const SizedBox(height: 4),
              Text(_card!['issued_at']?.toString() ?? '—',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
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
