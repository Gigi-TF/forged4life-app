import 'package:flutter/material.dart';

import '../services/prices.dart';
import '../services/shelf_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import 'my_listings_screen.dart';
import 'sell_book_screen.dart';
import 'shelf_item_sheet.dart';

/// The Shelf — the institute's learning-resources exchange.
///
/// Two-sided: the institute's own stock, and books members have finished with.
class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  late Future<Shelf> _future;
  String _category = '';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = ShelfApi()
      .browse(category: _category, search: _search.text.trim());

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(ShelfItem item, int holdDays) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShelfItemSheet(item: item, holdDays: holdDays),
    );
    if (changed == true) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Shelf'),
        actions: [
          IconButton(
            tooltip: 'My listings',
            icon: const Icon(Icons.inventory_2_outlined, size: 21),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyListingsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Shelf>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Could not load The Shelf.',
                  style: TextStyle(color: mute)),
            );
          }

          final shelf = snap.data!;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(_load);
                  await _future;
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                  children: [
                    Text('LEARNING RESOURCES',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                            color: mute)),
                    const SizedBox(height: 6),
                    Text(
                      'Books from the institute, and books other members have '
                      'finished with. Collect and pay at reception.',
                      style:
                          TextStyle(fontSize: 14, height: 1.6, color: mute),
                    ),
                    const SizedBox(height: 16),

                    // Selling comes first while the shelf is empty. With no
                    // stock, the useful thing a member can do is supply it —
                    // and sellers are what create the buy side.
                    if (shelf.items.isEmpty)
                      _emptyShelf(context, shelf, mute)
                    else ...[
                      _sellStrip(context, shelf, mute),
                      const SizedBox(height: 16),
                      _filters(context, shelf),
                      const SizedBox(height: 14),
                      ...shelf.items.map((i) => _ItemRow(
                            item: i,
                            onTap: () => _open(i, shelf.holdDays),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyShelf(BuildContext context, Shelf shelf, Color? mute) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              F4L.teal.withValues(alpha: 0.10),
              F4L.orange.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: F4L.teal.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ForgeIcons.blog.tile(size: 46),
            const SizedBox(height: 14),
            const Text('The shelf is empty — for now.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'It fills up from both ends. The institute is stocking its first '
              'titles, and members are bringing in books they have finished '
              'with. If you have one worth passing on, start there.',
              style: TextStyle(fontSize: 14, height: 1.6, color: mute),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SellBookScreen()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: F4L.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Sell a book — you keep ${shelf.sellerShare}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14.5)),
            ),
          ],
        ),
      );

  Widget _sellStrip(BuildContext context, Shelf shelf, Color? mute) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SellBookScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: F4L.orange.withValues(alpha: 0.07),
            border: Border.all(color: F4L.orange.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            ForgeIcons.press.tile(size: 38),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sell a book you have finished with',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                  Text('You keep ${shelf.sellerShare}% · bring it to reception',
                      style: TextStyle(fontSize: 12.5, color: mute)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 19),
          ]),
        ),
      );

  Widget _filters(BuildContext context, Shelf shelf) => Column(
        children: [
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => setState(_load),
            decoration: InputDecoration(
              hintText: 'Title or author',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _search.clear();
                        setState(_load);
                      },
                    ),
            ),
          ),
          if (shelf.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(context, 'All', _category.isEmpty, () {
                    _category = '';
                    setState(_load);
                  }),
                  ...shelf.categories.map((c) => _chip(
                        context,
                        c,
                        _category == c,
                        () {
                          _category = c;
                          setState(_load);
                        },
                      )),
                ],
              ),
            ),
          ],
        ],
      );

  Widget _chip(BuildContext c, String label, bool on, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: on,
          showCheckmark: false,
          selectedColor: F4L.orange,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: on ? FontWeight.w800 : FontWeight.w600,
            color: on ? Colors.white : null,
          ),
          onSelected: (_) => onTap(),
        ),
      );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap});
  final ShelfItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A cover if there is one, a spine-ish block if not — a book
              // list with no covers reads as a spreadsheet.
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.cover != null
                    ? Image.network(item.cover!,
                        width: 46,
                        height: 66,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _spine(context))
                    : _spine(context),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            height: 1.3)),
                    if (item.author != null)
                      Text(item.author!,
                          style: TextStyle(fontSize: 12.5, color: mute)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 5, children: [
                      if (item.secondHand)
                        _tag(context, 'SECOND HAND', F4L.tealMid),
                      if (item.isDigital)
                        _tag(context, 'DIGITAL', F4L.teal)
                      else
                        _tag(context, item.conditionLabel.toUpperCase(),
                            mute ?? F4L.teal),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (Prices.show)
                Text('\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800))
              else
                Icon(Icons.chevron_right, size: 19, color: mute),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spine(BuildContext context) => Container(
        width: 46,
        height: 66,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              F4L.teal.withValues(alpha: 0.7),
              F4L.tealDeep.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: const Icon(Icons.menu_book_rounded, size: 20, color: Colors.white),
      );

  Widget _tag(BuildContext c, String label, Color colour) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: colour)),
      );
}
