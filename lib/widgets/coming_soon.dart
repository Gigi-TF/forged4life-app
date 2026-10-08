import 'package:flutter/material.dart';

import '../services/features.dart';
import '../theme/f4l_theme.dart';

/// Wraps anything that is built but not yet live.
///
/// Greys it, blocks the tap, and says why. A disabled control with no
/// explanation reads as a broken app — someone taps twice, assumes it is
/// broken, and does not come back to it when it does work.
class ComingSoon extends StatelessWidget {
  const ComingSoon({
    super.key,
    required this.enabled,
    required this.child,
    this.label,
  });

  final bool enabled;
  final Widget child;

  /// Overrides the server's label where a feature needs its own wording.
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (enabled) return child;

    return Stack(children: [
      // IgnorePointer rather than removing the onTap: the row keeps its exact
      // layout, so nothing shifts when the feature goes live.
      Opacity(
        opacity: 0.42,
        child: IgnorePointer(child: child),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: SoonChip(label: label),
      ),
    ]);
  }
}

class SoonChip extends StatelessWidget {
  const SoonChip({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          (label ?? Features.instance.soonLabel).toUpperCase(),
          style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.amber),
        ),
      );
}

/// A full-width notice, for the top of a screen that is live but whose
/// contents are not — the rewards store, with earning on and spending off.
class SoonBanner extends StatelessWidget {
  const SoonBanner({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.09),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.schedule, size: 19, color: Colors.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(body,
                  style:
                      TextStyle(fontSize: 13, height: 1.55, color: mute)),
            ],
          ),
        ),
      ]),
    );
  }
}
