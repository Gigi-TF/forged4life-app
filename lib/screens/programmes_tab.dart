import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/forges.dart';
import '../theme/f4l_theme.dart';

import 'forge_detail_screen.dart';

/// The five cohort schools. Each opens into its own card of programmes —
/// the same shape as the website, but one at a time rather than five columns,
/// because five columns on a phone is a scroll nobody finishes.
class ProgrammesTab extends StatelessWidget {
  const ProgrammesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final total = forges.fold(0, (n, f) => n + f.programmes.length);

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              Text('OUR COHORTS & PROGRAMMES',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: mute)),
              const SizedBox(height: 6),
              const BlendText('Our cohorts.\nOne PATHWAY™.',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 10),
              Text(
                'SkillsForge360 is a professional coaching and mentoring '
                'institute opening in October 2026, built around five cohort '
                'schools that guide people through life’s biggest transitions '
                'and professional milestones: from leaving school, to entering '
                'the workforce, to leading, to retiring well.',
                style: TextStyle(fontSize: 14.5, height: 1.62, color: mute),
              ),
              const SizedBox(height: 20),
              for (final forge in forges) _ForgeCard(forge: forge),
              const SizedBox(height: 14),
              Text('THE PATHWAY™',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: mute)),
              const SizedBox(height: 8),
              Text(
                'Seven elements, one transformation. Every one of the $total '
                'programmes runs the PATHWAY through the Transformation Cycle™ '
                '— Identify, Equip, Mentor, Experience, Flourish — and you '
                'leave with a personal Scorecard.',
                style: TextStyle(fontSize: 13, height: 1.6, color: mute),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _P('P', 'urpose'),
                  _P('A', 'wareness'),
                  _P('T', 'argets'),
                  _P('H', 'abits'),
                  _P('W', 'isdom'),
                  _P('A', 'ccountability'),
                  _P('Y', 'ield'),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => launchUrl(
                  Uri.parse('https://skillsforge360.org/register-interest'),
                  mode: LaunchMode.externalApplication,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: F4L.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Register your interest',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const SizedBox(height: 10),
              Text(
                'Tell us which journeys interest you and we will send the '
                'programme cards, dates and fees as cohorts open.',
                style: TextStyle(fontSize: 12.5, height: 1.6, color: mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A school, closed. Header band, who it is for, and the programmes named
/// so the card is useful before you tap it.
class _ForgeCard extends StatelessWidget {
  const _ForgeCard({required this.forge});
  final Forge forge;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final accent = forge.spec.$2.colours.last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ForgeDetailScreen(forge: forge),
        )),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // the coloured band, as on the website
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: forge.spec.$2.colours,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(forge.spec.$1, size: 21, color: Colors.white),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(forge.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${forge.programmes.length}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(forge.forWhom,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            color: accent)),
                    const SizedBox(height: 10),
                    // Naming the programmes here means the closed card still
                    // answers "is this the one I want?".
                    Text(
                      forge.programmes.map((p) => p.name).join(' · '),
                      style:
                          TextStyle(fontSize: 12.5, height: 1.55, color: mute),
                    ),
                    const SizedBox(height: 12),
                    const Row(children: [
                      Text('Explore',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: F4L.orange)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 15, color: F4L.orange),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _P extends StatelessWidget {
  const _P(this.letter, this.rest);
  final String letter;
  final String rest;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(
              text: letter,
              style: const TextStyle(
                  color: F4L.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          TextSpan(
              text: rest,
              style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).textTheme.bodySmall?.color)),
        ])),
      );
}
