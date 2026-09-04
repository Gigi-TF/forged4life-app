import 'package:flutter/material.dart';

import '../services/prices.dart';
import '../services/shelf_api.dart';
import '../theme/f4l_theme.dart';

class ShelfItemSheet extends StatefulWidget {
  const ShelfItemSheet({super.key, required this.item, required this.holdDays});
  final ShelfItem item;
  final int holdDays;

  @override
  State<ShelfItemSheet> createState() => _ShelfItemSheetState();
}

class _ShelfItemSheetState extends State<ShelfItemSheet> {
  bool _busy = false;
  String? _done;

  Future<void> _reserve() async {
    setState(() => _busy = true);
    try {
      final msg = await ShelfApi().reserve(widget.item.id);
      if (mounted) {
        setState(() {
        _done = msg;
        _busy = false;
      });
      }
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            Text(i.title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, height: 1.25)),
            if (i.author != null) ...[
              const SizedBox(height: 4),
              Text(i.author!, style: TextStyle(fontSize: 14, color: mute)),
            ],

            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (i.secondHand) _pill('Second hand', F4L.tealMid),
              _pill(i.isDigital ? 'Digital' : i.conditionLabel, F4L.teal),
              if (i.category != null) _pill(i.category!, mute ?? F4L.teal),
              if (Prices.show)
                _pill('\$${i.price.toStringAsFixed(2)}', F4L.orange),
            ]),

            if (i.description != null) ...[
              const SizedBox(height: 16),
              Text(i.description!,
                  style: TextStyle(fontSize: 14, height: 1.6, color: mute)),
            ],

            const SizedBox(height: 18),

            if (_done != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: F4L.teal.withValues(alpha: 0.09),
                  border: Border.all(color: F4L.teal.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle, size: 19, color: F4L.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_done!,
                        style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: F4L.teal.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(children: [
                  Icon(i.isDigital
                      ? Icons.cloud_download_outlined
                      : Icons.storefront_outlined,
                      size: 18, color: mute),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      i.isDigital
                          ? 'Pay at reception and we will email you the file.'
                          : 'We hold it at reception for ${widget.holdDays} '
                              'days. Collect and pay there.',
                      style: TextStyle(
                          fontSize: 12.5, height: 1.5, color: mute),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _reserve,
                style: FilledButton.styleFrom(
                  backgroundColor: F4L.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white))
                    // "Reserve", not "Buy" — payment happens at the counter,
                    // and promising a purchase the app cannot complete is how
                    // you get an argument at reception.
                    : const Text('Reserve this book',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],

            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, _done != null),
                child: Text(_done != null ? 'Done' : 'Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color colour) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: colour)),
      );
}
