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
  });

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
        color: selected ? scheme.primary : scheme.tile,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
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
