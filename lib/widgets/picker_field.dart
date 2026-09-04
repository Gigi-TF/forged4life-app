import 'package:flutter/material.dart';

import '../theme/f4l_theme.dart';

/// A dropdown that opens a proper panel instead of a floating menu.
///
/// Two reasons this is not a `DropdownButtonFormField`:
///
/// The theme sets `canvasColor: Colors.transparent` so the mint backdrop can
/// show through every screen — and Material dropdown menus inherit that, so
/// their items paint straight over whatever is behind them with no surface.
///
/// And a fourteen-item menu floating over a form is hard to hit on a phone.
/// A sheet gives every option a full-width row, room for a description, and
/// a tick against the one already chosen.
class PickerField<T> extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.icon,
    this.title,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  /// Heading on the sheet. Falls back to the field label.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;
    final chosen = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
        ),

        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: items.isEmpty ? null : () => _open(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              border: Border.all(
                color: chosen != null
                    ? F4L.orange.withValues(alpha: 0.55)
                    : Theme.of(context).dividerColor,
                width: chosen != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: mute),
                const SizedBox(width: 11),
              ],
              Expanded(
                child: Text(
                  chosen == null ? hint : labelOf(chosen),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        chosen == null ? FontWeight.w400 : FontWeight.w600,
                    color: chosen == null
                        ? mute
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: mute),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      // An explicit surface, so it cannot inherit the transparent canvas.
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => _Sheet<T>(
        title: title ?? label,
        items: items,
        value: value,
        labelOf: labelOf,
      ),
    );

    if (picked != null) onChanged(picked);
  }
}

class _Sheet<T> extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.items,
    required this.value,
    required this.labelOf,
  });

  final String title;
  final List<T> items;
  final T? value;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodySmall?.color;

    return SafeArea(
      child: ConstrainedBox(
        // Never taller than two thirds — the sheet should read as a panel
        // over the form, not as a new screen.
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.66),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final on = item == value;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context, item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: on
                            ? F4L.orange.withValues(alpha: 0.08)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(labelOf(item),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    on ? FontWeight.w800 : FontWeight.w500,
                                color: on ? F4L.orange : null,
                              )),
                        ),
                        if (on)
                          const Icon(Icons.check_circle,
                              size: 20, color: F4L.orange)
                        else
                          Icon(Icons.chevron_right, size: 19, color: mute),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
