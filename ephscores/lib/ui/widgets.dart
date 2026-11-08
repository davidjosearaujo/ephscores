import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../scores/model.dart';
import '../theme.dart';

/// Text that shrinks to fit the space it is given, instead of wrapping or
/// overflowing (labels on buttons and chips, large system fonts). It has no
/// maxLines on purpose: inside a FittedBox it can't wrap anyway, and setting
/// it changes the intrinsic height that pages like the start screen rely on.
class FitText extends StatelessWidget {
  const FitText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, style: style, textAlign: textAlign),
  );
}

/// Small rounded value chip. [compact] is the size used in the evolution
/// table; text that is still too wide scales down to fit.
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    required this.color,
    required this.onColor,
    this.compact = false,
  });

  final String text;
  final Color color;
  final Color onColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(minWidth: compact ? 48 : 64),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
      ),
      child: FitText(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 16 : 22,
          fontWeight: FontWeight.w700,
          color: onColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// A [Pill] showing a score value, coloured by its severity.
class ResultPill extends StatelessWidget {
  const ResultPill(this.result, {super.key, this.compact = false});

  final ScoreResult result;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Pill(
      result.display,
      color: Palette.severity(result.severity, scheme),
      onColor: Palette.onSeverity(result.severity, scheme),
      compact: compact,
    );
  }
}

/// A [Pill] showing a burned surface area.
class BurnPill extends StatelessWidget {
  const BurnPill(this.tbsa, {super.key, this.compact = false});

  final double tbsa;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Pill(
      formatPercent(tbsa),
      color: scheme.secondaryContainer,
      onColor: scheme.onSecondaryContainer,
      compact: compact,
    );
  }
}

/// A result shown on a tinted card: a score this one depends on, or the
/// shock index.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.result,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final ScoreResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: filledCardShape,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: ResultPill(result),
        onTap: onTap,
      ),
    );
  }
}

/// A tinted note with an icon: how a page works, or a hint to dismiss.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.icon,
    required this.text,
    this.onDismiss,
  });

  final IconData icon;

  /// Plain text or a [TextSpan] with bold parts.
  final InlineSpan text;

  /// Shows a close button when set.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSecondaryContainer;
    return Card(
      color: theme.colorScheme.secondaryContainer,
      shape: filledCardShape,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, onDismiss == null ? 16 : 4, 12),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Fechar',
                color: fg,
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }
}

/// Section heading used inside pages.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Asks for confirmation before a destructive action.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String action = 'Limpar',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Confirms a delete started by a long press, with a haptic tap first.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) {
  HapticFeedback.mediumImpact();
  return confirm(context, title: title, message: message, action: 'Apagar');
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}

/// Opens [page] on top of the current one.
Future<void> pushPage(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

/// Tappable tile used for every choice: filled when selected, outlined
/// otherwise. [builder] receives the foreground colour to draw with.
class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.selected,
    required this.onTap,
    required this.builder,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.color,
  });

  /// Fill when not selected, instead of the plain tile (e.g. amber when
  /// something is due).
  final Color? color;

  final bool selected;
  final VoidCallback onTap;
  final Widget Function(Color foreground) builder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(14);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primary : color ?? scheme.tile,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected || color != null
              ? BorderSide.none
              : BorderSide(color: scheme.tileBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: padding,
              child: builder(selected ? scheme.onPrimary : scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// A [SelectableTile] that is ticked on and off.
class CheckTile extends StatelessWidget {
  const CheckTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectableTile(
      selected: selected,
      onTap: onTap,
      builder: (fg) => Row(
        children: [
          Expanded(
            child: TileLabel(label, detail: detail, color: fg),
          ),
          if (selected) Icon(Icons.check, color: fg, size: 20),
        ],
      ),
    );
  }
}

/// The text of a [SelectableTile]: a label with an optional, smaller detail
/// line, in the tile's foreground colour.
class TileLabel extends StatelessWidget {
  const TileLabel(this.label, {super.key, this.detail, required this.color});

  final String label;
  final String? detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        if (detail != null)
          Text(
            detail!,
            style: TextStyle(
              fontSize: 13,
              color: color.withValues(alpha: 0.75),
            ),
          ),
      ],
    );
  }
}

/// The time [picked] on the clock, on the most recent day it isn't in the
/// future: a time later than now is taken as yesterday.
DateTime resolveClockTime(TimeOfDay picked, DateTime now) {
  final today = DateTime(
    now.year,
    now.month,
    now.day,
    picked.hour,
    picked.minute,
  );
  return today.isAfter(now) ? today.subtract(const Duration(days: 1)) : today;
}

/// Asks for a time of day, starting at [initial]; returns it on the most
/// recent day it isn't in the future (see [resolveClockTime]), or null if
/// cancelled.
Future<DateTime?> pickClockTime(
  BuildContext context, {
  required DateTime initial,
  required String title,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    helpText: title,
  );
  return picked == null ? null : resolveClockTime(picked, DateTime.now());
}

/// A time to register with one tap: "Registar" stamps now; once stamped,
/// tap to change it on the clock, ✕ to clear it.
class TimeStampTile extends StatelessWidget {
  const TimeStampTile({
    super.key,
    required this.label,
    required this.at,
    required this.onChanged,
    this.detail,
  });

  final String label;
  final String? detail;
  final DateTime? at;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _edit(BuildContext context, DateTime current) async {
    final picked = await pickClockTime(context, initial: current, title: label);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final at = this.at;
    return SelectableTile(
      selected: at != null,
      onTap: at == null
          ? () => onChanged(DateTime.now())
          : () => _edit(context, at),
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      builder: (fg) => Row(
        children: [
          Expanded(
            child: TileLabel(label, detail: detail, color: fg),
          ),
          if (at == null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                'Registar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            )
          else ...[
            Text(
              formatClock(at),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            IconButton(
              tooltip: 'Limpar $label',
              color: fg,
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close),
            ),
          ],
        ],
      ),
    );
  }
}

/// A coloured note: a flag in amber or red, or a grey reminder
/// ([Severity.incomplete]).
class FlagNote extends StatelessWidget {
  const FlagNote({
    super.key,
    required this.severity,
    required this.text,
    this.top = 8,
  });

  final Severity severity;
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Palette.severity(severity, scheme),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: severity == Severity.incomplete
                ? FontWeight.w500
                : FontWeight.w700,
            color: Palette.onSeverity(severity, scheme),
          ),
        ),
      ),
    );
  }
}

/// Bold heading above a question, field or group, with an optional grey
/// line under it and an optional marker at the right ("answered", ...).
class ItemHeader extends StatelessWidget {
  const ItemHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.top = 20,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double top;

  /// The tick shown when an item is answered or a group is met.
  static Widget done(BuildContext context) => Icon(
    Icons.check_circle,
    size: 20,
    color: Theme.of(context).colorScheme.primary,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, top, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (subtitle != null && subtitle.isNotEmpty)
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
