import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/blog_list_screen.dart';
import '../screens/cafeteria_screen.dart';
import '../screens/my_listings_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/perks_screen.dart';
import '../screens/press_screen.dart';
import '../screens/shelf_screen.dart';
import '../theme/f4l_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/forge_icon.dart';

/// Everything that used to crowd the Home screen.
///
/// Home is now about the card and the sparks; the rest of the Forge lives one
/// tap away behind the menu. Nothing is buried — it is just not competing for
/// attention with the thing people opened the app to see.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final theme = ThemeController.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: F4L.blend,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: mute)),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 22),
            _head('AT THE FORGE', mute),
            _item(context, ForgeIcons.cafeteria, 'The Quench',
                'Order food & drink', const CafeteriaScreen()),
            _item(context, ForgeIcons.press, 'The Press',
                'Printing, photos & the studio', const PressScreen()),
            _item(context, (Icons.menu_book_rounded, ForgeTone.sea), 'The Shelf',
                'Books & learning resources', const ShelfScreen()),
            _item(context, ForgeIcons.perks, 'Partner perks',
                'Discounts beyond the Forge', const PerksScreen()),

            const SizedBox(height: 16),
            _head('MINE', mute),
            _item(context, ForgeIcons.bookings, 'My food orders',
                'The Quench', const OrdersScreen()),
            _item(context, (Icons.inventory_2_rounded, ForgeTone.moss),
                'Books I am selling', 'The Shelf', const MyListingsScreen()),

            const SizedBox(height: 16),
            _head('READ', mute),
            _item(context, ForgeIcons.blog, 'Sparks from the Forge',
                'Stories from the Institute', const BlogListScreen()),
            _link(context, ForgeIcons.programmes,
                'Register interest in a programme', 'skillsforge360.org',
                'https://skillsforge360.org/register-interest'),

            const SizedBox(height: 16),
            _head('SETTINGS', mute),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.5)),
                ),
                child: Row(children: [
                  Icon(dark ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Dark mode',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  Switch(
                    value: dark,
                    activeThumbColor: F4L.orange,
                    onChanged: (_) => theme.toggle(),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 14),
            Center(
              child: Text('Forged 4 Life · SkillsForge360',
                  style: TextStyle(fontSize: 11.5, color: mute)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _head(String text, Color? mute) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 9),
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: mute)),
      );

  Widget _item(BuildContext context, (IconData, ForgeTone) spec, String title,
          String sub, Widget screen) =>
      _row(context, spec, title, sub, () {
        Navigator.pop(context);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      });

  Widget _link(BuildContext context, (IconData, ForgeTone) spec, String title,
          String sub, String url) =>
      _row(context, spec, title, sub, () {
        Navigator.pop(context);
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      });

  Widget _row(BuildContext context, (IconData, ForgeTone) spec, String title,
          String sub, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(children: [
              spec.tile(size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(sub,
                        style: TextStyle(
                            fontSize: 11.5,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );
}
