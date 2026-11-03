import 'package:flutter/material.dart';

import 'burn/burn.dart';
import 'scores/score_store.dart';
import 'start/start.dart';
import 'theme.dart';
import 'ui/home_page.dart';

class EPHScoresApp extends StatelessWidget {
  const EPHScoresApp({
    super.key,
    required this.scores,
    required this.start,
    required this.burn,
  });

  final ScoreStore scores;
  final StartStore start;
  final BurnStore burn;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      scores: scores,
      start: start,
      burn: burn,
      child: MaterialApp(
        title: 'EPHScores',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        builder: phoneWidth,
        home: const HomePage(),
      ),
    );
  }
}

/// Keeps the phone layout on wide screens (desktop browsers, tablets).
Widget phoneWidth(BuildContext context, Widget? child) {
  return ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: child,
      ),
    ),
  );
}

/// Gives every page access to the app's stores.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.scores,
    required this.start,
    required this.burn,
    required super.child,
  });

  final ScoreStore scores;
  final StartStore start;
  final BurnStore burn;

  static AppScope of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      scores != oldWidget.scores ||
      start != oldWidget.start ||
      burn != oldWidget.burn;
}
