import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart';
import '../services/card_store.dart';
import '../theme/f4l_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/forge_icon.dart';
import 'blog_list_screen.dart';
import 'orders_screen.dart';
import 'welcome_screen.dart';
import 'rewards_screen.dart';
import 'perks_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _member;

  @override
  void initState() {
    super.initState();
    CardStore.readMember().then((m) {
      if (mounted) setState(() => _member = m);
    });
  }

  Future<void> _signOut() async {
    await CardStore.wipe();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _freeze() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Freeze this card?'),
        content: const Text(
            'Nothing will scan until reception unfreezes it. Use this if your '
            'phone is lost or stolen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Freeze')),
        ],
      ),
    );
    if (sure != true) return;

    try {
      await ApiClient().freezeCard();
      if (mounted) await _signOut();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final name = _member?['name'] as String? ?? 'Member';
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: F4L.blend,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(initials,
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        Text(_member?['email'] as String? ?? '',
                            style: TextStyle(fontSize: 13, color: mute)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Appearance is a switch, not a chevron — it toggles rather than
              // navigating, and the state is visible without tapping.
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.85),
                    border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    ForgeIcon(
                      dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      tone: dark ? ForgeTone.slate : ForgeTone.gold,
                      size: 38,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dark mode',
                              style: TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w700)),
                          Text(dark ? 'On' : 'Off',
                              style: TextStyle(fontSize: 12.5, color: mute)),
                        ],
                      ),
                    ),
                    Switch(
                      value: dark,
                      activeThumbColor: F4L.orange,
                      onChanged: (_) => theme.toggle(),
                    ),
                  ]),
                ),
              ),

              _Row(
                spec: ForgeIcons.blog,
                title: 'Sparks from the Forge',
                sub: 'Read the latest blog posts',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BlogListScreen()),
                ),
              ),
              _Row(
                spec: ForgeIcons.bookings,
                title: 'My food orders',
                sub: 'The Quench',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
              ),
              _Row(
                spec: ForgeIcons.whatsOn,
                title: 'Updates & notifications',
                sub: 'Choose what reaches you',
                onTap: () => _soon(context),
              ),
              _Row(
                spec: ForgeIcons.programmes,
                title: 'Register interest in a programme',
                sub: 'skillsforge360.org',
                onTap: () => launchUrl(
                  Uri.parse('https://skillsforge360.org/register-interest'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _Row(
                spec: (Icons.ac_unit_rounded, ForgeTone.teal),
                title: 'Freeze my card',
                sub: 'Lost phone? Stop it scanning anywhere.',
                onTap: _freeze,
              ),
              _Row(
                spec: (Icons.logout_rounded, ForgeTone.slate),
                title: 'Sign out',
                sub: 'You will need a new code to get back in',
                onTap: _signOut,
              ),
              _Row(
                spec: (Icons.workspace_premium_rounded, ForgeTone.gold),
                title: 'Rewards & tier',
                sub: 'What your card is worth',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RewardsScreen()),
                ),
              ),

              _Row(
                spec: ForgeIcons.perks,
                title: 'Partner perks',
                sub: 'Discounts beyond the Forge',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PerksScreen()),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('Forged 4 Life · a product of SkillsForge360',
                    style: TextStyle(fontSize: 12, color: mute)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _soon(BuildContext c) => ScaffoldMessenger.of(c)
      .showSnackBar(const SnackBar(content: Text('Coming before launch.')));
}

class _Row extends StatelessWidget {
  const _Row({
    required this.spec,
    required this.title,
    required this.sub,
    this.onTap,
  });

  final (IconData, ForgeTone) spec;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
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
            child: Row(
              children: [
                spec.tile(size: 38),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                      Text(sub,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 19),
              ],
            ),
          ),
        ),
      );
}
