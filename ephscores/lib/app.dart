import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'burn/burn.dart';
import 'history/history.dart';
import 'history/unlock.dart';
import 'patient/patient.dart';
import 'scores/score_store.dart';
import 'start/start.dart';
import 'theme.dart';
import 'viaverde/via_verde.dart';
import 'ui/events_overlay.dart';
import 'ui/root_page.dart';

class EPHScoresApp extends StatelessWidget {
  EPHScoresApp({
    super.key,
    required this.scores,
    required this.start,
    required this.burn,
    required this.patient,
    HistoryStore? history,
    this.unlocker = const NoUnlocker(),
  }) : history = history ?? MemoryHistoryStore(available: false);

  final ScoreStore scores;
  final StartStore start;
  final BurnStore burn;
  final PatientStore patient;
  final HistoryStore history;
  final Unlocker unlocker;

  /// Lets the occurrence-times bubble, which floats above every page, open
  /// its panel on the navigator and step aside while a dialog is shown.
  final navigatorKey = GlobalKey<NavigatorState>();
  final popups = PopupTracker();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      scores: scores,
      start: start,
      burn: burn,
      patient: patient,
      history: history,
      unlocker: unlocker,
      child: MaterialApp(
        title: 'EPHScores',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        // Portuguese for built-in widgets (licences page, tooltips).
        locale: const Locale('pt', 'PT'),
        supportedLocales: const [Locale('pt', 'PT')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        navigatorKey: navigatorKey,
        navigatorObservers: [popups],
        builder: (context, child) => phoneWidth(
          context,
          Stack(
            fit: StackFit.expand,
            children: [
              child!,
              EventsBubble(navigatorKey: navigatorKey, popups: popups),
            ],
          ),
        ),
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
  AppScope({
    super.key,
    required this.scores,
    required this.start,
    required this.burn,
    required this.patient,
    required this.history,
    required this.unlocker,
    required super.child,
  });

  final ScoreStore scores;
  final StartStore start;
  final BurnStore burn;
  final PatientStore patient;

  /// Finished patients (encrypted, Android only).
  final HistoryStore history;

  /// Asks for the phone's screen lock before the history is shown.
  final Unlocker unlocker;

  /// Fires on any change to the patient, the live answers or the burn map.
  /// Created once, so builders listening to it don't re-subscribe each build.
  late final Listenable patientState = Listenable.merge([
    scores,
    burn,
    patient,
  ]);

  static AppScope of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      scores != oldWidget.scores ||
      start != oldWidget.start ||
      burn != oldWidget.burn ||
      patient != oldWidget.patient ||
      history != oldWidget.history ||
      unlocker != oldWidget.unlocker;
}

/// Actions that span several stores.
extension PatientFlow on AppScope {
  /// Opens a new patient with empty scores and burns.
  void startPatient() {
    scores.resetAll();
    burn.clearAll();
    patient.start();
  }

  /// Finishes the patient and keeps it in the history.
  void finishPatient() {
    patient.finish();
    history.save(patient);
  }

  /// Deletes an evaluation; a finished patient's history copy follows.
  void removeEvaluation(int index) {
    patient.removeAt(index);
    if (patient.isFinished) history.save(patient);
  }

  /// Forgets the patient and every answer, leaving nothing on the device:
  /// a finished one is deleted from the history too.
  void discardPatient() {
    if (patient.isFinished) {
      history.delete(patient.startedAt!.millisecondsSinceEpoch);
    }
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

  /// The live answers, vital signs, burns, onset and ticked criteria.
  ClinicalState clinicalState({DateTime? now}) => ClinicalState(
    scores: scores.sheet,
    burns: burn.sheet,
    onset: patient.onset,
    checks: patient.checks,
    now: now ?? DateTime.now(),
  );
}
