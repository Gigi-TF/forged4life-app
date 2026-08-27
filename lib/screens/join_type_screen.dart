import 'package:flutter/material.dart';

import '../services/signup_draft.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import 'signup_form_screen.dart';

class JoinTypeScreen extends StatelessWidget {
  const JoinTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Step 1 of 2')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const BlendText('How are you joining?',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Pick the one that fits today. You can upgrade a day pass to full '
                'membership later without filling anything in twice.',
                style: TextStyle(fontSize: 15, height: 1.6, color: mute),
              ),
              const SizedBox(height: 18),
              const _TypeTile(
                type: 'day',
                spec: ForgeIcons.dayPass,
                title: 'Day pass',
                blurb: 'Here for one session, meeting or training day. '
                    'Card expires tonight.',
              ),
              const _TypeTile(
                type: 'member',
                spec: ForgeIcons.member,
                title: 'Full membership',
                blurb: 'Programmes, discounts, Sparks and partner perks. '
                    'Free to join.',
              ),
              const _TypeTile(
                type: 'silver',
                spec: ForgeIcons.silver,
                title: 'FORGE Silver',
                blurb:
                    'For retirees and those approaching the end of a career.',
              ),
              const _TypeTile(
                type: 'community',
                spec: ForgeIcons.community,
                title: 'Community',
                blurb: 'Cafeteria, the bookstore and open events. '
                    'No programme needed.',
              ),
              const SizedBox(height: 8),
              Text(
                'Not sure? Start as Community — it takes thirty seconds and '
                'upgrades cleanly.',
                style: TextStyle(fontSize: 13, height: 1.6, color: mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.spec,
    required this.title,
    required this.blurb,
  });

  final String type;

  /// The tile brings its own colour, so the separate `colour` field this
  /// widget used to take is gone.
  final (IconData, ForgeTone) spec;
  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                SignupFormScreen(draft: SignupDraft(memberType: type)),
          )),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                spec.tile(size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(blurb,
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      );
}
