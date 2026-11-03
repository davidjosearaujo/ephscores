import 'package:flutter/material.dart';

import '../scores/model.dart';
import '../theme.dart';

/// Rounded, colour-coded pill showing a score value.
class ResultPill extends StatelessWidget {
  const ResultPill(this.result, {super.key, this.large = false});

  final ScoreResult result;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(minWidth: large ? 88 : 64),
      padding: EdgeInsets.symmetric(
        horizontal: large ? 18 : 12,
        vertical: large ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: Palette.severity(result.severity, scheme),
        borderRadius: BorderRadius.circular(large ? 20 : 14),
      ),
      child: Text(
        result.display,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: large ? 36 : 22,
          fontWeight: FontWeight.w700,
          color: Palette.onSeverity(result.severity, scheme),
          fontFeatures: const [FontFeature.tabularFigures()],
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
