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

/// Surfaces with enough contrast to tell cards apart from the page outdoors.
extension AppSurfaces on ColorScheme {
  bool get _dark => brightness == Brightness.dark;

  /// Page background, slightly tinted so white cards stand out.
  Color get pageBackground => _dark ? surface : surfaceContainer;

  /// Cards and unselected option tiles.
  Color get tile => _dark ? surfaceContainerHigh : surfaceContainerLowest;

  Color get tileBorder =>
      _dark ? outlineVariant : outline.withValues(alpha: 0.35);
}

const cardRadius = BorderRadius.all(Radius.circular(20));

/// Padding of the scrolling pages (side margins, room below the last item).
const listPadding = EdgeInsets.fromLTRB(16, 0, 16, 24);

/// Shape for cards with their own fill colour, which need no outline.
const filledCardShape = RoundedRectangleBorder(borderRadius: cardRadius);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  var scheme = ColorScheme.fromSeed(
    seedColor: Palette.navy,
    brightness: brightness,
  );
  if (!dark) scheme = scheme.copyWith(primary: Palette.navy);

  return ThemeData(
    colorScheme: scheme,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: scheme.pageBackground,
    appBarTheme: AppBarTheme(
      // Taller than the default 56 so the times tab at the top clears the
      // titles.
      toolbarHeight: 72,
      backgroundColor: scheme.pageBackground,
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
      color: scheme.tile,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(color: scheme.tileBorder),
      ),
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
    // Outlined buttons sit on the page background, so they get the tile fill.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(backgroundColor: scheme.tile),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(scheme.tile),
      side: WidgetStatePropertyAll(BorderSide(color: scheme.tileBorder)),
    ),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: scheme.tile),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
