import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/press_api.dart';
import '../services/prices.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';
import '../widgets/icon_lookup.dart';
import 'studio_booking_screen.dart';

/// The Press — printing, copying, photos and the studio.
class PressScreen extends StatefulWidget {
  const PressScreen({super.key});

  @override
  State<PressScreen> createState() => _PressScreenState();
}

class _PressScreenState extends State<PressScreen> {
  late Future<PressCatalogue> _future;

  final List<_Job> _jobs = [];
  final List<PlatformFile> _files = [];
  final _instructions = TextEditingController();
  bool _sending = false;

  static const _order = ['documents', 'photos', 'finishing', 'studio'];
  static const _titles = {
    'documents': 'Documents',
    'photos': 'Photos',
    'finishing': 'Finishing',
    'studio': 'In the studio',
  };

  @override
  void initState() {
    super.initState();
    _future = PressApi().services();
  }

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  double get _subtotal =>
      _jobs.fold(0.0, (s, j) => s + j.service.price * j.quantity);

  Future<void> _pickFiles(PressCatalogue cat) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
        'jpg', 'jpeg', 'png', 'heic', 'webp',
      ],
    );
    if (result == null) return;

    final tooBig = result.files
        .where((f) => f.size > cat.maxFileMb * 1024 * 1024)
        .toList();

    setState(() {
      _files.addAll(result.files.where((f) => !tooBig.contains(f)));
      if (_files.length > cat.maxFiles) {
        _files.removeRange(cat.maxFiles, _files.length);
      }
    });

    if (tooBig.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${tooBig.length} file(s) over ${cat.maxFileMb}MB were '
            'skipped. Bring those on a USB stick.'),
      ));
    }
  }

  Future<void> _send() async {
    setState(() => _sending = true);

    try {
      final order = await PressApi().placeOrder(
        items: _jobs
            .map((j) => (
                  serviceId: j.service.id,
                  quantity: j.quantity,
                  options: j.chosen,
                ))
            .toList(),
        files: _files,
        instructions: _instructions.text,
      );

      if (!mounted) return;
      setState(() {
        _jobs.clear();
        _files.clear();
        _instructions.clear();
        _sending = false;
      });

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Sent — ${order['number']}'),
          content: const Text(
              'The Press will check the details and confirm your price. '
              'You will see it under My print jobs.'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(c), child: const Text('Right'))
          ],
        ),
      );
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

    return Scaffold(
      appBar: AppBar(title: const Text('The Press')),
      body: FutureBuilder<PressCatalogue>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Could not load The Press.',
                    style: TextStyle(color: mute)));
          }

          final cat = snap.data!;
          Prices.show = cat.showPrices;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding:
                    EdgeInsets.fromLTRB(18, 10, 18, _jobs.isEmpty ? 28 : 110),
                children: [
                  Text(
                    'Printing, copying, photos and passport pictures — all on '
                    'the premises. Send your files ahead and collect when ready.',
                    style: TextStyle(fontSize: 14.5, height: 1.6, color: mute),
                  ),
                  const SizedBox(height: 18),

                  for (final key in _order)
                    if (cat.categories[key] != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Row(children: [
                          IconFor.pressCategory(key).tile(size: 30),
                          const SizedBox(width: 10),
                          Text(_titles[key]!.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.7)),
                        ]),
                      ),
                      if (key == 'studio')
                        _StudioBanner(services: cat.categories[key]!)
                      else
                        ...cat.categories[key]!.map((s) => _ServiceRow(
                              service: s,
                              job: _jobs
                                  .where((j) => j.service.id == s.id)
                                  .firstOrNull,
                              onChanged: (job) => setState(() {
                                _jobs.removeWhere((j) => j.service.id == s.id);
                                if (job != null) _jobs.add(job);
                              }),
                            )),
                    ],

                  const SizedBox(height: 22),
                  Text('YOUR FILES',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.7,
                          color: mute)),
                  const SizedBox(height: 10),

                  ..._files.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.85),
                            border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.6)),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(children: [
                            ForgeIcons.documents.tile(size: 32),
                            const SizedBox(width: 11),
                            Expanded(
                                child: Text(f.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13.5))),
                            Text('${(f.size / 1024 / 1024).toStringAsFixed(1)} MB',
                                style: TextStyle(fontSize: 12, color: mute)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 17),
                              onPressed: () => setState(() => _files.remove(f)),
                            ),
                          ]),
                        ),
                      )),

                  OutlinedButton.icon(
                    onPressed: () => _pickFiles(cat),
                    icon: const Icon(Icons.upload_file, size: 19),
                    label: Text(_files.isEmpty
                        ? 'Upload documents or photos'
                        : 'Add more files'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Up to ${cat.maxFiles} files, ${cat.maxFileMb}MB each. '
                    'We delete everything you send ${cat.purgeDays} days after '
                    'your job is finished.',
                    style: TextStyle(fontSize: 12, height: 1.55, color: mute),
                  ),

                  const SizedBox(height: 18),
                  TextField(
                    controller: _instructions,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Anything we should know?',
                      hintText: 'Pages 3–12 only, staple top left…',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _jobs.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: FilledButton(
                  onPressed: _sending ? null : _send,
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
                      : Text(
                          Prices.show
                              ? 'Send to The Press · about '
                                  '${Prices.of(_subtotal)}'
                              : 'Send to The Press',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ),
    );
  }
}

class _Job {
  _Job({required this.service, Map<String, String>? chosen})
      : quantity = 1,
        chosen = chosen ?? {};

  final PrintService service;
  int quantity;
  Map<String, String> chosen;
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.job,
    required this.onChanged,
  });

  final PrintService service;
  final _Job? job;
  final ValueChanged<_Job?> onChanged;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final on = job != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
          border: Border.all(
            color: on
                ? F4L.orange.withValues(alpha: 0.6)
                : Theme.of(context).dividerColor.withValues(alpha: 0.6),
            width: on ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(children: [
              IconFor.press(service.name, service.unit).tile(size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name,
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w800)),
                    if (service.description != null)
                      Text(service.description!,
                          style: TextStyle(
                              fontSize: 12.5, height: 1.4, color: mute)),
                    const SizedBox(height: 3),
                    Text(
                        Prices.show
                            ? '${Prices.of(service.price)} ${service.unitLabel}'
                            : 'Priced ${service.unitLabel}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: F4L.teal)),
                  ],
                ),
              ),
              on
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 21),
                      onPressed: () => onChanged(null))
                  : IconButton.filledTonal(
                      icon: const Icon(Icons.add, size: 19),
                      onPressed: () => onChanged(_Job(service: service))),
            ]),

            if (on) ...[
              const Divider(height: 20),
              Row(children: [
                Text(
                    service.unit == 'per_page'
                        ? 'Pages'
                        : service.unit == 'per_print'
                            ? 'Prints'
                            : 'Quantity',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: job!.quantity > 1
                      ? () {
                          job!.quantity--;
                          onChanged(job);
                        }
                      : null,
                ),
                Text('${job!.quantity}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    job!.quantity++;
                    onChanged(job);
                  },
                ),
              ]),
              for (final entry in service.options.entries)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    SizedBox(
                      width: 66,
                      child: Text(entry.key[0].toUpperCase() +
                          entry.key.substring(1),
                          style: TextStyle(fontSize: 12.5, color: mute)),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.value.map((v) {
                          final picked = job!.chosen[entry.key] == v ||
                              (job!.chosen[entry.key] == null &&
                                  entry.value.first == v);
                          return ChoiceChip(
                            label: Text(v, style: const TextStyle(fontSize: 12)),
                            selected: picked,
                            showCheckmark: false,
                            selectedColor: F4L.orange,
                            labelStyle: TextStyle(
                                fontSize: 12,
                                color: picked ? Colors.white : null),
                            onSelected: (_) =>
                                onChanged(job!..chosen[entry.key] = v),
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The studio is a booking, not a basket item — you have to turn up.
class _StudioBanner extends StatelessWidget {
  const _StudioBanner({required this.services});
  final List<PrintService> services;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            F4L.teal.withValues(alpha: 0.10),
            F4L.orange.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: F4L.teal.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Passport, ID and visa photos',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
            'Taken and printed while you wait. Book a slot so you are not '
            'queueing — half-hour slots, nine to four.',
            style: TextStyle(fontSize: 13, height: 1.55, color: mute),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StudioBookingScreen(services: services),
            )),
            style: FilledButton.styleFrom(
              backgroundColor: F4L.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Book a sitting',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
