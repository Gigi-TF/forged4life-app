import 'package:flutter/material.dart';

import '../services/cafeteria_api.dart';
import '../services/prices.dart';
import '../theme/f4l_theme.dart';

/// Choose how you want it: eat in, collect, or delivered.
///
/// "Dial a delivery" is the third option — an address and a phone number,
/// nothing more. Payment is at the counter or on delivery for now.
class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({
    super.key,
    required this.basket,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
  });

  final Map<int, int> basket;
  final Map<int, MenuItem> items;
  final double subtotal;
  final double deliveryFee;

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  String _mode = 'collect';
  final _table = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  final _phone = TextEditingController();

  bool _sending = false;
  String? _error;

  double get _fee => _mode == 'delivery' ? widget.deliveryFee : 0;
  double get _total => widget.subtotal + _fee;

  Future<void> _place() async {
    if (_mode == 'delivery' &&
        (_address.text.trim().isEmpty || _phone.text.trim().isEmpty)) {
      setState(() => _error = 'We need an address and a number to deliver.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final order = await CafeteriaApi().placeOrder(
        fulfilment: _mode,
        quantities: widget.basket,
        tableNumber: _table.text,
        address: _address.text,
        notes: _notes.text,
        phone: _phone.text,
      );
      if (mounted) Navigator.of(context).pop(order);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _sending = false;
      });
    }
  }

  @override
  void dispose() {
    _table.dispose();
    _address.dispose();
    _notes.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
              const Text('How would you like it?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              _Mode(
                value: 'eat_in',
                group: _mode,
                icon: Icons.restaurant,
                title: 'Eat in',
                sub: 'We bring it to your table at The Quench',
                onTap: (v) => setState(() => _mode = v),
              ),
              _Mode(
                value: 'collect',
                group: _mode,
                icon: Icons.shopping_bag_outlined,
                title: 'Collect',
                sub: 'Ready at the counter — we will tell you when',
                onTap: (v) => setState(() => _mode = v),
              ),
              _Mode(
                value: 'delivery',
                group: _mode,
                icon: Icons.delivery_dining,
                title: 'Dial a delivery',
                sub: Prices.show
                    ? 'Brought to you · ${Prices.of(widget.deliveryFee)}'
                    : 'Brought to you · small delivery fee',
                onTap: (v) => setState(() => _mode = v),
              ),
              const SizedBox(height: 14),
              if (_mode == 'eat_in')
                TextField(
                  controller: _table,
                  decoration: const InputDecoration(
                      labelText: 'Table number (if you know it)'),
                ),
              if (_mode == 'delivery') ...[
                TextField(
                  controller: _address,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Delivery address',
                      hintText: 'Building, street, suburb'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Contact number',
                      hintText: '+263 71 000 0000'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(
                      labelText: 'Notes for the driver (optional)',
                      hintText: 'Gate code, landmark, who to ask for'),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: F4L.teal.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Prices.show
                    ? Column(children: [
                        _Line('Subtotal', widget.subtotal),
                        if (_fee > 0) _Line('Delivery', _fee),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Your member discount is applied when the order '
                            'is placed.',
                            style: TextStyle(fontSize: 11.5, color: mute),
                          ),
                        ),
                        const Divider(height: 20),
                        _Line('Before discount', _total, bold: true),
                      ])
                    : Row(children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Prices are being finalised. The counter will '
                            'confirm your total, with your member discount '
                            'already taken off.',
                            style: TextStyle(
                                fontSize: 12.5, height: 1.5, color: mute),
                          ),
                        ),
                      ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13.5)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sending ? null : _place,
                  style: FilledButton.styleFrom(
                    backgroundColor: F4L.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white))
                      : const Text('Place order',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text('Pay at the counter or on delivery',
                    style: TextStyle(fontSize: 12.5, color: mute)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mode extends StatelessWidget {
  const _Mode({
    required this.value,
    required this.group,
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  final String value;
  final String group;
  final IconData icon;
  final String title;
  final String sub;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final on = value == group;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: on ? F4L.orange.withValues(alpha: 0.09) : null,
            border: Border.all(
              color: on
                  ? F4L.orange
                  : Theme.of(context).dividerColor.withValues(alpha: 0.7),
              width: on ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(icon, size: 21, color: on ? F4L.orange : null),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
            if (on) const Icon(Icons.check_circle, size: 20, color: F4L.orange),
          ]),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.amount, {this.bold = false});
  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
            Text('\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      );
}
