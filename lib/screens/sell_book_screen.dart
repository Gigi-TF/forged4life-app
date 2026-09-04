import 'package:flutter/material.dart';

import '../services/prices.dart';
import '../services/shelf_api.dart';
import '../theme/f4l_theme.dart';

/// Offer a book for sale.
///
/// The form is short on purpose. Every field is one more reason to abandon it,
/// and staff verify the book physically anyway — anything wrong gets corrected
/// at the counter.
class SellBookScreen extends StatefulWidget {
  const SellBookScreen({super.key});

  @override
  State<SellBookScreen> createState() => _SellBookScreenState();
}

class _SellBookScreenState extends State<SellBookScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();

  String _condition = 'good';
  String _category = 'Business & finance';
  bool _sending = false;
  String? _done;

  static const _categories = [
    'Business & finance',
    'Leadership',
    'Personal development',
    'Technical & professional',
    'Academic',
    'Faith & wellbeing',
    'Fiction',
    'Other',
  ];

  double get _youGet {
    final p = double.tryParse(_price.text) ?? 0;
    return p * 0.8;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);

    try {
      final msg = await ShelfApi().offer(
        title: _title.text.trim(),
        author: _author.text.trim(),
        category: _category,
        condition: _condition,
        price: double.parse(_price.text),
        description: _description.text.trim(),
      );
      if (mounted) {
        setState(() {
        _done = msg;
        _sending = false;
      });
      }
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    if (_done != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listed')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 48, color: F4L.teal),
                  const SizedBox(height: 16),
                  Text(_done!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, height: 1.55, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(
                    'You can withdraw it any time before it sells.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: mute),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: F4L.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sell a book')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: F4L.teal.withValues(alpha: 0.07),
                    border: Border.all(color: F4L.teal.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How it works',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'Tell us about the book, then bring it to reception. '
                        'We check it over and put it on the shelf. When it '
                        'sells you keep 80% — we take 20% for holding and '
                        'handling it.',
                        style: TextStyle(
                            fontSize: 13, height: 1.55, color: mute),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _label('Title'),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      hintText: 'Thinking, Fast and Slow'),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'We need the title'
                      : null,
                ),
                const SizedBox(height: 14),

                _label('Author'),
                TextFormField(
                  controller: _author,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Daniel Kahneman'),
                ),
                const SizedBox(height: 14),

                _label('Category'),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 14),

                _label('Condition'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'new', label: Text('As new')),
                    ButtonSegment(value: 'good', label: Text('Good')),
                    ButtonSegment(value: 'fair', label: Text('Well read')),
                  ],
                  selected: {_condition},
                  onSelectionChanged: (s) =>
                      setState(() => _condition = s.first),
                ),
                const SizedBox(height: 6),
                Text(
                  'Be honest — reception checks it, and a book marked "as new" '
                  'that is not gets sent back.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: mute),
                ),
                const SizedBox(height: 14),

                _label('Your asking price'),
                TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      prefixText: '\$ ', hintText: '12.00'),
                  validator: (v) {
                    final p = double.tryParse(v ?? '');
                    if (p == null || p < 0.5) return 'Give a price';
                    if (p > 500) return 'That seems high — talk to reception';
                    return null;
                  },
                ),
                if (Prices.show && _youGet > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: F4L.orange.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(children: [
                      const Icon(Icons.savings_outlined,
                          size: 18, color: F4L.orange),
                      const SizedBox(width: 9),
                      Text('You get \$${_youGet.toStringAsFixed(2)} when it sells',
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: F4L.orange)),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),

                _label('Anything a buyer should know?'),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      hintText: 'Some highlighting in chapter 3, otherwise clean'),
                ),
                const SizedBox(height: 20),

                FilledButton(
                  onPressed: _sending ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: F4L.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white))
                      : const Text('List it',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                const SizedBox(height: 10),
                Text(
                  'Nothing appears on the shelf until we physically have the '
                  'book — that is what stops buyers reserving things that are '
                  'still at home.',
                  style: TextStyle(fontSize: 12, height: 1.55, color: mute),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
      );
}
