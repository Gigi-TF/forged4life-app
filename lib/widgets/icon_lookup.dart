import 'package:flutter/material.dart';
import 'forge_icon.dart';

/// Maps database rows to icon specs.
///
/// The cafeteria menu and the print catalogue come from the server, so their
/// items cannot carry a Dart icon. Rather than adding an icon column and
/// asking staff to pick one, we match on the name — a lookup that improves
/// when the real menu lands, without a migration.
class IconFor {
  /// A menu item. Specific matches beat general ones, then it falls back to
  /// the section, then to a plate.
  static (IconData, ForgeTone) food(String name, String section) {
    final n = name.toLowerCase();

    if (_has(n, ['tea', 'coffee', 'cappuccino', 'espresso'])) {
      return (Icons.local_cafe_rounded, ForgeTone.sea);
    }
    if (_has(n, ['water', 'juice', 'mazoe', 'cooler', 'soda'])) {
      return (Icons.local_drink_rounded, ForgeTone.teal);
    }
    if (_has(n, ['sadza', 'stew', 'curry', 'rice'])) {
      return (Icons.rice_bowl_rounded, ForgeTone.ember);
    }
    if (_has(n, ['chicken', 'beef', 'meat', 'nyama', 'grill'])) {
      return (Icons.set_meal_rounded, ForgeTone.ember);
    }
    if (_has(n, ['wrap', 'sandwich', 'toast', 'burger'])) {
      return (Icons.lunch_dining_rounded, ForgeTone.moss);
    }
    if (_has(n, ['samoosa', 'pie', 'scone', 'pastry'])) {
      return (Icons.bakery_dining_rounded, ForgeTone.gold);
    }
    if (_has(n, ['egg', 'breakfast', 'boerewors'])) {
      return (Icons.egg_alt_rounded, ForgeTone.gold);
    }
    if (_has(n, ['fruit', 'yoghurt', 'salad', 'granola', 'vegetable'])) {
      return (Icons.eco_rounded, ForgeTone.moss);
    }

    return foodSection(section);
  }

  static (IconData, ForgeTone) foodSection(String section) {
    final s = section.toLowerCase();
    if (s.contains('breakfast')) return ForgeIcons.breakfast;
    if (s.contains('drink')) return ForgeIcons.drinks;
    if (s.contains('light') || s.contains('bite')) return ForgeIcons.lightBites;
    if (s.contains('main')) return ForgeIcons.mains;
    return ForgeIcons.cafeteria;
  }

  /// A print service, matched on name then category.
  static (IconData, ForgeTone) press(String name, String category) {
    final n = name.toLowerCase();

    if (_has(n, ['passport', 'visa', 'id photo', 'licence', 'portrait'])) {
      return ForgeIcons.studio;
    }
    if (_has(n, ['bind'])) return (Icons.menu_book_rounded, ForgeTone.gold);
    if (_has(n, ['laminat'])) return (Icons.layers_rounded, ForgeTone.gold);
    if (_has(n, ['scan'])) return ForgeIcons.scanning;
    if (_has(n, ['plan', 'drawing'])) {
      return (Icons.architecture_rounded, ForgeTone.teal);
    }
    if (_has(n, ['photo print', 'large format'])) return ForgeIcons.photos;
    if (_has(n, ['colour', 'color'])) {
      return (Icons.palette_rounded, ForgeTone.ember);
    }
    if (_has(n, ['copy', 'photocop'])) {
      return (Icons.content_copy_rounded, ForgeTone.sea);
    }
    if (_has(n, ['black', 'b&w', 'print'])) {
      return (Icons.print_rounded, ForgeTone.sea);
    }

    return pressCategory(category);
  }

  static (IconData, ForgeTone) pressCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('photo')) return ForgeIcons.photos;
    if (c.contains('finish')) return ForgeIcons.finishing;
    if (c.contains('studio')) return ForgeIcons.studio;
    return ForgeIcons.documents;
  }

  static bool _has(String s, List<String> needles) =>
      needles.any(s.contains);
}
