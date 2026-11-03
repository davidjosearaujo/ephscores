import 'package:ephscores/app.dart';
import 'package:ephscores/burn/burn.dart';
import 'package:ephscores/patient/patient.dart';
import 'package:ephscores/scores/adult.dart';
import 'package:ephscores/scores/score_store.dart';
import 'package:ephscores/start/start.dart';
import 'package:ephscores/ui/burn_page.dart';
import 'package:ephscores/ui/contacts_page.dart';
import 'package:ephscores/ui/dashboard_page.dart';
import 'package:ephscores/ui/evolution_page.dart';
import 'package:ephscores/ui/score_list_page.dart';
import 'package:ephscores/ui/score_page.dart';
import 'package:ephscores/ui/start_page.dart';
import 'package:ephscores/ui/welcome_page.dart';
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

/// Three evaluations: GCS 15, then 14 with a burn, then 9.
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
  await tester.ensureVisible(find.text(label));
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

    await tester.pageBack();
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
    await tester.tap(find.text('Copiar resumo'));
    await tester.pump();
    expect(copied, startsWith('EPHScores — evolução do doente'));
    expect(copied, contains('Avaliação 2'));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Último doente'), findsOneWidget);
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
