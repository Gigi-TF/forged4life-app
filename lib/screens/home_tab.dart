import 'package:flutter/material.dart';

import '../services/card_store.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import 'blog_list_screen.dart';
import 'cafeteria_screen.dart';
import 'press_screen.dart';
import 'rewards_screen.dart';
import 'perks_screen.dart';
import 'shelf_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onJump});
  final ValueChanged<int> onJump;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? _member;

  @override
  void initState() {
    super.initState();
    CardStore.readMember().then((m) {
      if (mounted) setState(() => _member = m);
    });
  }

  String get _firstName {
    final n = (_member?['name'] as String?)?.trim() ?? '';
    return n.isEmpty ? 'there' : n.split(' ').first;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              Text(_dateLine().toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: mute)),
              const SizedBox(height: 6),
              BlendText('$_greeting, $_firstName.',
                  style: const TextStyle(
                      fontSize: 27, fontWeight: FontWeight.w800)),
              const SizedBox(height: 22),
              const _Section(title: 'Quick actions'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                // Lower than before: a 42px tile is taller than a line of emoji.
                childAspectRatio: 1.32,
                children: [
                  _Action(
                      spec: ForgeIcons.card,
                      title: 'My card',
                      sub: 'Show the QR',
                      onTap: () => widget.onJump(2)),
                  _Action(
                      spec: ForgeIcons.programmes,
                      title: 'Programmes',
                      sub: 'Five forges',
                      onTap: () => widget.onJump(1)),
                  _Action(
                      spec: ForgeIcons.whatsOn,
                      title: "What's on",
                      sub: 'Events & cohorts',
                      onTap: () => widget.onJump(3)),
                  _Action(
                    spec: ForgeIcons.perks,
                    title: 'Loyalty programme',
                    sub: 'Forge for Life',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PerksScreen()),
                    ),
                  ),
                  _Action(
                    spec: ForgeIcons.cafeteria,
                    title: 'The Quench',
                    sub: 'Order food',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CafeteriaScreen()),
                    ),
                  ),
                  _Action(
                    spec: ForgeIcons.press,
                    title: 'The Press',
                    sub: 'Print & photos',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PressScreen()),
                    ),
                  ),
                  _Action(
                    spec: (Icons.workspace_premium_rounded, ForgeTone.gold),
                    title: 'My rewards',
                    sub: 'Tier & discount',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RewardsScreen()),
                    ),
                  ),
                  _Action(
                    spec: ForgeIcons.blog,
                    title: 'The Shelf',
                    sub: 'Books & resources',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShelfScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _Section(title: 'Next up'),
              _Card(
                child: Row(
                  children: [
                    ForgeIcons.bookings.tile(size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nothing booked yet',
                              style: TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Browse the programmes to find your first one.',
                              style: TextStyle(fontSize: 12.5, color: mute)),
                        ],
                      ),
                    ),
                    TextButton(
                        onPressed: () => widget.onJump(1),
                        child: const Text('Browse')),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _Section(title: 'Sparks from the Forge'),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const BlogListScreen(),
                )),
                child: _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ForgeIcons.blog.tile(size: 34),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text('ATHLETE & CREATIVE TRANSITION',
                                style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                    color: mute)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      const Text('The Boots by the Door',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'For eleven years Tanaka knew exactly who he was. Then his '
                        'knee gave out in an ordinary training session.',
                        style:
                            TextStyle(fontSize: 13, height: 1.55, color: mute),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLine() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[DateTime.now().weekday - 1]} · Harare';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.spec,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  /// (glyph, tone) — always from ForgeIcons, so the same feature keeps the
  /// same icon wherever it appears.
  final (IconData, ForgeTone) spec;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              spec.tile(size: 42),
              const SizedBox(height: 9),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800)),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ),
      );
}
