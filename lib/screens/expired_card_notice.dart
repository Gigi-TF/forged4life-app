import 'package:flutter/material.dart';

import '../services/card_store.dart';
import '../services/upgrade_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';

/// What a day visitor sees the morning after.
///
/// Not an error, and not a wall. Their pass did what it was for; the question
/// now is whether they want to stay. Membership is free, they already have
/// the account and the sparks, so the honest answer is "yes, obviously" — and
/// the screen should make that one tap rather than a form.
class ExpiredCardNotice extends StatefulWidget {
  const ExpiredCardNotice({super.key, required this.onUpgraded});

  /// Called after a successful upgrade so the card screen can reload.
  final Future<void> Function() onUpgraded;

  @override
  State<ExpiredCardNotice> createState() => _ExpiredCardNoticeState();
}

class _ExpiredCardNoticeState extends State<ExpiredCardNotice> {
  bool _busy = false;
  int? _sparks;

  @override
  void initState() {
    super.initState();
    CardStore.readMember().then((m) {
      if (mounted) setState(() => _sparks = (m?['sparks'] as num?)?.toInt());
    });
  }

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
          content: Text('$msg\n\nYour card no longer expires, and your '
              'discount applies everywhere from now on.'),
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            Center(child: ForgeIcons.dayPass.tile(size: 62)),
            const SizedBox(height: 20),

            const BlendText('Your day pass has ended.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 25, fontWeight: FontWeight.w800, height: 1.25)),
            const SizedBox(height: 10),
            Text(
              'It did what it was for. Your account is still here — and so is '
              'everything you earned.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.6, color: mute),
            ),

            const SizedBox(height: 26),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  F4L.teal.withValues(alpha: 0.09),
                  F4L.orange.withValues(alpha: 0.07),
                ]),
                border: Border.all(color: F4L.teal.withValues(alpha: 0.32)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Become a member — free',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),

                  _point(context, 'A card that never expires', mute),
                  _point(context, 'Your discount at the café, the bookstore '
                      'and every partner', mute),
                  _point(
                      context,
                      _sparks == null
                          ? 'Your sparks come with you'
                          : 'Your ${_sparks!} sparks come with you',
                      mute),
                  _point(context, 'Nothing to fill in — you already have an '
                      'account', mute),

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

            const SizedBox(height: 18),
            Text(
              'Coming in for another single day instead? Reception can issue a '
              'new pass at the desk.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, height: 1.6, color: mute),
            ),
          ],
        ),
      ),
    );
  }

  Widget _point(BuildContext c, String text, Color? mute) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 16, color: F4L.teal),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: mute)),
          ),
        ]),
      );
}
