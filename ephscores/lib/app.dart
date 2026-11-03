import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'burn/burn.dart';
import 'patient/patient.dart';
import 'scores/score_store.dart';
import 'start/start.dart';
import 'theme.dart';
import 'ui/root_page.dart';

class EPHScoresApp extends StatelessWidget {
  const EPHScoresApp({
    super.key,
    required this.scores,
    required this.start,
    required this.burn,
    required this.patient,
  });

  final ScoreStore scores;
  final StartStore start;
  final BurnStore burn;
  final PatientStore patient;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      scores: scores,
      start: start,
      burn: burn,
      patient: patient,
      child: MaterialApp(
        title: 'EPHScores',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        // Portuguese for built-in widgets (licences page, tooltips).
        locale: const Locale('pt', 'PT'),
        supportedLocales: const [Locale('pt', 'PT')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: phoneWidth,
        home: const RootPage(),
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
    required this.patient,
    required super.child,
  });

  final ScoreStore scores;
  final StartStore start;
  final BurnStore burn;
  final PatientStore patient;

  static AppScope of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      scores != oldWidget.scores ||
      start != oldWidget.start ||
      burn != oldWidget.burn ||
      patient != oldWidget.patient;
}

/// Actions that span several stores.
extension PatientFlow on AppScope {
  /// Opens a new patient with empty scores and burns.
  void startPatient() {
    scores.resetAll();
    burn.clearAll();
    patient.start();
  }

  /// Forgets the patient and every answer, leaving nothing on the device.
  void discardPatient() {
    scores.resetAll();
    burn.clearAll();
    patient.clear();
  }

  /// Something has been assessed, so there is something to register.
  bool get canRegister => !scores.isEmpty || !burn.isEmpty;

  bool get hasUnsavedChanges =>
      patient.hasUnsavedChanges(scores.sheet, burn.sheet);

  /// Registers the current answers. They stay in place as the reference for
  /// the next evaluation.
  Evaluation registerEvaluation() => patient.register(scores.sheet, burn.sheet);
}
