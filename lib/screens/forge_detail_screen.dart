import 'package:flutter/material.dart';

import '../data/forges.dart';
import '../services/interest_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';

/// One cohort school, opened out. Each programme can be ticked; the bar at
/// the bottom sends the selection and the curriculum cards follow by email.
class ForgeDetailScreen extends StatefulWidget {
  const ForgeDetailScreen({super.key, required this.forge});
  final Forge forge;

  @override
  State<ForgeDetailScreen> createState() => _ForgeDetailScreenState();
}

class _ForgeDetailScreenState extends State<ForgeDetailScreen> {
  /// Everything the member has ever ticked, across all five schools.
  Set<String> _saved = {};

  /// What is ticked right now on this screen.
  final Set<String> _picked = {};

  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    InterestApi().mine().then((s) {
      if (!mounted) return;
      setState(() {
        _saved = s;
        // Pre-tick anything from this school they already registered, so the
        // screen reflects what the server knows rather than starting blank.
        _picked.addAll(
          widget.forge.programmes.map((p) => p.slug).where(s.contains),
        );
        _loading = false;
      });
    });
  }

  /// Only the ones that would actually be new — the button should not offer
  /// to send cards they already have.
  Set<String> get _unsent => _picked.difference(_saved);

  Future<void> _send() async {
    setState(() => _sending = true);

    try {
      final result = await InterestApi().save(
        _picked.toList(),
        forge: widget.forge.name,
      );

      if (!mounted) return;
      setState(() {
        _saved = {..._saved, ..._picked};
        _sending = false;
      });

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(result.emailed ? 'On its way' : 'Saved'),
          content: Text(
            result.emailed
                ? '${result.message}.\n\nWe will also tell you first when any '
                    'of these cohorts opens.'
                : '${result.message}\n\nWe will tell you first when any of '
                    'these cohorts opens.',
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(c), child: const Text('Good')),
          ],
        ),
      );
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final accent = widget.forge.spec.$2.colours.last;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 132,
            foregroundColor: Colors.white,
            backgroundColor: accent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(54, 0, 16, 14),
              title: Text(widget.forge.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.forge.spec.$2.colours,
                  ),
                ),
                child: Align(
                  alignment: const Alignment(0.85, -0.15),
                  child: Icon(widget.forge.spec.$1,
                      size: 84, color: Colors.white.withValues(alpha: 0.16)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 18, 20, _picked.isEmpty ? 34 : 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.forge.forWhom,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              color: accent)),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.forge.programmes.length} programme'
                        '${widget.forge.programmes.length == 1 ? '' : 's'} · '
                        'tick the ones you want to hear about',
                        style:
                            TextStyle(fontSize: 13, height: 1.4, color: mute),
                      ),
                      const SizedBox(height: 18),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        for (final p in widget.forge.programmes)
                          _ProgrammeRow(
                            p: p,
                            picked: _picked.contains(p.slug),
                            alreadySent: _saved.contains(p.slug),
                            onToggle: () => setState(() {
                              _picked.contains(p.slug)
                                  ? _picked.remove(p.slug)
                                  : _picked.add(p.slug);
                            }),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (_picked.isEmpty || _loading)
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: F4L.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _sending
                          ? const SizedBox(
                              height: 19,
                              width: 19,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: Colors.white))
                          : Text(
                              _unsent.isEmpty
                                  ? 'Already registered'
                                  : "I'm interested "
                                      '(${_unsent.length})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _unsent.isEmpty
                          ? 'We have already sent the cards for these.'
                          : 'We will email the programme cards and tell you '
                              'first when a cohort opens.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.4, color: mute),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProgrammeRow extends StatelessWidget {
  const _ProgrammeRow({
    required this.p,
    required this.picked,
    required this.alreadySent,
    required this.onToggle,
  });

  final Programme p;
  final bool picked;
  final bool alreadySent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final accent = p.spec.$2.colours.last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // The whole card is the target, not just the checkbox — a 20px tick
        // box is a miserable thing to hit on a phone.
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: picked
                ? accent.withValues(alpha: 0.07)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
            border: Border.all(
              color: picked
                  ? accent
                  : Theme.of(context).dividerColor.withValues(alpha: 0.6),
              width: picked ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              p.spec.tile(size: 40),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.name,
                              style: const TextStyle(
                                  fontSize: 15.5, fontWeight: FontWeight.w800)),
                        ),
                        if (alreadySent)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.mark_email_read_outlined,
                                size: 15, color: mute),
                          ),
                      ],
                    ),
                    if (p.audience != null) ...[
                      const SizedBox(height: 3),
                      Text(p.audience!,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                              color: accent)),
                    ],
                    const SizedBox(height: 5),
                    Text(p.blurb,
                        style:
                            TextStyle(fontSize: 13, height: 1.55, color: mute)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Checkbox is decorative — the card handles the tap. Kept so
              // the state is obvious at a glance.
              IgnorePointer(
                child: Checkbox(
                  value: picked,
                  onChanged: (_) {},
                  activeColor: accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
