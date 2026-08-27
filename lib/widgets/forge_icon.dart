import 'package:flutter/material.dart';

/// A tinted glass tile with an icon inside — the app's icon language.
///
/// Built rather than drawn: a widget scales to any size, re-tints with the
/// theme, and adds nothing to the bundle. A folder of PNGs would need three
/// resolutions each and would go stale the moment the palette moved.
///
/// The look is four layers:
///   1. a squircle filled with a two-stop gradient
///   2. a large translucent blob offset to one corner — the "glass"
///   3. a light rim along the top edge, so it reads as a lit surface
///   4. the glyph, with a soft shadow so it sits above the glass
class ForgeIcon extends StatelessWidget {
  const ForgeIcon(
    this.icon, {
    super.key,
    this.tone = ForgeTone.ember,
    this.size = 46,
  });

  final IconData icon;
  final ForgeTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = tone.colours;
    // Squircle: Apple's superellipse is roughly 28% of the side.
    final radius = size * 0.28;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c,
          ),
          boxShadow: [
            // Shadow tinted with the icon's own colour, not black — that is
            // what stops these looking like flat stickers.
            BoxShadow(
              color: c.last.withValues(alpha: 0.38),
              blurRadius: size * 0.30,
              offset: Offset(0, size * 0.14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 2. the glass blob
              Positioned(
                right: -size * 0.22,
                bottom: -size * 0.30,
                child: Container(
                  width: size * 0.90,
                  height: size * 0.90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
              ),

              // a second, smaller highlight top-left keeps it from looking
              // lopsided
              Positioned(
                left: -size * 0.18,
                top: -size * 0.24,
                child: Container(
                  width: size * 0.62,
                  height: size * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. lit top edge
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: size * 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.26),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. the glyph
              Center(
                child: Icon(
                  icon,
                  size: size * 0.50,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: c.last.withValues(alpha: 0.5),
                      blurRadius: size * 0.10,
                      offset: Offset(0, size * 0.03),
                    ),
                  ],
                ),
              ),

              // hairline edge, so tiles separate on a light background
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where an icon sits on the brand gradient.
///
/// Every tone is a two-stop slice of teal → orange, so a screen full of
/// icons reads as one family rather than a bag of colours.
enum ForgeTone {
  teal, // structural, informational
  sea, // secondary
  moss, // the midpoint
  gold, // attention, money
  ember, // primary actions
  slate; // neutral / disabled

  List<Color> get colours => switch (this) {
        ForgeTone.teal => const [Color(0xFF0FA8AC), Color(0xFF02656A)],
        ForgeTone.sea => const [Color(0xFF35B3A0), Color(0xFF068081)],
        ForgeTone.moss => const [Color(0xFF7FB25A), Color(0xFF3E8E63)],
        ForgeTone.gold => const [Color(0xFFF2B33C), Color(0xFFC98A12)],
        ForgeTone.ember => const [Color(0xFFF9913F), Color(0xFFD9560C)],
        ForgeTone.slate => const [Color(0xFF9BAFB2), Color(0xFF64797C)],
      };
}

/// One place that decides which glyph and tone every feature gets.
///
/// Kept central so the cafeteria icon on Home and the cafeteria icon in
/// Profile cannot drift apart — which is exactly what happens when each
/// screen picks its own emoji.
class ForgeIcons {
  // ---- navigation ----
  static const home = (Icons.cottage_rounded, ForgeTone.teal);
  static const programmes = (Icons.school_rounded, ForgeTone.sea);
  static const card = (Icons.qr_code_2_rounded, ForgeTone.ember);
  static const whatsOn = (Icons.calendar_month_rounded, ForgeTone.gold);
  static const profile = (Icons.person_rounded, ForgeTone.slate);

  // ---- features ----
  static const cafeteria = (Icons.restaurant_rounded, ForgeTone.ember);
  static const press = (Icons.print_rounded, ForgeTone.sea);
  static const studio = (Icons.photo_camera_rounded, ForgeTone.moss);
  static const blog = (Icons.auto_stories_rounded, ForgeTone.teal);
  static const perks = (Icons.local_offer_rounded, ForgeTone.gold);
  static const bookings = (Icons.receipt_long_rounded, ForgeTone.slate);
  static const rooms = (Icons.meeting_room_rounded, ForgeTone.teal);

  // ---- perk categories ----
  static const medical = (Icons.medical_services_rounded, ForgeTone.teal);
  static const shopping = (Icons.shopping_bag_rounded, ForgeTone.ember);
  static const rides = (Icons.directions_car_rounded, ForgeTone.sea);
  static const banks = (Icons.account_balance_rounded, ForgeTone.moss);
  static const flights = (Icons.flight_takeoff_rounded, ForgeTone.gold);
  static const gym = (Icons.fitness_center_rounded, ForgeTone.ember);

  // ---- membership types ----
  static const dayPass = (Icons.confirmation_number_rounded, ForgeTone.gold);
  static const member = (Icons.local_fire_department_rounded, ForgeTone.ember);
  static const silver = (Icons.spa_rounded, ForgeTone.moss);
  static const community = (Icons.groups_rounded, ForgeTone.teal);

  // ---- the press ----
  static const documents = (Icons.description_rounded, ForgeTone.sea);
  static const photos = (Icons.image_rounded, ForgeTone.moss);
  static const finishing = (Icons.auto_awesome_rounded, ForgeTone.gold);
  static const scanning = (Icons.document_scanner_rounded, ForgeTone.teal);

  // ---- cafeteria sections ----
  static const breakfast = (Icons.egg_alt_rounded, ForgeTone.gold);
  static const mains = (Icons.dinner_dining_rounded, ForgeTone.ember);
  static const lightBites = (Icons.bakery_dining_rounded, ForgeTone.moss);
  static const drinks = (Icons.local_cafe_rounded, ForgeTone.sea);
}

/// Convenience: `ForgeIcons.cafeteria.tile(size: 52)`
extension ForgeIconSpec on (IconData, ForgeTone) {
  Widget tile({double size = 46}) => ForgeIcon($1, tone: $2, size: size);
}
