import 'package:flutter/material.dart';

import '../services/cafeteria_api.dart';
import '../services/prices.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import '../widgets/icon_lookup.dart';
import 'checkout_sheet.dart';
import 'orders_screen.dart';

/// The Quench. Browse, add to a basket, then choose how you want it —
/// eat in, collect, or delivered.
class CafeteriaScreen extends StatefulWidget {
  const CafeteriaScreen({super.key});

  @override
  State<CafeteriaScreen> createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends State<CafeteriaScreen> {
  late Future<Menu> _future;

  /// itemId -> quantity. Held here rather than in a store because a basket
  /// that survives closing the screen is a basket people order by accident.
  final Map<int, int> _basket = {};
  final Map<int, MenuItem> _byId = {};

  @override
  void initState() {
    super.initState();
    _future = CafeteriaApi().menu();
  }

  double get _subtotal => _basket.entries
      .fold(0.0, (sum, e) => sum + (_byId[e.key]?.price ?? 0) * e.value);

  int get _count => _basket.values.fold(0, (a, b) => a + b);

  void _add(MenuItem item) {
    setState(() {
      _byId[item.id] = item;
      _basket[item.id] = (_basket[item.id] ?? 0) + 1;
    });
  }

  void _remove(MenuItem item) {
    setState(() {
      final n = (_basket[item.id] ?? 0) - 1;
      if (n <= 0) {
        _basket.remove(item.id);
      } else {
        _basket[item.id] = n;
      }
    });
  }

  Future<void> _checkout(Menu menu) async {
    final placed = await showModalBottomSheet<FoodOrder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckoutSheet(
        basket: Map.of(_basket),
        items: Map.of(_byId),
        subtotal: _subtotal,
        deliveryFee: menu.deliveryFee,
      ),
    );

    if (placed != null && mounted) {
      setState(() => _basket.clear());
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Quench'),
        actions: [
          IconButton(
            tooltip: 'My orders',
            icon: const Icon(Icons.receipt_long_outlined, size: 21),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Menu>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text('Could not load the menu.',
                    style: TextStyle(color: mute)),
              ),
            );
          }

          final menu = snap.data!;
          Prices.show = menu.showPrices;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: EdgeInsets.fromLTRB(18, 8, 18, _count > 0 ? 110 : 28),
                children: [
                  if (!menu.open)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: F4L.orange.withValues(alpha: 0.10),
                        border: Border.all(
                            color: F4L.orange.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(children: [
                        const Icon(Icons.schedule, size: 18, color: F4L.orange),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'The kitchen is closed. You can still order — it '
                            'will be made when we open. ${menu.hours}',
                            style: const TextStyle(fontSize: 13, height: 1.45),
                          ),
                        ),
                      ]),
                    ),
                  Text('OPEN ${menu.hours}'.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: mute)),
                  const SizedBox(height: 14),
                  for (final section in menu.sections) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Row(children: [
                        IconFor.foodSection(section.name).tile(size: 30),
                        const SizedBox(width: 10),
                        Text(section.name.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.7)),
                      ]),
                    ),
                    ...section.items.map((item) => _ItemRow(
                          item: item,
                          section: section.name,
                          quantity: _basket[item.id] ?? 0,
                          onAdd: () => _add(item),
                          onRemove: () => _remove(item),
                        )),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    Prices.show
                        ? 'Member discount is applied at checkout — you are '
                            'already signed in, so there is nothing to scan.'
                        : 'Prices are being finalised. Order now and the '
                            'counter will confirm your total, with your member '
                            'discount already taken off.',
                    style: TextStyle(fontSize: 12.5, height: 1.6, color: mute),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _count == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: FilledButton(
                  onPressed: () async => _checkout(await _future),
                  style: FilledButton.styleFrom(
                    backgroundColor: F4L.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    Prices.show
                        ? '$_count item${_count == 1 ? '' : 's'} · '
                            '${Prices.of(_subtotal)} — Checkout'
                        : '$_count item${_count == 1 ? '' : 's'} — Checkout',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.section,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final MenuItem item;
  final String section;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final off = !item.available;

    return Opacity(
      opacity: off ? 0.45 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconFor.food(item.name, section).tile(size: 42),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w800)),
                    if (item.description != null)
                      Text(item.description!,
                          style: TextStyle(
                              fontSize: 12.5, height: 1.4, color: mute)),
                    const SizedBox(height: 4),
                    Text(
                      off
                          ? 'Sold out'
                          : Prices.show
                              ? '${Prices.of(item.price)} · ${item.prep} min'
                              : 'About ${item.prep} min',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: off ? mute : F4L.teal),
                    ),
                  ],
                ),
              ),
              if (!off)
                quantity == 0
                    ? IconButton.filledTonal(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add, size: 19),
                        tooltip: 'Add',
                      )
                    : Row(children: [
                        IconButton(
                            onPressed: onRemove,
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 21)),
                        Text('$quantity',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        IconButton(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add_circle,
                                size: 21, color: F4L.orange)),
                      ]),
            ],
          ),
        ),
      ),
    );
  }
}
