import 'package:ephscores/app.dart';
import 'package:ephscores/burn/burn.dart';
import 'package:ephscores/scores/score_store.dart';
import 'package:ephscores/scores/adult.dart';
import 'package:ephscores/start/start.dart';
import 'package:ephscores/ui/burn_page.dart';
import 'package:ephscores/ui/contacts_page.dart';
import 'package:ephscores/ui/home_page.dart';
import 'package:ephscores/ui/score_list_page.dart';
import 'package:ephscores/ui/score_page.dart';
import 'package:ephscores/ui/start_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phone-sized viewport (360x780 logical pixels).
Future<EPHScoresApp> buildApp(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return EPHScoresApp(
    scores: ScoreStore(prefs),
    start: StartStore(prefs),
    burn: BurnStore(prefs),
  );
}

/// The scrollable of the page on top (pages underneath stay mounted).
final pageScrollable = find.byType(Scrollable).last;

void main() {
  group('large text', largeTextTests);

  testWidgets('scoring GCS updates the result bar and the list', (
    tester,
  ) async {
    await tester.pumpWidget(await buildApp(tester));
    await tester.tap(find.text('Escalas gerais'));
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
    final app = await buildApp(tester);
    await tester.pumpWidget(app);
    await tester.tap(find.text('Triagem START'));
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
    await tester.tap(find.text('Avaliação do queimado'));
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
}

/// Layout overflows throw in tests, so rendering is enough to catch them.
void largeTextTests() {
  final pages = <String, Widget Function()>{
    'home': () => const HomePage(),
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
      await tester.pumpWidget(
        AppScope(
          scores: app.scores,
          start: app.start,
          burn: app.burn,
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
