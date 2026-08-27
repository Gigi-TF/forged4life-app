import 'package:flutter/material.dart';

import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';

/// The partner network. Its own screen rather than a tab inside What's on —
/// an event and a discount are not two views of the same thing, and burying
/// perks behind a segmented control meant tapping "Partner perks" landed you
/// on a list of seminars.
class PerksScreen extends StatelessWidget {
  const PerksScreen({super.key});

  static const _categories = [
    (ForgeIcons.medical, 'Medical', 'Clinics, dental, optical, pharmacy'),
    (ForgeIcons.shopping, 'Shopping', 'Retail, groceries, books'),
    (ForgeIcons.rides, 'Rides', 'Taxis, car hire, servicing, fuel'),
    (ForgeIcons.banks, 'Banks', 'Accounts, cards, financial services'),
    (ForgeIcons.flights, 'Flights', 'Airlines, travel agents, bookings'),
    (ForgeIcons.gym, 'Gym', 'Fitness, wellness, sports clubs'),
  ];

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Partner perks')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const BlendText('Your card works\nbeyond the Forge.',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 10),
              Text(
                'Show your QR at the till. The partner scans it, the discount '
                'comes off, and your visit counts toward your next tier.',
                style: TextStyle(fontSize: 14.5, height: 1.6, color: mute),
              ),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.06,
                children: _categories
                    .map((c) => _CategoryCard(
                          spec: c.$1,
                          title: c.$2,
                          blurb: c.$3,
                        ))
                    .toList(),
              ),

              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.9),
                  border: Border.all(color: F4L.orange.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      ForgeIcons.community.tile(size: 38),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Know a business that belongs here?',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'Members bringing in the gym they use or the dentist '
                      'they trust is how this network actually fills up.',
                      style:
                          TextStyle(fontSize: 13, height: 1.5, color: mute),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                              content: Text(
                                  'Thanks — tell reception and we will approach them.'))),
                      style: FilledButton.styleFrom(
                        backgroundColor: F4L.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Suggest a partner',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Partners are being finalised ahead of the October launch. '
                'Each category will fill with named businesses and their '
                'member rate.',
                style: TextStyle(fontSize: 12.5, height: 1.6, color: mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.spec,
    required this.title,
    required this.blurb,
  });

  final (IconData, ForgeTone) spec;
  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            spec.tile(size: 40),
            const SizedBox(height: 10),
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text(blurb,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
            const Spacer(),
            const Text('COMING SOON',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: F4L.orange)),
          ],
        ),
      );
}
