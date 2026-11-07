import 'package:ephscores/app.dart';
import 'package:ephscores/burn/burn.dart';
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
  // Centred, clear of the times tab at the top edge.
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

  testWidgets('the times tab opens the panel from any page', (tester) async {
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
    // The tab steps aside while the panel is open.
    expect(bubble, findsNothing);

    await tester.tap(find.text('Chegada à vítima'));
    await tester.pump();
    expect(app.patient.events.keys, [PatientEvent.atVictim]);
    await tester.tap(find.byTooltip('Limpar Chegada à vítima'));
    await tester.pump();
    expect(app.patient.events, isEmpty);
    await tester.tap(find.text('Contacto CODU'));
    await tester.pump();

    // Swiping up puts the panel away.
    await tester.fling(find.text('Disponível'), const Offset(0, -300), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(EventsPanel), findsNothing);
    expect(
      find.bySemanticsLabel('Horas da ocorrência, 1 registadas'),
      findsOneWidget,
    );
  });

  testWidgets('pulling the tab down opens the times', (tester) async {
    await tester.pumpWidget(await buildApp(tester));
    final tab = find.bySemanticsLabel(RegExp('^Horas da ocorrência, '));
    // At the top, right of centre (clear of the front camera) and left of
    // the app bar actions.
    expect(tester.getCenter(tab).dx, inInclusiveRange(200, 260));
    expect(tester.getTopLeft(tab).dy, 0);
    await tester.drag(tab, const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(find.byType(EventsPanel), findsOneWidget);
  });

  testWidgets('no times tab without an open patient', (tester) async {
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
