import 'package:flutter/material.dart';

import '../services/event_api.dart';
import '../theme/f4l_theme.dart';

/// Tap an event, get the detail and the button. A sheet rather than a screen
/// because registering is one decision — pushing a whole route for it makes
/// the back journey longer than the task.
class EventSheet extends StatefulWidget {
  const EventSheet({super.key, required this.event});
  final F4LEvent event;

  @override
  State<EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<EventSheet> {
  late F4LEvent _e = widget.event;
  int _guests = 0;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    // The list gives us enough to paint immediately; the detail call fills in
    // the description and a fresh seat count.
    EventApi().show(widget.event.id).then((full) {
      if (mounted) setState(() => _e = full);
    }).catchError((_) {});
  }

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      final r = await EventApi().register(_e.id, guests: _guests);
      if (!mounted) return;
      _changed = true;
      final fresh = await EventApi().show(_e.id);
      if (!mounted) return;
      setState(() {
        _e = fresh;
        _busy = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.message)));
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _cancel() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Give up your place?'),
        content: const Text(
            'Someone on the waitlist may want it. You can register again if '
            'there is still room.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep it')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Give it up')),
        ],
      ),
    );
    if (sure != true) return;

    setState(() => _busy = true);
    try {
      await EventApi().cancel(_e.id);
      if (!mounted) return;
      _changed = true;
      final fresh = await EventApi().show(_e.id);
      if (!mounted) return;
      setState(() {
        _e = fresh;
        _busy = false;
      });
    } catch (e) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {},
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: F4L.orange.withValues(alpha: 0.12),
                      border:
                          Border.all(color: F4L.orange.withValues(alpha: 0.35)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(children: [
                      Text(_e.day,
                          style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: F4L.orange)),
                      Text(_e.month.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: mute)),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_e.kind.toUpperCase(),
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: mute)),
                        const SizedBox(height: 3),
                        Text(_e.title,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                height: 1.25)),
                        const SizedBox(height: 3),
                        Text(_e.timeLine,
                            style: TextStyle(fontSize: 13, color: mute)),
                      ],
                    ),
                  ),
                ],
              ),

              if (_e.description != null) ...[
                const SizedBox(height: 16),
                Text(_e.description!,
                    style: TextStyle(fontSize: 14, height: 1.6, color: mute)),
              ],

              const SizedBox(height: 16),
              _statusStrip(context, mute),

              // Guests only make sense before you have committed, and only
              // where there is room to bring anyone.
              if (_e.canRegister && _e.myStatus == null && !_e.isFull) ...[
                const SizedBox(height: 16),
                Row(children: [
                  Text('Bringing anyone?',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: mute)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 21),
                    onPressed:
                        _guests > 0 ? () => setState(() => _guests--) : null,
                  ),
                  Text('$_guests',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        size: 21, color: F4L.orange),
                    onPressed:
                        _guests < 4 ? () => setState(() => _guests++) : null,
                  ),
                ]),
              ],

              const SizedBox(height: 18),
              _button(context),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, _changed),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusStrip(BuildContext context, Color? mute) {
    final (icon, text, colour) = switch (_e) {
      _ when _e.isGoing => (
          Icons.check_circle,
          'You have a place at this one.',
          F4L.teal
        ),
      _ when _e.isWaitlisted => (
          Icons.hourglass_bottom,
          'You are on the waitlist. We will tell you if a place opens.',
          const Color(0xFFB07A0E)
        ),
      _ when !_e.open => (
          Icons.lock_outline,
          'Not open for registration — this one is for a specific cohort.',
          mute ?? F4L.teal
        ),
      _ when _e.hasClosed => (
          Icons.event_busy,
          'Registration has closed.',
          mute ?? F4L.teal
        ),
      _ when _e.isFull => (
          Icons.people_alt,
          'Full — but you can join the waitlist.',
          const Color(0xFFB07A0E)
        ),
      _ when _e.seatsLeft != null && _e.seatsLeft! <= 5 => (
          Icons.local_fire_department,
          'Only ${_e.seatsLeft} place${_e.seatsLeft == 1 ? '' : 's'} left.',
          F4L.orange
        ),
      _ => (
          Icons.event_available,
          _e.seatsLeft == null
              ? 'Open to all members.'
              : '${_e.seatsLeft} places left.',
          F4L.teal
        ),
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.09),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: colour),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: colour)),
        ),
      ]),
    );
  }

  Widget _button(BuildContext context) {
    if (!_e.canRegister && _e.myStatus == null) {
      return const SizedBox.shrink();
    }

    if (_e.myStatus != null) {
      return OutlinedButton(
        onPressed: _busy ? null : _cancel,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(_e.isWaitlisted ? 'Leave the waitlist' : 'Give up my place',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    return FilledButton(
      onPressed: _busy ? null : _register,
      style: FilledButton.styleFrom(
        backgroundColor: F4L.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _busy
          ? const SizedBox(
              height: 19,
              width: 19,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: Colors.white))
          : Text(
              _e.isFull
                  ? 'Join the waitlist'
                  : _guests > 0
                      ? 'Register ${_guests + 1} of us'
                      : 'Register',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
    );
  }
}
