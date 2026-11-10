import 'package:ephscores/app.dart';
import 'package:ephscores/burn/burn.dart';
import 'package:ephscores/history/history.dart';
import 'package:ephscores/platform/android.dart';
import 'package:ephscores/history/unlock.dart';
import 'package:ephscores/ui/history_page.dart';
import 'package:ephscores/patient/chamu.dart';
import 'package:ephscores/patient/patient.dart';
import 'package:ephscores/scores/adult.dart';
import 'package:ephscores/scores/score_store.dart';
import 'package:ephscores/start/start.dart';
import 'package:ephscores/ui/burn_page.dart';
import 'package:ephscores/ui/contacts_page.dart';
import 'package:ephscores/ui/dashboard_page.dart';
import 'package:ephscores/ui/events_overlay.dart';
import 'package:ephscores/ui/evolution_page.dart';
import 'package:ephscores/ui/score_list_page.dart';
import 'package:ephscores/ui/score_page.dart';
import 'package:ephscores/ui/start_page.dart';
import 'package:ephscores/ui/via_verde_page.dart';
import 'package:ephscores/ui/widgets.dart' show ChoiceField;
import 'package:ephscores/ui/vitals_page.dart';
import 'package:ephscores/ui/welcome_page.dart';
import 'package:ephscores/viaverde/via_verde.dart';
import 'package:ephscores/vitals/vitals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phone-sized viewport (360x780 logical pixels). By default a patient is
/// already open, so the app starts on the dashboard.
Future<EPHScoresApp> buildApp(
  WidgetTester tester, {
  bool openPatient = true,
  HistoryStore? history,
  Unlocker unlocker = const NoUnlocker(),
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final patient = PatientStore(prefs);
  if (openPatient) patient.start();
  return EPHScoresApp(
    scores: ScoreStore(prefs),
    start: StartStore(prefs),
    burn: BurnStore(prefs),
    patient: patient,
    history: history,
    unlocker: unlocker,
  );
}

/// Three evaluations: GCS 15, then 14 with a burn, then 9, with vital
/// signs and a symptom onset.
void seedEvaluations(EPHScoresApp app) {
  void pick(int eyes, int verbal, int motor) {
    for (final (item, i) in [
      (gcs.items[0], eyes),
      (gcs.items[1], verbal),
      (gcs.items[2], motor),
    ]) {
      if (!app.scores.answersFor('gcs').of(item.id).contains(i)) {
        app.scores.toggle('gcs', item, i);
      }
    }
  }

  final base = app.patient.startedAt!;
  app.patient.onset = Onset(base.subtract(const Duration(minutes: 20)));
  for (final (v, n) in [
    (Vital.age, 64),
    (Vital.avds, 0),
    (Vital.rr, 24),
    (Vital.spo2, 93),
    (Vital.o2, 0),
    (Vital.hr, 118),
    (Vital.sbp, 98),
    (Vital.dbp, 61),
    (Vital.temp, 38.6),
    (Vital.pain, 7),
    (Vital.glucose, 54),
  ]) {
    app.scores.setVital(v, n);
  }
  app.patient.toggleCheck('sepsis.urinary');
  pick(0, 0, 0);
  app.patient.register(
    app.scores.sheet,
    app.burn.sheet,
    at: base.add(const Duration(minutes: 2)),
  );
  pick(0, 1, 0);
  app.burn.paint(app.burn.regions[1], BurnDegree.second);
  app.patient.register(
    app.scores.sheet,
    app.burn.sheet,
    at: base.add(const Duration(minutes: 9)),
  );
  pick(1, 2, 1);
  app.patient.register(
    app.scores.sheet,
    app.burn.sheet,
    at: base.add(const Duration(minutes: 15)),
  );
}

/// The scrollable of the page on top (pages underneath stay mounted).
final pageScrollable = find.byType(Scrollable).last;

/// Taps a home-screen entry, scrolling to it first on short screens.
Future<void> openFromHome(WidgetTester tester, String label) async {
  // Centred on screen before tapping.
  await Scrollable.ensureVisible(
    tester.element(find.text(label)),
    alignment: 0.5,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
}

void main() {
  group('large text', largeTextTests);

  testWidgets('scoring GCS updates the result bar and the list', (
    tester,
  ) async {
    await tester.pumpWidget(await buildApp(tester));
    await openFromHome(tester, 'Escalas gerais');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ECG'));
    await tester.pumpAndSettle();

    expect(find.text('Faltam 3 de 3'), findsOneWidget);
    await tester.tap(find.text('Espontânea'));
    await tester.tap(find.text('Orientada'));
    await tester.scrollUntilVisible(
      find.text('Obedece a ordens'),
      100,
      scrollable: pageScrollable,
    );
    await tester.ensureVisible(find.text('Obedece a ordens'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Obedece a ordens'));
    await tester.pump();
    expect(find.text('Ligeiro'), findsOneWidget);
    expect(find.text('O4 V5 M6'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Ligeiro'), findsOneWidget);
  });

  testWidgets('START flow records a victim', (tester) async {
    final app = await buildApp(tester, openPatient: false);
    await tester.pumpWidget(app);
    await openFromHome(tester, 'Triagem START');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Não')); // walks?
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não')); // breathes?
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim')); // after airway?
    await tester.pumpAndSettle();
    expect(find.text('Emergente'), findsOneWidget);
    await tester.tap(find.text('Registar vítima'));
    await tester.pumpAndSettle();
    expect(app.start.count(StartCategory.p1), 1);
    expect(find.text('Caminha?'), findsOneWidget);
  });

  testWidgets('tapping the body diagram paints a region', (tester) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await openFromHome(tester, 'Avaliação do queimado');
    await tester.pumpAndSettle();

    final diagram = find
        .byType(CustomPaint)
        .evaluate()
        .map((e) => e.renderObject! as RenderBox)
        .firstWhere((b) => b.size.height > 200 && b.size.height > b.size.width);
    // Centre of the chest in the front view: canvas (100, 110) of 200x440.
    final origin = diagram.localToGlobal(Offset.zero);
    final scale = diagram.size.width / 200;
    await tester.tapAt(origin + const Offset(100, 110) * scale);
    await tester.pump();
    expect(app.burn.tbsa, 9);
    await tester.scrollUntilVisible(
      find.text('Tórax'),
      100,
      scrollable: pageScrollable,
    );
    expect(find.text('Tórax'), findsOneWidget);
  });

  testWidgets('a patient from start to summary', (tester) async {
    final app = await buildApp(tester, openPatient: false);
    await tester.pumpWidget(app);

    await tester.tap(find.text('Novo doente'));
    await tester.pumpAndSettle();
    expect(app.patient.isActive, isTrue);
    expect(find.text('Doente em avaliação'), findsOneWidget);
    // Nothing assessed yet, and no evaluation to finish.
    final register = find.widgetWithText(FilledButton, 'Registar');
    expect(tester.widget<FilledButton>(register).onPressed, isNull);
    expect(find.text('Finalizar'), findsNothing);

    // Assess GCS 15 and register it.
    for (final item in gcs.items) {
      app.scores.toggle('gcs', item, 0);
    }
    await tester.pump();
    await tester.tap(register);
    await tester.pump();
    expect(find.textContaining('Avaliação 1 registada'), findsOneWidget);
    expect(app.patient.evaluations, hasLength(1));
    // The answers stay as the reference for the next evaluation.
    expect(app.scores.resultFor('gcs').value, 15);
    await tester.pumpAndSettle();

    // Change one answer, then finish: offered to register it first.
    app.scores.toggle('gcs', gcs.items[1], 1);
    await tester.pump();
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Registar a avaliação atual'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Registar').last);
    await tester.pumpAndSettle();

    expect(app.patient.isFinished, isTrue);
    expect(app.patient.evaluations, hasLength(2));
    expect(find.text('Evolução'), findsOneWidget);
    expect(find.text('Finalizado'), findsOneWidget);
    expect(find.textContaining('Avaliação 2 ·'), findsOneWidget);

    String? shared;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        if (call.method == 'share') {
          shared = (call.arguments as Map)['text'] as String;
        }
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    await tester.tap(find.text('Partilhar resumo (ISBAR)'));
    await tester.pump();
    final copied = shared;
    expect(copied, startsWith('EPHScores — resumo ISBAR'));
    expect(copied, contains('A — Avaliação\n- Avaliação 2'));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Último doente'), findsOneWidget);
  });

  testWidgets('copies the summary where sharing is not possible', (
    tester,
  ) async {
    final app = await buildApp(tester);
    seedEvaluations(app);
    await tester.pumpWidget(app);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async => throw PlatformException(code: 'unavailable'),
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await tester.tap(find.text('Evolução (3)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partilhar resumo (ISBAR)'));
    await tester.pumpAndSettle();
    expect(copied, startsWith('EPHScores — resumo ISBAR'));
    expect(find.text('Resumo copiado'), findsOneWidget);
  });

  group('history', () {
    Future<EPHScoresApp> finishedApp(
      WidgetTester tester, {
      Unlocker unlocker = const NoUnlocker(),
    }) async {
      final app = await buildApp(
        tester,
        history: MemoryHistoryStore(),
        unlocker: unlocker,
      );
      seedEvaluations(app);
      AppScope(
        scores: app.scores,
        start: app.start,
        burn: app.burn,
        patient: app.patient,
        history: app.history,
        unlocker: app.unlocker,
        child: const SizedBox(),
      ).finishPatient();
      await tester.pumpWidget(app);
      return app;
    }

    testWidgets('a finished patient is kept and opens read-only', (
      tester,
    ) async {
      final app = await finishedApp(tester);
      expect(await app.history.entries(), hasLength(1));
      // Starting the next patient doesn't ask: the last one is kept.
      await tester.tap(find.text('Novo doente'));
      await tester.pumpAndSettle();
      expect(app.patient.isActive, isTrue);
      expect(await app.history.entries(), hasLength(1));
      app.patient.clear();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 avaliações'), findsOneWidget);
      await tester.tap(find.textContaining('3 avaliações'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Doente de '), findsOneWidget);
      expect(find.textContaining('Guardado até'), findsOneWidget);
      expect(find.text('Partilhar resumo (ISBAR)'), findsOneWidget);
      // Read-only: no deleting evaluations.
      expect(find.textContaining('Mantenha premida'), findsNothing);
    });

    testWidgets('going to the background locks it and closes the patient', (
      tester,
    ) async {
      await finishedApp(tester);
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('3 avaliações'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      // The very first frame back shows the lock, not the patient.
      await tester.pump();
      expect(find.textContaining('Doente de '), findsNothing);
      expect(find.text('O histórico está bloqueado.'), findsOneWidget);
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 avaliações'), findsOneWidget);
    });

    testWidgets('screenshots are blocked only while it is open', (
      tester,
    ) async {
      final calls = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        androidChannel,
        (call) async =>
            call.method == 'takeShortcut' ? null : calls.add(call.arguments),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          androidChannel,
          null,
        ),
      );
      await finishedApp(tester);
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(calls, [true]);
      await tester.tap(find.textContaining('3 avaliações'));
      await tester.pumpAndSettle();
      expect(calls, [true]);
      // The Android back button, twice.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(calls, [true, false]);
    });

    testWidgets('a failed unlock shows nothing', (tester) async {
      await finishedApp(
        tester,
        unlocker: const NoUnlocker(UnlockResult.failed),
      );
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(find.text('O histórico está bloqueado.'), findsOneWidget);
      expect(find.textContaining('avaliações'), findsNothing);
    });

    testWidgets('without a screen lock it explains why', (tester) async {
      await finishedApp(
        tester,
        unlocker: const NoUnlocker(UnlockResult.noLock),
      );
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(find.textContaining('bloqueio de ecrã'), findsOneWidget);
    });

    testWidgets('deleting the last patient deletes it from the history', (
      tester,
    ) async {
      final app = await finishedApp(tester);
      await tester.longPress(find.text('Último doente'));
      await tester.pumpAndSettle();
      expect(find.textContaining('também do histórico'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Apagar'));
      await tester.pumpAndSettle();
      expect(await app.history.entries(), isEmpty);
    });

    testWidgets('no history button where there is no history', (tester) async {
      final app = await buildApp(tester, openPatient: false);
      await tester.pumpWidget(app);
      expect(find.text('Histórico'), findsNothing);
      expect(app.history.available, isFalse);
    });
  });

  testWidgets('pregnancy and birth, with the screen kept on', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      androidChannel,
      (call) async => call.method == 'takeShortcut'
          ? null
          : calls.add('${call.method} ${call.arguments}'),
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        androidChannel,
        null,
      ),
    );
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await openFromHome(tester, 'Grávida e parto');
    await tester.pumpAndSettle();
    expect(calls, ['keepScreenOn true']);
    await tester.tap(find.text('Doente grávida'));
    await tester.pumpAndSettle();
    expect(find.text('NEWS2 não validada na gravidez'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Nascimento'),
      300,
      scrollable: pageScrollable,
    );
    await tester.tap(find.text('Nascimento'));
    await tester.pumpAndSettle();
    expect(app.patient.pregnancy!.birth, isNotNull);
    await tester.scrollUntilVisible(
      find.text('APGAR ao 1.º minuto'),
      300,
      scrollable: pageScrollable,
    );
    expect(find.textContaining('faltam'), findsWidgets);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(calls.last, 'keepScreenOn false');
    expect(find.textContaining('Grávida · Nascimento'), findsOneWidget);
  });

  testWidgets('the re-assessment reminder, reset by each evaluation', (
    tester,
  ) async {
    final app = await buildApp(tester);
    app.patient.reminderMinutes = 10;
    await tester.pumpWidget(app);
    await tester.pump(const Duration(minutes: 9));
    expect(find.textContaining('Reavaliar o doente'), findsNothing);

    // Registering starts the count again.
    app.patient.register(app.scores.sheet, app.burn.sheet);
    await tester.pump(const Duration(minutes: 9));
    expect(find.textContaining('Reavaliar o doente'), findsNothing);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(find.textContaining('Reavaliar o doente'), findsOneWidget);

    // No reminder once it is off.
    app.patient.reminderMinutes = null;
    await tester.pump(const Duration(minutes: 30));
    expect(find.textContaining('Reavaliar o doente'), findsOneWidget);
  });

  testWidgets('choosing the reminder on the dashboard', (tester) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await tester.tap(find.byTooltip('Lembrete de reavaliação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reavaliar a cada 15 min'));
    await tester.pumpAndSettle();
    expect(app.patient.reminderMinutes, 15);
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    // Kept with the patient, and gone with the next one.
    expect(
      PatientStore(await SharedPreferences.getInstance()).reminderMinutes,
      15,
    );
    app.patient.start();
    expect(app.patient.reminderMinutes, isNull);
  });

  group('launcher shortcuts', () {
    void mockLaunch(WidgetTester tester, String? shortcut) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        androidChannel,
        (call) async => call.method == 'takeShortcut' ? shortcut : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          androidChannel,
          null,
        ),
      );
    }

    testWidgets('"Novo doente" starts one from the start screen', (
      tester,
    ) async {
      mockLaunch(tester, 'new_patient');
      final app = await buildApp(tester, openPatient: false);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(app.patient.isActive, isTrue);
      expect(find.text('Sinais vitais'), findsOneWidget);
    });

    testWidgets('"Novo doente" leaves a patient in progress alone', (
      tester,
    ) async {
      mockLaunch(tester, 'new_patient');
      final app = await buildApp(tester);
      final started = app.patient.startedAt;
      app.patient.reminderMinutes = 5;
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(app.patient.startedAt, started);
      expect(app.patient.reminderMinutes, 5);
    });

    testWidgets('"Contactos" and "Triagem START" open their pages, also while '
        'the app is running', (tester) async {
      mockLaunch(tester, 'contacts');
      final app = await buildApp(tester, openPatient: false);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.byType(ContactsPage), findsOneWidget);

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        androidChannel.name,
        androidChannel.codec.encodeMethodCall(
          const MethodCall('shortcut', 'start'),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(find.byType(StartPage), findsOneWidget);
      expect(find.byType(ContactsPage), findsNothing);
    });
  });

  testWidgets('a child\'s estimated weight shows with the age', (tester) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await openFromHome(tester, 'Sinais vitais');
    expect(find.textContaining('Peso estimado'), findsNothing);
    app.scores.setVital(Vital.age, 5);
    await tester.pumpAndSettle();
    expect(
      find.text('Peso estimado: cerca de 18 kg (fórmulas APLS)'),
      findsOneWidget,
    );
    app.scores.setVital(Vital.age, 40);
    await tester.pumpAndSettle();
    expect(find.textContaining('Peso estimado'), findsNothing);
  });

  testWidgets('CHAMU: dropdowns, a text area for "Outra", medication as text', (
    tester,
  ) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await openFromHome(tester, 'CHAMU');
    await tester.pumpAndSettle();

    // Circumstances: one choice; the text area opens only for "Outra".
    expect(find.text('Descreva a situação'), findsNothing);
    await tester.tap(find.byType(ChoiceField).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Queda'));
    await tester.pumpAndSettle();
    expect(find.text('Queda'), findsOneWidget);
    expect(find.text('Descreva a situação'), findsNothing);

    await tester.tap(find.text('Queda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outra'));
    await tester.pumpAndSettle();
    expect(find.text('Descreva a situação'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'caiu da bicicleta');
    expect(
      app.patient.chamu.lineFor(chamuQuestions.first),
      'Outra: caiu da bicicleta',
    );

    // Allergies: several at once, kept open until "Concluído".
    await tester.scrollUntilVisible(
      find.text('A · Alergias'),
      300,
      scrollable: pageScrollable,
    );
    // Circumstances, antecedents, allergies.
    await tester.tap(find.byType(ChoiceField).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alimentos'));
    await tester.pump();
    await tester.tap(find.text('Látex'));
    await tester.pump();
    await tester.tap(find.text('Concluído'));
    await tester.pumpAndSettle();
    expect(find.text('Alimentos, Látex'), findsOneWidget);
    expect(find.text('A quê'), findsOneWidget);

    // Medication is only a text area.
    await tester.scrollUntilVisible(
      find.text('Nomes dos medicamentos'),
      300,
      scrollable: pageScrollable,
    );
    await tester.enterText(
      find.widgetWithText(TextField, '').last,
      'Varfarina',
    );
    expect(app.patient.chamu.note('m'), 'Varfarina');
  });

  testWidgets('cancelling a patient with no evaluations', (tester) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await tester.tap(find.text('Evolução'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar doente'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar doente'));
    await tester.pumpAndSettle();
    expect(app.patient.startedAt, isNull);
    expect(find.text('Novo doente'), findsOneWidget);
  });

  testWidgets('long-pressing "Último doente" deletes it', (tester) async {
    final app = await buildApp(tester);
    seedEvaluations(app);
    app.patient.finish();
    await tester.pumpWidget(app);
    expect(find.text('Último doente'), findsOneWidget);

    await tester.longPress(find.text('Último doente'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apagar'));
    await tester.pumpAndSettle();

    expect(find.text('Último doente'), findsNothing);
    expect(app.patient.startedAt, isNull);
    // Nothing about the patient is left behind.
    expect((app.scores.isEmpty, app.burn.isEmpty), (true, true));
  });

  testWidgets('info dialog shows the pubspec metadata', (tester) async {
    await tester.pumpWidget(await buildApp(tester, openPatient: false));
    await tester.tap(find.byTooltip('Informação'));
    await tester.pumpAndSettle();
    expect(find.text('com.davidaraujo.ephscores'), findsOneWidget);
    expect(find.text('David Araújo'), findsOneWidget);
    expect(
      find.text('https://codeberg.org/davidjosearaujo/ephscores'),
      findsOneWidget,
    );
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('https://ephscores-7e4eb.web.app'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^\d+\.\d+\.\d+ \(\d+\)$')),
      findsOneWidget,
    );
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Pacote'), findsNothing);
  });

  testWidgets('long-pressing an evaluation deletes it', (tester) async {
    final app = await buildApp(tester);
    seedEvaluations(app);
    await tester.pumpWidget(app);
    await tester.tap(find.text('Evolução (3)'));
    await tester.pumpAndSettle();

    final second = find.textContaining('Avaliação 2 ·');
    // The page's own vertical list (the trend table scrolls sideways).
    final page = find
        .descendant(
          of: find.byType(EvolutionPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(second, 100, scrollable: page);
    await tester.ensureVisible(second);
    await tester.pumpAndSettle();
    await tester.longPress(second);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apagar'));
    await tester.pumpAndSettle();

    expect(app.patient.evaluations, hasLength(2));
    // Evaluations are renumbered: the old third is now the second.
    expect(find.textContaining('Avaliação 3 ·'), findsNothing);
  });

  testWidgets('a vital sign typed once fills NEWS2', (tester) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await openFromHome(tester, 'Sinais vitais');
    await tester.pumpAndSettle();
    final vitalsList = find
        .descendant(
          of: find.byType(VitalsPage),
          matching: find.byType(Scrollable),
        )
        .first;

    final hr = find.ancestor(
      of: find.text('bpm'),
      matching: find.byType(TextField),
    );
    await tester.scrollUntilVisible(hr, 100, scrollable: vitalsList);
    await tester.ensureVisible(hr);
    await tester.pumpAndSettle();
    await tester.enterText(hr, '135');
    await tester.pump();
    expect(app.scores.vitals[Vital.hr], 135);

    // Out of range: not stored, and flagged once the field is left.
    await tester.enterText(hr, '999');
    await tester.pump();
    expect(app.scores.vitals[Vital.hr], isNull);
    await tester.enterText(hr, '135');
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('1 registado'), findsOneWidget);
    await openFromHome(tester, 'Escalas gerais');
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEWS2'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dos sinais vitais: FC 135 bpm'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(ScorePage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(app.scores.resultFor('news2').answered, 1);
  });

  testWidgets('"next" on the keyboard goes to the next number field', (
    tester,
  ) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await openFromHome(tester, 'Sinais vitais');
    await tester.pumpAndSettle();
    final fields = find.byType(EditableText);
    await tester.tap(fields.at(0)); // Idade
    await tester.enterText(fields.at(0), '70');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    // Skips the AVDS tiles: the respiratory rate field has the focus.
    expect(
      tester.widget<EditableText>(fields.at(1)).focusNode.hasFocus,
      isTrue,
    );
    expect(app.scores.vitals[Vital.avds], isNull);
  });

  testWidgets('tapping a face records the pain', (tester) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await openFromHome(tester, 'Sinais vitais');
    await tester.pumpAndSettle();
    final face = find.bySemanticsLabel('6, Bastante dor');
    await tester.scrollUntilVisible(
      face,
      100,
      scrollable: find
          .descendant(
            of: find.byType(VitalsPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(face);
    await tester.pumpAndSettle();
    await tester.tap(face);
    await tester.pump();
    expect(app.scores.vitals[Vital.pain], 6);
    expect(app.scores.vitals.painFaces, isTrue);
    expect(find.text('Bastante dor'), findsOneWidget);
    // The number field shows it too.
    expect(find.widgetWithText(TextField, '6'), findsOneWidget);
  });

  testWidgets('Vias Verdes: onset now and a ticked criterion', (tester) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await openFromHome(tester, 'Vias Verdes');
    await tester.pumpAndSettle();
    final list = find
        .descendant(
          of: find.byType(ViaVerdePage),
          matching: find.byType(Scrollable),
        )
        .first;
    Future<void> show(String text) async {
      await tester.scrollUntilVisible(find.text(text), 100, scrollable: list);
      await tester.ensureVisible(find.text(text));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Agora'));
    await tester.pumpAndSettle();
    expect(app.patient.onset, isNotNull);
    expect(find.text('Hora exata'), findsOneWidget);

    await show('Via Verde Trauma');
    await tester.tap(find.text('Via Verde Trauma'));
    await tester.pumpAndSettle();
    await show('Queda superior a 6 metros');
    await tester.tap(find.text('Queda superior a 6 metros'));
    await tester.pumpAndSettle();
    expect(app.patient.checks, {'trauma.fall'});
    expect(
      viaVerdeTrauma
          .check(
            ClinicalState(
              scores: app.scores.sheet,
              burns: app.burn.sheet,
              checks: app.patient.checks,
              now: DateTime.now(),
            ),
          )
          .result
          .label,
      'Critérios cumpridos: contactar CODU',
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Critérios: Trauma'), findsOneWidget);
  });

  testWidgets('the times bubble opens the panel from any page', (tester) async {
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    final bubble = find.bySemanticsLabel(RegExp('^Horas da ocorrência, '));
    expect(bubble, findsOneWidget);

    // On a page deeper in the app too.
    await openFromHome(tester, 'Sinais vitais');
    await tester.pumpAndSettle();
    await tester.tap(bubble);
    await tester.pumpAndSettle();
    expect(find.byType(EventsPanel), findsOneWidget);
    // The bubble stays in view, with the panel pointing at it.
    expect(bubble, findsOneWidget);

    await tester.tap(find.text('Chegada à vítima'));
    await tester.pump();
    expect(app.patient.events.keys, [PatientEvent.atVictim]);
    await tester.tap(find.byTooltip('Limpar Chegada à vítima'));
    await tester.pump();
    expect(app.patient.events, isEmpty);
    await tester.tap(find.text('Contacto CODU'));
    await tester.pump();

    // Tapping outside puts it away; so does tapping the bubble again.
    await tester.tapAt(const Offset(20, 770));
    await tester.pumpAndSettle();
    expect(find.byType(EventsPanel), findsNothing);
    await tester.tap(bubble);
    await tester.pumpAndSettle();
    await tester.tap(bubble);
    await tester.pumpAndSettle();
    expect(find.byType(EventsPanel), findsNothing);
    expect(
      find.bySemanticsLabel('Horas da ocorrência, 1 registadas'),
      findsOneWidget,
    );
  });

  group('times panel placement', () {
    const top = 20.0, bottom = 760.0;
    Rect bubble(double y) => Rect.fromLTWH(300, y, 52, 52);

    test('below when it fits there', () {
      final p = placePanel(
        anchor: bubble(100),
        height: 400,
        top: top,
        bottom: bottom,
      );
      expect(p, (bubbleTop: 100.0, above: false));
    });
    test('above when only that side fits', () {
      final p = placePanel(
        anchor: bubble(600),
        height: 400,
        top: top,
        bottom: bottom,
      );
      expect(p, (bubbleTop: 600.0, above: true));
    });
    test('otherwise the bubble moves the shortest way', () {
      // 500 tall: fits below only if the bubble rises to 204, above only if
      // it drops to 524. From 300, rising is shorter.
      expect(
        placePanel(anchor: bubble(300), height: 500, top: top, bottom: bottom),
        (bubbleTop: 204.0, above: false),
      );
      // From 450, dropping is shorter.
      expect(
        placePanel(anchor: bubble(450), height: 500, top: top, bottom: bottom),
        (bubbleTop: 524.0, above: true),
      );
    });
    test('taller than the screen: bubble at the bottom, panel above', () {
      final p = placePanel(
        anchor: bubble(300),
        height: 900,
        top: top,
        bottom: bottom,
      );
      expect(p, (bubbleTop: 708.0, above: true));
    });
  });

  Future<(Rect, Rect)> openPanel(WidgetTester tester, Finder bubble) async {
    await tester.tap(bubble);
    await tester.pumpAndSettle();
    return (tester.getRect(bubble), tester.getRect(find.byType(EventsPanel)));
  }

  testWidgets('the panel opens below a bubble near the top', (tester) async {
    await tester.pumpWidget(await buildApp(tester));
    final bubble = find.bySemanticsLabel(RegExp('^Horas da ocorrência, '));
    await tester.drag(bubble, const Offset(0, -600));
    await tester.pumpAndSettle();
    final before = tester.getRect(bubble);
    final (at, panel) = await openPanel(tester, bubble);
    // The bubble stays put; the whole panel is below it, on screen.
    expect(at, before);
    expect(panel.top, greaterThanOrEqualTo(at.bottom));
    expect(panel.bottom, lessThanOrEqualTo(780));
  });

  testWidgets('the panel opens above a bubble near the bottom', (tester) async {
    await tester.pumpWidget(await buildApp(tester));
    final bubble = find.bySemanticsLabel(RegExp('^Horas da ocorrência, '));
    await tester.drag(bubble, const Offset(0, 300));
    await tester.pumpAndSettle();
    final before = tester.getRect(bubble);
    final (at, panel) = await openPanel(tester, bubble);
    expect(at, before);
    expect(panel.bottom, lessThanOrEqualTo(at.top));
    expect(panel.top, greaterThanOrEqualTo(0));
    // Back in place, and still there, once it closes.
    await tester.tap(bubble);
    await tester.pumpAndSettle();
    expect(tester.getRect(bubble), before);
  });

  testWidgets('the bubble can be dragged to the other side', (tester) async {
    await tester.pumpWidget(await buildApp(tester));
    final bubble = find.bySemanticsLabel(RegExp('^Horas da ocorrência, '));
    expect(tester.getCenter(bubble).dx, greaterThan(300));
    await tester.drag(bubble, const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(tester.getCenter(bubble).dx, lessThan(60));
  });

  testWidgets('no times bubble without an open patient', (tester) async {
    await tester.pumpWidget(await buildApp(tester, openPatient: false));
    expect(
      find.bySemanticsLabel(RegExp('^Horas da ocorrência, ')),
      findsNothing,
    );
  });

  testWidgets('RACE 5 or more offers the Via Verde AVC', (tester) async {
    final app = await buildApp(tester);
    void set(String id, String label) {
      final item = race.items.firstWhere((i) => i.id == id);
      app.scores.toggle(
        'race',
        item,
        item.options.indexWhere((o) => o.label == label),
      );
    }

    set('side', 'Direito');
    set('face', 'Moderada a grave');
    set('arm', 'Grave');
    set('leg', 'Ausente ou ligeira');
    set('gaze', 'Ausente');
    await tester.pumpWidget(app);
    await openFromHome(tester, 'Escalas gerais');
    await tester.pumpAndSettle();
    await tester.tap(find.text('RACE'));
    await tester.pumpAndSettle();
    final last = find.text('Não cumpre ordens');
    await tester.scrollUntilVisible(
      last,
      100,
      scrollable: find
          .descendant(
            of: find.byType(ScorePage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    await tester.tap(last);
    await tester.pump();
    expect(app.scores.resultFor('race').value, 6);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Oclusão de grande vaso?'),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Via Verde AVC'));
    await tester.pumpAndSettle();
    expect(find.byType(ViaVerdePage), findsOneWidget);
  });

  testWidgets('trend names stay put while the values scroll', (tester) async {
    final app = await buildApp(tester);
    for (var i = 0; i < 12; i++) {
      app.scores.toggle('gcs', gcs.items[0], i.isEven ? 0 : 1);
      app.patient.register(
        app.scores.sheet,
        app.burn.sheet,
        at: app.patient.startedAt!.add(Duration(minutes: i + 1)),
      );
    }
    await tester.pumpWidget(app);
    await tester.tap(find.text('Evolução (12)'));
    await tester.pumpAndSettle();

    final name = find.text('ECG').first;
    final first = find.text('#1');
    final nameX = tester.getTopLeft(name).dx;
    final firstX = tester.getTopLeft(first).dx;
    // Newest in view first: #1 starts scrolled off to the left.
    expect(firstX, lessThan(nameX));

    await tester.drag(find.text('#12'), const Offset(2000, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(name).dx, nameX);
    expect(tester.getTopLeft(first).dx, greaterThan(nameX));
  });
}

/// Layout overflows throw in tests, so rendering is enough to catch them.
void largeTextTests() {
  final pages = <String, Widget Function()>{
    'welcome': () => const WelcomePage(),
    'dashboard': () => const DashboardPage(),
    'evolution': () => const EvolutionPage(),
    'adult list': () =>
        ScoreListPage(title: 'Escalas gerais', scores: adultScores),
    for (final s in allScores.values)
      'score ${s.id}': () => ScorePage(score: s),
    'burn': () => const BurnPage(),
    'start': () => const StartPage(),
    'contacts': () => const ContactsPage(),
    'vitals': () => const VitalsPage(),
    'vias verdes': () => const ViaVerdePage(),
    'events panel': () => const EventsPanel(),
    'history': () => const HistoryPage(),
  };
  for (final MapEntry(key: name, value: page) in pages.entries) {
    testWidgets('$name fits at 1.6x text', (tester) async {
      final app = await buildApp(tester);
      seedEvaluations(app);
      // The start screen only shows "Último doente" after a finished patient.
      if (name == 'welcome') app.patient.finish();
      await tester.pumpWidget(
        AppScope(
          scores: app.scores,
          start: app.start,
          burn: app.burn,
          patient: app.patient,
          history: app.history,
          unlocker: app.unlocker,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: page(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  }
}
