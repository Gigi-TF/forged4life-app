import 'package:flutter/material.dart';

import '../services/press_api.dart';
import '../services/prices.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import '../widgets/icon_lookup.dart';

/// Book a photo sitting — passport, ID, visa, driver's licence or a portrait.
/// Taken and printed on the premises while you wait.
class StudioBookingScreen extends StatefulWidget {
  const StudioBookingScreen({super.key, required this.services});
  final List<PrintService> services;

  @override
  State<StudioBookingScreen> createState() => _StudioBookingScreenState();
}

class _StudioBookingScreenState extends State<StudioBookingScreen> {
  PrintService? _service;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _time;
  final _country = TextEditingController();
  int _copies = 4;

  late Future<List<Map<String, dynamic>>> _slots;
  bool _booking = false;

  static const _purposes = {
    'passport-photos': 'passport',
    'id-photos': 'national_id',
    'visa-photos': 'visa',
    'portrait': 'portrait',
  };

  @override
  void initState() {
    super.initState();
    _service = widget.services.firstOrNull;
    _slots = PressApi().slots(_date);
  }

  @override
  void dispose() {
    _country.dispose();
    super.dispose();
  }

  void _setDate(DateTime d) {
    setState(() {
      _date = d;
      _time = null;
      _slots = PressApi().slots(d);
    });
  }

  Future<void> _book() async {
    if (_service == null || _time == null) return;
    setState(() => _booking = true);

    try {
      final booking = await PressApi().bookStudio(
        serviceId: _service!.id,
        purpose: _purposes[_service!.slug] ?? 'portrait',
        date: _date,
        time: _time!,
        country: _country.text,
        copies: _copies,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Booked — ${booking['reference']}'),
          content: Text(
            '${booking['purpose']} on ${booking['date']} at ${booking['time']}.\n\n'
            'Come to The Press a few minutes early. Wear something you would '
            'be happy to see on a document for the next ten years.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _booking = false;
        _slots = PressApi().slots(_date); // someone may have taken it
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final isVisa = _service?.slug == 'visa-photos';

    return Scaffold(
      appBar: AppBar(title: const Text('Book a sitting')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              Text('WHAT FOR',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.7,
                      color: mute)),
              const SizedBox(height: 10),
              ...widget.services.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _service = s),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: _service?.id == s.id
                              ? F4L.orange.withValues(alpha: 0.09)
                              : null,
                          border: Border.all(
                            color: _service?.id == s.id
                                ? F4L.orange
                                : Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.6),
                            width: _service?.id == s.id ? 1.6 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          IconFor.press(s.name, 'studio').tile(size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800)),
                                if (s.description != null)
                                  Text(s.description!,
                                      style: TextStyle(
                                          fontSize: 12.5, color: mute)),
                              ],
                            ),
                          ),
                          if (Prices.show)
                            Text(Prices.of(s.price),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ),
                  )),
              if (isVisa) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _country,
                  decoration: const InputDecoration(
                    labelText: 'Which country?',
                    hintText: 'Requirements differ by embassy',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('WHEN',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.7,
                      color: mute)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(7, (i) {
                    final d = DateTime.now().add(Duration(days: i + 1));
                    final on = d.day == _date.day && d.month == _date.month;
                    const names = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun'
                    ];

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () => _setDate(d),
                        child: Container(
                          width: 56,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: on ? F4L.orange : null,
                            border: Border.all(
                                color: on
                                    ? F4L.orange
                                    : Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.6)),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Column(children: [
                            Text(names[d.weekday - 1],
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: on ? Colors.white : mute)),
                            const SizedBox(height: 2),
                            Text('${d.day}',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: on ? Colors.white : null)),
                          ]),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _slots,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final slots = snap.data ?? [];
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((s) {
                      final time = s['time'] as String;
                      final free = s['available'] as bool;
                      final on = _time == time;

                      return ChoiceChip(
                        label: Text(time),
                        selected: on,
                        showCheckmark: false,
                        selectedColor: F4L.teal,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                          color: on
                              ? Colors.white
                              : free
                                  ? null
                                  : mute,
                          decoration: free ? null : TextDecoration.lineThrough,
                        ),
                        onSelected:
                            free ? (_) => setState(() => _time = time) : null,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: (_time == null || _booking) ? null : _book,
                style: FilledButton.styleFrom(
                  backgroundColor: F4L.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _booking
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white))
                    : Text(
                        _time == null
                            ? 'Pick a time'
                            : 'Book $_time on ${_date.day}/${_date.month}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const SizedBox(height: 10),
              Text(
                  Prices.show
                      ? 'Pay at the counter after your sitting.'
                      : 'Prices are being finalised — the counter will confirm '
                          'before you pay.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: mute)),
            ],
          ),
        ),
      ),
    );
  }
}
