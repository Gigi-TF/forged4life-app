import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import 'book_offer_screen.dart';

/// Books, the three ways in — matching the website.
///
/// Buy, sell, donate. The second and third are invisible if you only build a
/// shop: nobody browsing a bookshelf thinks to look for a "sell us yours"
/// button, and the stock only exists because someone supplies it.
class BooksEntry extends StatelessWidget {
  const BooksEntry({super.key});

  /// The store is `products` on the website, already built. This link starts
  /// working the day STORE_LIVE is flipped, with nothing to change here.
  static const _storeUrl = 'https://skillsforge360.org/store';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Books')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                children: [
                  const BlendText('Books & learning resources',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.25)),
                  const SizedBox(height: 24),

                  _Option(
                    spec: (Icons.menu_book_rounded, ForgeTone.sea),
                    title: 'Buy books',
                    body: 'Titles from the Forge faculty on purpose, money, '
                        'leadership and transition, plus the PATHWAY™ '
                        'framework in print. Digital and paperback.',
                    action: 'Browse the shelf',
                    onTap: () => launchUrl(Uri.parse(_storeUrl),
                        mode: LaunchMode.externalApplication),
                  ),

                  _Option(
                    spec: (Icons.sell_rounded, ForgeTone.gold),
                    title: 'Sell your books',
                    body: 'Offer your pre-loved titles to the Institute. Tell '
                        'us what you have and we will come back with what we '
                        'can offer and how collection works.',
                    action: 'Make an offer',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            const BookOfferScreen(donating: false))),
                  ),

                  _Option(
                    spec: (Icons.favorite_rounded, ForgeTone.ember),
                    title: 'Donate books',
                    body: 'Give your books a second life. Donations go to the '
                        'Forge shelf and to community reading programmes, '
                        'reaching readers who need them most.',
                    action: 'Donate books',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            const BookOfferScreen(donating: true))),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.spec,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final (IconData, ForgeTone) spec;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              spec.tile(size: 44),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(body,
                  style:
                      TextStyle(fontSize: 13.5, height: 1.55, color: mute)),
              const SizedBox(height: 14),
              Row(children: [
                Text(action,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: F4L.orange)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 16, color: F4L.orange),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
