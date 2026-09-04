import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/card_store.dart';
import '../services/card_token.dart';
import '../services/pass_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/day_pass.dart';
import '../widgets/membership_card.dart';
import 'expired_card_notice.dart';

/// The card — or, for a day visitor, the pass.
///
/// They are different objects and should look different. A wallet card
/// implies permanence a day pass does not have, and the ticket carries the
/// reference that reception actually looks up.
class CardTab extends StatefulWidget {
  const CardTab({super.key});

  @override
  State<CardTab> createState() => _CardTabState();
}

class _CardTabState extends State<CardTab> {
  Map<String, dynamic>? _card;
  Map<String, dynamic>? _member;
  MyPass? _pass;
  String? _token;
  int _left = CardToken.period;
  Timer? _timer;
  bool _showQr = false;
  bool _loading = true;

  bool get _isDay => (_member?['member_type'] as String?) == 'day';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final card = await CardStore.readCard();
    final member = await CardStore.readMember();

    // Only fetched for a day visitor — a member has no visit to show, and
    // the call would come back null every time.
    final pass = (member?['member_type'] as String?) == 'day'
        ? await PassApi().mine()
        : null;

    if (!mounted) return;

    setState(() {
      _card = card;
      _member = member;
      _pass = pass;
      _loading = false;
    });

    _timer?.cancel();

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

  /// The card carries the expiry, so this is the only thing that decides it.
  bool get _expired {
    final raw = _card?['expires_at'];
    if (raw == null) return false;
    final at = DateTime.tryParse(raw.toString());
    return at != null && at.isBefore(DateTime.now());
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
    if (_expired) {
      return ExpiredCardNotice(onUpgraded: _load);
    }

    return _isDay ? _dayView(context) : _memberView(context);
  }

  // --------------------------------------------------------- day pass

  Widget _dayView(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final pass = _pass;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                const BlendText('Your day pass',
                    style:
                        TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Show this at reception when you arrive. The code refreshes '
                  'every ${CardToken.period} seconds and works offline.',
                  style: TextStyle(fontSize: 14.5, height: 1.6, color: mute),
                ),
                const SizedBox(height: 18),

                DayPass(
                  reference: pass?.reference ?? '—',
                  name: _member?['name'] as String? ?? 'Visitor',
                  date: pass?.dateLabel ?? 'Today',
                  validUntil: pass?.untilLabel ?? '23:59 tonight',
                  token: _token,
                  room: pass?.room,
                  purpose: pass?.purpose,
                  company: pass?.company ?? _member?['company'] as String?,
                  vehicleReg: pass?.vehicle,
                ),

                const SizedBox(height: 16),

                if (pass != null && pass.url.isNotEmpty) ...[
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: pass.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied.')),
                          );
                        },
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('Copy link'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // The same page that was emailed. Useful when the phone
                      // in hand is not the one the pass was sent to.
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(pass.url),
                            mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open online'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                ],

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB07A0E).withValues(alpha: 0.10),
                    border: Border.all(
                        color: const Color(0xFFB07A0E).withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    const Icon(Icons.schedule, size: 19, color: Color(0xFFB07A0E)),
                    const SizedBox(width: 11),
                    Expanded(
                      // Corrected: day passes earn no sparks, so promising
                      // that they carry over was simply wrong.
                      child: Text(
                        'This pass ends tonight. Membership is free, never '
                        'expires, and starts you earning sparks from day one.',
                        style: TextStyle(
                            fontSize: 12.5, height: 1.5, color: mute),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 14),
                Text(
                  'No phone with you? Reception can find you by your '
                  'reference.',
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: mute),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------- member

  Widget _memberView(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final type = _member?['member_type'] as String? ?? 'member';

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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = int.tryParse(s.substring(5, 7)) ?? 1;
    return '${months[m - 1]} ${s.substring(0, 4)}';
  }

  /// Fallbacks only — the label normally comes from the server. Kept in step
  /// with Member::TIER_LABELS.
  String _tierLabel(String type, String? tier) => switch (type) {
        'community' => 'Community',
        'silver' => 'Silver',
        _ => switch (tier) {
            'forge' => 'Forge',
            'blaze' => 'Blaze',
            'flame' => 'Flame',
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
