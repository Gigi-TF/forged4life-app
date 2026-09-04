import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/loyalty_api.dart';
import '../theme/f4l_theme.dart';
import '../widgets/forge_icon.dart';

/// The codes to show at reception.
class MyCodesScreen extends StatefulWidget {
  const MyCodesScreen({super.key});

  @override
  State<MyCodesScreen> createState() => _MyCodesScreenState();
}

class _MyCodesScreenState extends State<MyCodesScreen> {
  late Future<List<RedemptionCode>> _future;

  @override
  void initState() {
    super.initState();
    _future = LoyaltyApi().myCodes();
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('My codes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = LoyaltyApi().myCodes());
              await _future;
            },
            child: FutureBuilder<List<RedemptionCode>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snap.data ?? [];
                final unused = all.where((c) => c.unused).toList();
                final used = all.where((c) => !c.unused).toList();

                if (all.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(28),
                    children: [
                      const SizedBox(height: 60),
                      Center(child: ForgeIcons.perks.tile(size: 46)),
                      const SizedBox(height: 14),
                      const Text('Nothing redeemed yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('Codes you redeem appear here, ready to show.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13.5, height: 1.5, color: mute)),
                    ],
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                  children: [
                    if (unused.isNotEmpty) ...[
                      Text('READY TO USE',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: mute)),
                      const SizedBox(height: 10),
                      ...unused.map((c) => _CodeCard(code: c)),
                      const SizedBox(height: 20),
                    ],
                    if (used.isNotEmpty) ...[
                      Text('USED',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: mute)),
                      const SizedBox(height: 10),
                      ...used.map((c) => _CodeCard(code: c)),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});
  final RedemptionCode code;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final live = code.unused;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: live ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
            border: Border.all(
                color: live
                    ? F4L.orange.withValues(alpha: 0.5)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                width: live ? 1.5 : 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(code.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                Text('${code.spent} sparks',
                    style: TextStyle(fontSize: 12, color: mute)),
              ]),
              const SizedBox(height: 12),

              // Big, spaced, and tappable to copy — this gets read aloud
              // across a counter or typed into a till.
              InkWell(
                onTap: live
                    ? () {
                        Clipboard.setData(ClipboardData(text: code.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied.')),
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: live ? F4L.blend : null,
                    color: live
                        ? null
                        : Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(code.code,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5,
                            color: live ? Colors.white : mute)),
                  ),
                ),
              ),

              const SizedBox(height: 9),
              Row(children: [
                Icon(live ? Icons.storefront_outlined : Icons.check_circle,
                    size: 14, color: mute),
                const SizedBox(width: 6),
                Text(
                    live
                        ? 'Show at reception · tap to copy'
                        : 'Used ${code.usedAt == null ? '' : ''}',
                    style: TextStyle(fontSize: 12, color: mute)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
