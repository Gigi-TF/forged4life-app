import 'package:flutter/material.dart';

import '../services/prices.dart';
import '../services/shelf_api.dart';
import '../theme/f4l_theme.dart';
import 'sell_book_screen.dart';

/// Books this member is selling, at every stage.
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<MyListing>> _future;

  @override
  void initState() {
    super.initState();
    _future = ShelfApi().myListings();
  }

  void _reload() => setState(() => _future = ShelfApi().myListings());

  Future<void> _withdraw(MyListing l) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Take it back?'),
        content: Text(l.status == 'offered'
            ? 'This just removes the listing — you have not brought it in yet.'
            : 'We will put it aside at reception for you to collect.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep it listed')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Withdraw')),
        ],
      ),
    );
    if (sure != true) return;

    try {
      await ShelfApi().withdraw(l.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: FutureBuilder<List<MyListing>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rows = snap.data ?? [];
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(28),
                    children: [
                      const SizedBox(height: 60),
                      Text('You have not listed anything yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: mute)),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (_) => const SellBookScreen()))
                            .then((_) => _reload()),
                        style: FilledButton.styleFrom(
                          backgroundColor: F4L.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sell a book',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                  children: rows
                      .map((l) => _ListingRow(
                            l: l,
                            onWithdraw: () => _withdraw(l),
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.l, required this.onWithdraw});
  final MyListing l;
  final VoidCallback onWithdraw;

  Color _colour() => switch (l.status) {
        'offered' => const Color(0xFFB07A0E),
        'received' => F4L.tealMid,
        'listed' => F4L.teal,
        'reserved' => F4L.orange,
        'sold' || 'collected' => F4L.teal,
        _ => const Color(0xFF64797C),
      };

  bool get _canWithdraw =>
      !['sold', 'collected', 'reserved', 'withdrawn'].contains(l.status);

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(l.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _colour(),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(l.label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: Colors.white)),
              ),
            ]),
            if (l.author != null)
              Text(l.author!, style: TextStyle(fontSize: 12.5, color: mute)),

            if (Prices.show) ...[
              const SizedBox(height: 10),
              Row(children: [
                Text('Listed at \$${l.price.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12.5, color: mute)),
                const Spacer(),
                Text(
                    l.status == 'sold' || l.status == 'collected'
                        ? (l.paidOut
                            ? 'Paid \$${l.youGet.toStringAsFixed(2)}'
                            : 'You are owed \$${l.youGet.toStringAsFixed(2)}')
                        : 'You get \$${l.youGet.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: l.paidOut ? mute : F4L.orange)),
              ]),
            ],

            if (_canWithdraw) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onWithdraw,
                  child: const Text('Withdraw'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
