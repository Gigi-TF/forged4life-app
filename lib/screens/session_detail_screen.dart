import 'package:flutter/material.dart';

import '../services/sessions_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  LaunchSession? _s;
  MyRegistration? _mine;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await SessionsApi().one(widget.slug);
      if (mounted) {
        setState(() {
          _s = r.session;
          _mine = r.mine;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    setState(() => _busy = true);

    try {
      final r = await SessionsApi().register(widget.slug);
      await _load();

      if (!mounted) return;
      setState(() => _busy = false);

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(r.status == 'waitlisted'
              ? 'You are on the list'
              : 'Your seat is booked'),
          content: Text('${r.message}\n\nReference ${r.reference}'),
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
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _cancel() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Give up your seat?'),
        content: const Text(
            'It goes back to the group, and these fill up. You can register '
            'again if places are still open.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep it')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              style: FilledButton.styleFrom(backgroundColor: F4L.orange),
              child: const Text('Cancel my seat')),
        ],
      ),
    );
    if (sure != true) return;

    setState(() => _busy = true);
    try {
      final msg = await SessionsApi().cancel(widget.slug);
      await _load();
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final s = _s;

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : s == null
              ? Center(
                  child: Text('Could not load that session.',
                      style: TextStyle(color: mute)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      children: [
                        Text(s.audience.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.7,
                                color: mute)),
                        const SizedBox(height: 9),
                        BlendText(s.title,
                            style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                height: 1.25)),
                        const SizedBox(height: 12),
                        Text(s.hook,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.55,
                                fontStyle: FontStyle.italic)),

                        const SizedBox(height: 22),
                        _facts(context, s, mute),

                        if (_mine != null) ...[
                          const SizedBox(height: 16),
                          _yourSeat(context, mute),
                        ],

                        if (s.forWhom != null) ...[
                          const SizedBox(height: 24),
                          _heading("WHO IT'S FOR", mute),
                          const SizedBox(height: 8),
                          Text(s.forWhom!,
                              style: TextStyle(
                                  fontSize: 14.5, height: 1.6, color: mute)),
                        ],

                        if (s.explore.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _heading("WHAT YOU'LL EXPLORE", mute),
                          const SizedBox(height: 10),
                          ...s.explore.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 6),
                                        child: Icon(Icons.circle,
                                            size: 6, color: F4L.orange),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Text(e,
                                            style: TextStyle(
                                                fontSize: 14.5,
                                                height: 1.55,
                                                color: mute)),
                                      ),
                                    ]),
                              )),
                        ],

                        if (s.footnote != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: F4L.teal.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text(s.footnote!,
                                style: TextStyle(
                                    fontSize: 13, height: 1.55, color: mute)),
                          ),
                        ],

                        const SizedBox(height: 26),
                        _action(context, s),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _heading(String t, Color? mute) => Text(t,
      style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.7,
          color: mute));

  Widget _facts(BuildContext c, LaunchSession s, Color? mute) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(c).colorScheme.surface.withValues(alpha: 0.88),
          border:
              Border.all(color: Theme.of(c).dividerColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          _fact(Icons.calendar_today_outlined, 'Date', s.dateLabel, mute),
          const SizedBox(height: 12),
          _fact(Icons.schedule, 'Time', s.timeLabel, mute),
          const SizedBox(height: 12),
          _fact(Icons.place_outlined, 'Venue', s.venue, mute),
          const SizedBox(height: 12),
          _fact(
              Icons.confirmation_number_outlined,
              'Cost',
              s.isPaid && s.price != null
                  ? '\$${s.price!.toStringAsFixed(0)} per session'
                  : 'Free first session',
              mute),
        ]),
      );

  Widget _fact(IconData i, String k, String v, Color? mute) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, size: 17, color: mute),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(k,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mute)),
          ),
          Expanded(
            child: Text(v,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      );

  Widget _yourSeat(BuildContext c, Color? mute) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: F4L.teal.withValues(alpha: 0.09),
          border: Border.all(color: F4L.teal.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const ForgeIcon(Icons.confirmation_number_rounded,
              tone: ForgeTone.teal, size: 40),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_mine!.label,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Reference ${_mine!.reference}',
                    style: TextStyle(fontSize: 12.5, color: mute)),
                const SizedBox(height: 4),
                // The point of the whole feature: no separate ticket.
                Text('Show your Forged 4 Life card at the door.',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.4, color: mute)),
              ],
            ),
          ),
        ]),
      );

  Widget _action(BuildContext c, LaunchSession s) {
    if (_busy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_mine != null && _mine!.status != 'cancelled') {
      return OutlinedButton(
        onPressed: _cancel,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        child: const Text('Cancel my seat',
            style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    // Each unavailable state says why. A greyed button that just says
    // "Register" tells someone nothing about whether to come back.
    final (label, enabled) = switch (s.status) {
      'past' => ('This session has run', false),
      'closed' => ('Registration has closed', false),
      'full' => ('Full — join the waiting list', true),
      _ => (s.isPaid ? 'Register my interest' : 'Take my free seat', true),
    };

    return FilledButton(
      onPressed: enabled ? _register : null,
      style: FilledButton.styleFrom(
        backgroundColor: F4L.orange,
        disabledBackgroundColor:
            Theme.of(c).dividerColor.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
    );
  }
}
