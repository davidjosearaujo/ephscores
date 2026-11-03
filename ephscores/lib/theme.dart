import 'package:flutter/material.dart';

import 'scores/model.dart';

/// EPHScores brand colours.
abstract final class Palette {
  static const navy = Color(0xFF2C496C);
  static const green = Color(0xFF34A853);
  static const amber = Color(0xFFFBBC04);
  static const orange = Color(0xFFFF9933);
  static const red = Color(0xFFEA4335);
  static const black = Color(0xFF202124);

  static Color severity(Severity s, ColorScheme scheme) => switch (s) {
    Severity.ok => green,
    Severity.warning => amber,
    Severity.danger => red,
    Severity.incomplete => scheme.surfaceContainerHighest,
  };

  static Color onSeverity(Severity s, ColorScheme scheme) => switch (s) {
    Severity.warning => black,
    Severity.incomplete => scheme.onSurfaceVariant,
    _ => Colors.white,
  };
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  var scheme = ColorScheme.fromSeed(
    seedColor: Palette.navy,
    brightness: brightness,
  );
  if (!dark) scheme = scheme.copyWith(primary: Palette.navy);

  const radius = BorderRadius.all(Radius.circular(20));
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: dark ? scheme.onSurface : Palette.navy,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: dark ? scheme.onSurface : Palette.navy,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
