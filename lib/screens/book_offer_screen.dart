import 'package:flutter/material.dart';

import '../services/books_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';

/// Selling or donating books.
///
/// Short on purpose, matching the website. Condition, quantity and price are
/// conversation topics, not form fields — asking a stranger to grade fifteen
/// paperbacks before you have said hello is how a form gets abandoned.
///
/// Name, email and phone come from the account, so the only things left are
/// what they have and when to call.
class BookOfferScreen extends StatefulWidget {
  const BookOfferScreen({super.key, required this.donating});

  final bool donating;

  @override
  State<BookOfferScreen> createState() => _BookOfferScreenState();
}

class _BookOfferScreenState extends State<BookOfferScreen> {
  final _form = GlobalKey<FormState>();
  final _titles = TextEditingController();

  String _bestTime = 'anytime';
  bool _consent = false;
  bool _busy = false;

  bool get _donating => widget.donating;

  static const _times = [
    ('morning', 'Mornings'),
    ('afternoon', 'Afternoons'),
    ('evening', 'Evenings'),
    ('anytime', 'Any time'),
  ];

  @override
  void dispose() {
    _titles.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please tick the box so we know we can contact you.'),
      ));
      return;
    }

    setState(() => _busy = true);

    // No column for it, so it rides along in the note — which is where staff
    // read it anyway before picking up the phone.
    final label = _times.firstWhere((t) => t.$1 == _bestTime).$2;
    final note = 'Best time to reach: $label';

    try {
      final msg = _donating
          ? await BooksApi().donate(titles: _titles.text.trim(), notes: note)
          : await BooksApi().sell(titles: _titles.text.trim(), notes: note);

      if (!mounted) return;
      setState(() => _busy = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: Text(_donating ? 'Thank you' : 'Details sent'),
          content: Text(msg),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: F4L.orange),
              child: const Text('Done'),
            ),
          ],
        ),
      );
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
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar:
          AppBar(title: Text(_donating ? 'Donate books' : 'Sell your books')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                children: [
                  Center(
                    child: ForgeIcon(
                      _donating ? Icons.favorite_rounded : Icons.sell_rounded,
                      tone: _donating ? ForgeTone.ember : ForgeTone.gold,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 16),

                  BlendText(
                    _donating
                        ? 'Give your books a second life.'
                        : 'Tell us what you have.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _donating
                        ? 'Donations go to the Forge shelf and to community '
                            'reading programmes.'
                        : 'We will come back to you with what we can offer and '
                            'how collection works.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.6, color: mute),
                  ),

                  const SizedBox(height: 26),

                  _label('What do you have?'),
                  TextFormField(
                    controller: _titles,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'A rough idea is fine — titles, or just '
                          '"about fifteen novels and some business books".',
                    ),
                    validator: (v) => (v == null || v.trim().length < 5)
                        ? 'Tell us roughly what you have'
                        : null,
                  ),

                  const SizedBox(height: 20),
                  _label('When is a good time to reach you?'),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: _times
                        .map((t) => _Chip(
                              label: t.$2,
                              selected: t.$1 == _bestTime,
                              onTap: () => setState(() => _bestTime = t.$1),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 22),
                  InkWell(
                    onTap: () => setState(() => _consent = !_consent),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _consent,
                            activeColor: F4L.orange,
                            onChanged: (v) =>
                                setState(() => _consent = v ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _donating
                                    ? 'I am happy for SkillsForge360 to contact '
                                        'me about donating my books.'
                                    : 'I am happy for SkillsForge360 to contact '
                                        'me about selling my books.',
                                style: const TextStyle(
                                    fontSize: 13.5, height: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: F4L.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.3, color: Colors.white))
                        : const Text('Send details',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'No obligation. Your name and contact details come from '
                    'your account, so there is nothing else to fill in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.55, color: mute),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? F4L.orange.withValues(alpha: 0.12) : null,
            border: Border.all(
              color: selected
                  ? F4L.orange
                  : Theme.of(context).dividerColor.withValues(alpha: 0.7),
              width: selected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? F4L.orange : null)),
        ),
      );
}