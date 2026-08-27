import 'package:flutter/material.dart';

import '../services/event_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import 'event_sheet.dart';
import 'perks_screen.dart';

/// Events, live from the server. Perks moved to their own screen — this tab
/// is called What's on, so it should be things that are on.
class WhatsOnTab extends StatefulWidget {
  const WhatsOnTab({super.key});

  @override
  State<WhatsOnTab> createState() => _WhatsOnTabState();
}

class _WhatsOnTabState extends State<WhatsOnTab> {
  late Future<List<F4LEvent>> _events;

  @override
  void initState() {
    super.initState();
    _events = EventApi().upcoming();
  }

  void _reload() => setState(() => _events = EventApi().upcoming());

  Future<void> _open(F4LEvent e) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventSheet(event: e),
    );
    // Only refetch if something changed — reloading every time someone peeks
    // at an event means a flicker for nothing.
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _events;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                const BlendText("What's on",
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Seminars, clinics, open days and cohort sessions — '
                  'everything coming up at the Forge.',
                  style: TextStyle(fontSize: 14.5, height: 1.6, color: mute),
                ),
                const SizedBox(height: 18),

                _eventList(context, mute),

                const SizedBox(height: 22),
                // Perks still reachable from here, but as a signpost rather
                // than half of a segmented control.
                _PerksLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventList(BuildContext context, Color? mute) {
    return FutureBuilder<List<F4LEvent>>(
      future: _events,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(children: [
              Icon(Icons.cloud_off, size: 30, color: mute),
              const SizedBox(height: 10),
              Text('Could not load events. Pull down to try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: mute)),
            ]),
          );
        }

        final events = snap.data ?? [];
        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text('Nothing scheduled yet. Check back soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: mute)),
          );
        }

        return Column(
          children: events
              .map((e) => _EventRow(e: e, onTap: () => _open(e)))
              .toList(),
        );
      },
    );
  }
}

class _PerksLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PerksScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          ForgeIcons.perks.tile(size: 38),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Partner perks',
                    style:
                        TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                Text('Six categories · discounts beyond the Forge',
                    style: TextStyle(fontSize: 12.5, color: mute)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 19, color: mute),
        ]),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.e, required this.onTap});
  final F4LEvent e;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            border: Border.all(
              color: e.myStatus != null
                  ? F4L.teal.withValues(alpha: 0.55)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: e.myStatus != null ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: F4L.orange.withValues(alpha: 0.12),
                  border: Border.all(color: F4L.orange.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(children: [
                  Text(e.day,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: F4L.orange)),
                  Text(e.month.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: mute)),
                ]),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.kind.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: mute)),
                    const SizedBox(height: 3),
                    Text(e.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(e.timeLine,
                        style: TextStyle(fontSize: 12.5, color: mute)),
                    const SizedBox(height: 6),
                    _tag(context),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 19, color: mute),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context) {
    final (label, colour) = switch (e) {
      _ when e.isGoing => ('YOU’RE GOING', F4L.teal),
      _ when e.isWaitlisted => ('WAITLISTED', const Color(0xFFB07A0E)),
      _ when !e.open => ('BY COHORT', Theme.of(context).dividerColor),
      _ when e.hasClosed => ('CLOSED', Theme.of(context).dividerColor),
      _ when e.isFull => ('FULL · WAITLIST', const Color(0xFFB07A0E)),
      _ when e.seatsLeft != null && e.seatsLeft! <= 5 => (
          '${e.seatsLeft} PLACES LEFT',
          F4L.orange
        ),
      _ => ('OPEN — TAP TO REGISTER', F4L.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: colour)),
    );
  }
}
