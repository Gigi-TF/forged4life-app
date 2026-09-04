import 'package:flutter/material.dart';

import '../theme/f4l_theme.dart';
import 'card_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'programmes_tab.dart';
import 'whatson_tab.dart';

/// The app proper. Five tabs, with the card raised in the centre because it is
/// the thing people open the app to reach.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  // Lets us tell Home to reload when it comes back into view.
  final _homeKey = GlobalKey<HomeTabState>();

  /// Lets a child jump tabs — the Home quick actions use this.
  /// Lets a child jump tabs — the Home quick actions use this.
  void go(int i) {
    setState(() => _index = i);

    // Coming back to Home means the balance may have moved while they were
    // spending sparks somewhere else.
    if (i == 0) _homeKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(key: _homeKey, onJump: go),
      const ProgrammesTab(),
      const CardTab(),
      const WhatsOnTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      extendBody: true,
      // IndexedStack keeps each tab alive, so the card's 60-second timer and
      // any scroll position survive tab switches.
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: _TabBar(index: _index, onTap: go),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        height: 74,
        decoration: BoxDecoration(
          color: (dark ? const Color(0xFF15141F) : Colors.white)
              .withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.4 : 0.10),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _Item(
                icon: Icons.home_outlined,
                filled: Icons.home,
                label: 'Home',
                on: index == 0,
                onTap: () => onTap(0)),
            _Item(
                icon: Icons.school_outlined,
                filled: Icons.school,
                label: 'Learn',
                on: index == 1,
                onTap: () => onTap(1)),
            _CardKnob(on: index == 2, onTap: () => onTap(2)),
            _Item(
                icon: Icons.event_outlined,
                filled: Icons.event,
                label: "What's on",
                on: index == 3,
                onTap: () => onTap(3)),
            _Item(
                icon: Icons.person_outline,
                filled: Icons.person,
                label: 'Profile',
                on: index == 4,
                onTap: () => onTap(4)),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.filled,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final IconData icon;
  final IconData filled;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour =
        on ? F4L.orange : Theme.of(context).textTheme.bodySmall?.color;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(on ? filled : icon, size: 21, color: colour),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.4,
                  color: colour,
                )),
          ],
        ),
      ),
    );
  }
}

/// The raised centre button, as in the design. Bigger target than the others
/// because it is the most-used destination by a wide margin.
class _CardKnob extends StatelessWidget {
  const _CardKnob({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -14),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: F4L.blend,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    BoxShadow(
                      color: F4L.orange.withValues(alpha: on ? 0.55 : 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor ==
                            Colors.transparent
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child:
                    const Icon(Icons.qr_code_2, size: 27, color: Colors.white),
              ),
            ),
          ),
        ),
      );
}
