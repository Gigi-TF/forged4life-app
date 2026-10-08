import 'package:flutter/material.dart';

import '../services/sessions_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import 'session_detail_screen.dart';

/// The launch sessions. Replaces What's on.
///
/// These are the front door: seven free introductory sessions between October
/// and December, fifty places each. A member should be able to see what is
/// coming, take a seat, and show their card at the door — no separate ticket,
/// no form they have already filled in.
class SessionsTab extends StatefulWidget {
  const SessionsTab({super.key});

  @override
  State<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionsTab> {
  late Future<List<LaunchSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = SessionsApi().all();
  }

  Future<void> _reload() async {
    setState(() => _future = SessionsApi().all());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: RefreshIndicator(
            onRefresh: _reload,
            child: FutureBuilder<List<LaunchSession>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snap.data ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  children: [
                    const BlendText('Launch sessions',
                        style: TextStyle(
                            fontSize: 27, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Upcoming introductory sessions so you can experience the '
                      'SkillsForge360 approach first-hand. Fifty places per '
                      'group — registered early birds only.',
                      style:
                          TextStyle(fontSize: 14.5, height: 1.6, color: mute),
                    ),
                    const SizedBox(height: 20),
                    if (snap.hasError)
                      _card(context,
                          child: Column(children: [
                            Icon(Icons.cloud_off, size: 26, color: mute),
                            const SizedBox(height: 10),
                            const Text('Could not load the sessions.',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Pull down to try again.',
                                style: TextStyle(fontSize: 12.5, color: mute)),
                          ]))
                    else if (sessions.isEmpty)
                      _card(context,
                          child: Column(children: [
                            ForgeIcons.whatsOn.tile(size: 42),
                            const SizedBox(height: 12),
                            const Text('Nothing scheduled yet.',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 5),
                            Text(
                              'The launch programme is being finalised. Check '
                              'back shortly.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, height: 1.5, color: mute),
                            ),
                          ]))
                    else
                      ...sessions.map((s) => _SessionCard(
                            session: s,
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) =>
                                        SessionDetailScreen(slug: s.slug)))
                                .then((_) => _reload()),
                          )),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext c, {required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(c).colorScheme.surface.withValues(alpha: 0.88),
          border: Border.all(
              color: Theme.of(c).dividerColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final LaunchSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final past = session.status == 'past';

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Opacity(
        opacity: past ? 0.55 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
              border: Border.all(
                color: session.registered
                    ? F4L.teal.withValues(alpha: 0.6)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.55),
                width: session.registered ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(session.audience.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: mute)),
                  ),
                  _StatusPill(session: session),
                ]),
                const SizedBox(height: 9),
                Text(session.title,
                    style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3)),
                const SizedBox(height: 7),
                Text(session.hook,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, height: 1.5, color: mute)),
                const SizedBox(height: 13),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: mute),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(session.dateLabel,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: mute)),
                  ),
                  if (session.isPaid && session.price != null)
                    Text('\$${session.price!.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: F4L.orange))
                  else
                    const Text('FREE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: F4L.teal)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The state of a session, in one word.
///
/// Worked out on the server and sent as a single value rather than the app
/// deriving it from three flags — "full" and "closed" and "already happened"
/// need different words, and getting that wrong in two places is worse than
/// getting it right in one.
///
/// The colours carry meaning on their own, for someone scanning the list
/// rather than reading it:
///
///   orange  you can act — register, or join the list before it fills
///   teal    you are already in; nothing to do
///   gold    caution — full, or you are only on the waiting list
///   grey    gone; no action exists
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.session});

  final LaunchSession session;

  @override
  Widget build(BuildContext context) {
    final (label, colour) = switch (true) {
      _ when session.isWaitlisted => ('WAITING LIST', const Color(0xFFB07A0E)),
      _ when session.registered => ('REGISTERED', F4L.teal),
      _ when session.status == 'past' => ('PAST', Colors.grey),
      _ when session.status == 'closed' => ('CLOSED', Colors.grey),
      _ when session.status == 'full' => ('FULL', const Color(0xFFB07A0E)),
      _ when session.status == 'nearly_full' => (
          '${session.seatsLeft} LEFT',
          F4L.orange
        ),
      _ => ('OPEN', F4L.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: colour)),
    );
  }
}
