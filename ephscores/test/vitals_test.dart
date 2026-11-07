import 'package:ephscores/scores/adult.dart';
import 'package:ephscores/scores/model.dart';
import 'package:ephscores/scores/pediatric.dart';
import 'package:ephscores/scores/score_store.dart';
import 'package:ephscores/vitals/vitals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ScoreStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = ScoreStore(await SharedPreferences.getInstance());
  });

  void set(Map<Vital, num> values) {
    for (final MapEntry(key: v, value: n) in values.entries) {
      store.setVital(v, n);
    }
  }

  /// Picks an option by label, as in scores_test.
  void answer(ScoreDefinition score, String itemId, String label) {
    final item = score.items.firstWhere((i) => i.id == itemId);
    final i = item.options.indexWhere((o) => o.label == label);
    expect(i, isNot(-1), reason: 'Unknown option $label');
    store.toggle(score.id, item, i);
  }

  void gcs15() {
    for (final item in gcs.items) {
      store.toggle('gcs', item, 0);
    }
  }

  String? picked(ScoreDefinition score, String itemId) {
    final i = store.sheet.answersFor(score.id).choice(itemId);
    if (i == null) return null;
    return score.items.firstWhere((it) => it.id == itemId).options[i].label;
  }

  final normal = {
    Vital.rr: 16,
    Vital.spo2: 97,
    Vital.o2: 0,
    Vital.sbp: 125,
    Vital.hr: 78,
    Vital.avds: 0,
    Vital.temp: 36.8,
  };

  group('parsing', () {
    test('decimal comma and point, one decimal place', () {
      expect(Vital.temp.parse('36,8'), 36.8);
      expect(Vital.temp.parse('36.84'), 36.8);
      expect(Vital.o2.parse('0'), 0);
    });
    test('empty, invalid and out of range are null', () {
      expect(Vital.temp.parse(''), isNull);
      expect(Vital.temp.parse('3'), isNull);
      expect(Vital.pain.parse('11'), isNull);
      expect(Vital.rr.parse('18,5'), isNull);
      expect(Vital.spo2.parse('101'), isNull);
    });
  });

  group('NEWS2 from vital signs', () {
    test('a full set of vitals completes it with no manual answer', () {
      set(normal);
      final r = store.resultFor('news2');
      expect((r.complete, r.value, r.label), (true, 0, 'Risco baixo'));
      expect(store.hasAnswers('news2'), isFalse);
      expect(store.isFilled('news2'), isTrue);
      expect(store.sheet.answered.map((s) => s.id), contains('news2'));
    });

    for (final (vital, value, item, label) in [
      (Vital.rr, 8, 'rr', '≤ 8'),
      (Vital.rr, 25, 'rr', '≥ 25'),
      (Vital.spo2, 92, 'spo2', '92 – 93'),
      (Vital.o2, 2, 'o2', 'Oxigénio suplementar'),
      (Vital.sbp, 220, 'sbp', '≥ 220'),
      (Vital.hr, 131, 'hr', '≥ 131'),
      (Vital.hr, 41, 'hr', '41 – 50'),
      (Vital.temp, 35.0, 'temp', '≤ 35,0'),
      (Vital.temp, 38.1, 'temp', '38,1 – 39,0'),
      (Vital.avds, 2, 'avds', 'Confusão recente, V, D ou S'),
    ]) {
      test('${vital.short} $value → $label', () {
        store.setVital(vital, value);
        expect(picked(news2, item), label);
      });
    }

    test('new confusion while alert counts as altered', () {
      set({Vital.avds: 0});
      expect(picked(news2, 'avds'), 'Alerta');
      store.newConfusion = true;
      expect(picked(news2, 'avds'), 'Confusão recente, V, D ou S');
      // Only meaningful while alert.
      store.setVital(Vital.avds, 1);
      store.setVital(Vital.avds, 0);
      expect(store.vitals.newConfusion, isTrue);
    });

    test('SpO₂ scale 2 needs the oxygen above 92%', () {
      answer(news2, 'scale', 'Escala 2');
      set({Vital.spo2: 95});
      expect(picked(news2, 'spo2_2'), isNull);
      store.setVital(Vital.o2, 2);
      expect(picked(news2, 'spo2_2'), '95 – 96');
      store.setVital(Vital.o2, 0);
      expect(picked(news2, 'spo2_2'), '88 – 92');
      store.setVital(Vital.spo2, 85);
      expect(picked(news2, 'spo2_2'), '84 – 85');
      // Scale 1 is not used meanwhile.
      expect(picked(news2, 'spo2'), isNull);
    });

    test('not filled below 16 years of age', () {
      set({...normal, Vital.age: 10});
      final r = store.resultFor('news2');
      expect(r.answered, 0);
      expect(store.isFilled('news2'), isFalse);
    });

    test(
      'vital signs override a manual answer, which returns when cleared',
      () {
        answer(news2, 'hr', '51 – 90');
        set({Vital.hr: 120});
        expect(picked(news2, 'hr'), '111 – 130');
        store.setVital(Vital.hr, null);
        expect(picked(news2, 'hr'), '51 – 90');
      },
    );
  });

  group('other scores', () {
    test('RTS completes from the vitals once the GCS is in', () {
      set({Vital.rr: 35, Vital.sbp: 80});
      expect(store.isFilled('rts'), isFalse);
      gcs15();
      final r = store.resultFor('rts');
      expect((r.complete, r.value), (true, 10));
    });

    for (final (rr, label) in [
      (0, '0 cpm'),
      (5, '1 – 5 cpm'),
      (9, '6 – 9 cpm'),
      (29, '10 – 29 cpm'),
      (30, '> 29 cpm'),
    ]) {
      test('RTS FR $rr → $label', () {
        store.setVital(Vital.rr, rr);
        expect(picked(rts, 'rr'), label);
      });
    }

    test('RTS PAS 0 is no pulse', () {
      store.setVital(Vital.sbp, 0);
      expect(picked(rts, 'sbp'), 'Sem pulso');
    });

    test('MGAP takes age and pressure', () {
      gcs15();
      answer(mgap, 'mechanism', 'Fechado');
      set({Vital.age: 70, Vital.sbp: 130});
      expect(picked(mgap, 'age'), '≥ 60 anos');
      expect(picked(mgap, 'sbp'), '> 120 mmHg');
      expect(store.resultFor('mgap').value, 4 + 15 + 0 + 5);
      store.setVital(Vital.sbp, 120);
      expect(picked(mgap, 'sbp'), '60 – 120 mmHg');
    });

    test('ProACS takes age and pressure', () {
      set({Vital.age: 72, Vital.sbp: 115});
      expect(picked(proacs, 'age'), '≥ 72 anos');
      expect(picked(proacs, 'sbp'), '< 116 mmHg');
    });

    test('PTS takes the pressure', () {
      store.setVital(Vital.sbp, 90);
      expect(picked(pts, 'sbp'), '50 – 90 mmHg');
    });
  });

  group('sheet', () {
    test('vital signs survive a JSON round trip', () {
      set({...normal, Vital.age: 45});
      store.newConfusion = true;
      final back = ScoreSheet.fromJson(store.sheet.toJson());
      expect(back.sameAs(store.sheet), isTrue);
      expect(back.vitals[Vital.temp], 36.8);
      expect(back.vitals.newConfusion, isTrue);
    });

    test('sheets saved before vital signs still load', () {
      final legacy = ScoreSheet.fromJson({
        'gcs': {
          'eyes': [0],
        },
      });
      expect(legacy.vitals.isEmpty, isTrue);
      expect(legacy.answersFor('gcs').choice('eyes'), 0);
    });

    test('out-of-range saved values are dropped', () {
      final sheet = ScoreSheet.fromJson({
        'vitals': {'hr': 900, 'rr': 20},
      });
      expect((sheet.vitals[Vital.hr], sheet.vitals[Vital.rr]), (null, 20));
    });

    test('copies are independent', () {
      set({Vital.hr: 80});
      final copy = store.sheet.copy();
      store.setVital(Vital.hr, 140);
      expect(copy.vitals[Vital.hr], 80);
    });

    test('vitals alone make the sheet non-empty; reset all clears them', () {
      set({Vital.pain: 4});
      expect(store.isEmpty, isFalse);
      store.resetAll();
      expect(store.isEmpty, isTrue);
    });
  });

  group('derived values', () {
    test('shock index bands', () {
      expect(shockIndexResult(0.6).severity, Severity.ok);
      expect(shockIndexResult(0.7).severity, Severity.warning);
      expect(shockIndexResult(1.0).severity, Severity.danger);
      set({Vital.hr: 110, Vital.sbp: 100});
      expect(store.vitals.shockIndex, closeTo(1.1, 1e-9));
      expect(shockIndexResult(store.vitals.shockIndex!).display, '1,10');
    });

    test('glucose flags', () {
      expect(glucoseFlag(59)?.$1, Severity.danger);
      expect(glucoseFlag(60), isNull);
      expect(glucoseFlag(201)?.$1, Severity.warning);
    });

    test('summary follows the national form', () {
      set({
        Vital.age: 67,
        Vital.avds: 0,
        Vital.rr: 18,
        Vital.spo2: 95,
        Vital.o2: 0,
        Vital.hr: 88,
        Vital.sbp: 120,
        Vital.dbp: 80,
        Vital.temp: 37.2,
        Vital.pain: 3,
        Vital.glucose: 110,
      });
      expect(
        store.vitals.summary(),
        '67 anos · AVDS A · FR 18 cpm · SpO₂ 95% · O₂ ar ambiente · FC 88 bpm · '
        'PA 120/80 mmHg · Temp. 37,2 °C · Dor 3/10 · Glic. 110 mg/dL · '
        'IC 0,73',
      );
    });
  });

  group('faces scale', () {
    test('records the pain and how it was rated', () {
      store.setPainFaces(6);
      expect(store.vitals[Vital.pain], 6);
      expect(store.vitals.painFaces, isTrue);
      expect(store.vitals.format(Vital.pain), '6/10 (faces)');
      final back = ScoreSheet.fromJson(store.sheet.toJson());
      expect(back.vitals.painFaces, isTrue);
    });
    test('typing a number replaces the faces rating', () {
      store.setPainFaces(8);
      store.setVital(Vital.pain, 5);
      expect(store.vitals.painFaces, isFalse);
      expect(store.vitals.format(Vital.pain), '5/10');
    });
    test('clearing the pain drops the faces flag', () {
      store.setPainFaces(2);
      store.setVital(Vital.pain, null);
      expect(store.vitals.painFaces, isFalse);
      expect(store.vitals.toJson(), isEmpty);
    });
  });

  group('children', () {
    test('normal ranges by age (PALS)', () {
      expect(childNormal(Vital.rr, 0), (30, 53));
      expect(childNormal(Vital.rr, 4), (20, 28));
      expect(childNormal(Vital.hr, 7), (75, 118));
      expect(childNormal(Vital.sbp, 14), (110, 131));
      expect(childNormal(Vital.rr, 16), isNull);
      expect(childNormal(Vital.temp, 4), isNull);
    });

    test('hypotension threshold', () {
      expect([0, 1, 5, 9, 10, 15].map(childHypotension), [
        70,
        72,
        80,
        88,
        90,
        90,
      ]);
    });

    test('flags', () {
      expect(childFlag(Vital.rr, 24, 4), isNull);
      expect(childFlag(Vital.rr, 34, 4), (
        Severity.warning,
        'FR elevada para a idade (normal 20–28 cpm)',
      ));
      expect(childFlag(Vital.hr, 70, 7)?.$2, startsWith('FC baixa'));
      // Below the normal range but not hypotension: amber.
      expect(childFlag(Vital.sbp, 82, 4)?.$1, Severity.warning);
      expect(childFlag(Vital.sbp, 75, 4), (
        Severity.danger,
        'Hipotensão para a idade (< 78 mmHg)',
      ));
      expect(childFlag(Vital.sbp, 75, 30), isNull);
    });

    test('age labels', () {
      expect(childAgeLabel(0), 'no 1.º ano de vida');
      expect(childAgeLabel(1), 'aos 1 ano');
      expect(childAgeLabel(6), 'aos 6 anos');
    });
  });

  group('paediatric GCS', () {
    void pick(int eyes, int verbal, int motor) {
      for (final (i, item) in pgcs.items.indexed) {
        store.toggle('pgcs', item, [eyes, verbal, motor][i]);
      }
    }

    test('15 is mild, with the breakdown', () {
      pick(0, 0, 0);
      final r = store.resultFor('pgcs');
      expect((r.value, r.severity, r.breakdown), (15, Severity.ok, 'O4 V5 M6'));
    });

    test('8 is severe', () {
      pick(2, 3, 2); // 2 + 2 + 4
      final r = store.resultFor('pgcs');
      expect((r.value, r.label), (8, 'Grave'));
    });
  });

  group('FLACC', () {
    ScoreResult flaccWith(List<int> picks) {
      for (final (i, item) in flacc.items.indexed) {
        store.toggle('flacc', item, picks[i]);
      }
      return store.resultFor('flacc');
    }

    test('0 is no pain', () {
      final r = flaccWith([0, 0, 0, 0, 0]);
      expect(
        (r.display, r.label, r.severity),
        ('0/10', 'Sem dor', Severity.ok),
      );
    });
    test('5 is moderate', () {
      final r = flaccWith([1, 1, 1, 1, 1]);
      expect((r.value, r.label), (5, 'Dor moderada'));
    });
    test('10 is severe', () {
      final r = flaccWith([2, 2, 2, 2, 2]);
      expect((r.value, r.severity), (10, Severity.danger));
    });
  });
}
