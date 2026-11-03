import 'package:ephscores/burn/burn.dart';
import 'package:ephscores/main.dart';
import 'package:ephscores/start/start.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Walks the START tree with the given answers and returns the category.
StartCategory triage(List<bool> answers) {
  var q = StartQuestion.walks;
  for (final (i, yes) in answers.indexed) {
    final step = startAnswer(q, yes);
    if (step.category != null) {
      expect(i, answers.length - 1, reason: 'Finished early');
      return step.category!;
    }
    q = step.next!;
  }
  fail('Not enough answers');
}

void main() {
  group('START algorithm', () {
    test(
      'walking wounded are P3',
      () => expect(triage([true]), StartCategory.p3),
    );
    test('apnoeic after airway opening is P4', () {
      expect(triage([false, false, false]), StartCategory.p4);
    });
    test('breathes after airway opening is P1', () {
      expect(triage([false, false, true]), StartCategory.p1);
    });
    test(
      'RR > 30 is P1',
      () => expect(triage([false, true, true]), StartCategory.p1),
    );
    test(
      'poor perfusion is P1',
      () => expect(triage([false, true, false, true]), StartCategory.p1),
    );
    test('does not obey is P1', () {
      expect(triage([false, true, false, false, false]), StartCategory.p1);
    });
    test('obeys commands is P2', () {
      expect(triage([false, true, false, false, true]), StartCategory.p2);
    });
  });

  group('StartStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('counts, removes last of a category, persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = StartStore(prefs)
        ..add(StartCategory.p1)
        ..add(StartCategory.p2)
        ..add(StartCategory.p1);
      store.removeLast(StartCategory.p1);
      expect(
        (
          store.count(StartCategory.p1),
          store.count(StartCategory.p2),
          store.total,
        ),
        (1, 1, 2),
      );
      expect(StartStore(prefs).total, 2);
      store.removeLast(StartCategory.p4); // no-op
      store.clear();
      expect(StartStore(prefs).total, 0);
    });
  });

  group('Burns', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('each body map sums to 100%', () {
      for (final p in BurnPatient.values) {
        final total = bodyRegions[p]!.fold(0.0, (a, r) => a + r.percent);
        expect(total, 100, reason: p.name);
      }
    });

    test('region ids are unique', () {
      for (final p in BurnPatient.values) {
        final ids = bodyRegions[p]!.map((r) => r.id).toList();
        expect(ids.toSet().length, ids.length);
      }
    });

    test('TBSA excludes first degree; repaint toggles', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = BurnStore(prefs);
      final regions = store.regions;
      final head = regions.firstWhere((r) => r.id == 'front.head');
      final chest = regions.firstWhere((r) => r.id == 'front.upperTorso');
      final arm = regions.firstWhere((r) => r.id == 'back.leftArm');
      store
        ..paint(head, BurnDegree.first)
        ..paint(chest, BurnDegree.second)
        ..paint(arm, BurnDegree.third);
      expect(store.tbsa, 13.5);
      expect(store.percentWhere((d) => d == BurnDegree.first), 4.5);
      store.paint(chest, BurnDegree.second);
      expect(store.tbsa, 4.5);
    });

    test('adult and child keep separate maps and persist', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = BurnStore(prefs);
      store.paint(store.regions.first, BurnDegree.third);
      store.patient = BurnPatient.child;
      expect(store.tbsa, 0);
      store.paint(store.regions.first, BurnDegree.second); // child head 9%
      final reloaded = BurnStore(prefs);
      expect((reloaded.patient, reloaded.tbsa), (BurnPatient.child, 9));
      reloaded.patient = BurnPatient.adult;
      expect(reloaded.tbsa, 4.5);
    });
  });

  test('legacy START counters are migrated and old keys removed', () async {
    SharedPreferences.setMockInitialValues({
      'p1': 2,
      'p3': 1,
      's4.3': 2,
      'head_front': 1,
    });
    final prefs = await SharedPreferences.getInstance();
    await migrateLegacyPrefs(prefs);
    final store = StartStore(prefs);
    expect(
      (store.count(StartCategory.p1), store.count(StartCategory.p3)),
      (2, 1),
    );
    expect(prefs.getKeys(), {'start.v2'});
  });
}
