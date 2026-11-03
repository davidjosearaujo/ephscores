import 'package:ephscores/scores/adult.dart';
import 'package:ephscores/scores/model.dart';
import 'package:ephscores/scores/pediatric.dart';
import 'package:ephscores/scores/score_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds answers by option label, which keeps tests readable and catches
/// accidental label/points mismatches.
Answers pick(ScoreDefinition score, Map<String, Object> byLabel) {
  final map = <String, Set<int>>{};
  for (final MapEntry(key: itemId, value: labels) in byLabel.entries) {
    final item = score.items.firstWhere((i) => i.id == itemId);
    final list = labels is List<String> ? labels : [labels as String];
    map[itemId] = {
      for (final l in list) item.options.indexWhere((o) => o.label == l),
    };
    expect(
      map[itemId],
      isNot(contains(-1)),
      reason: 'Unknown option in $itemId: $list',
    );
  }
  return Answers(map);
}

ScoreResult noLookup(String _) => throw StateError('unexpected lookup');

ScoreResult eval(
  ScoreDefinition score,
  Map<String, Object> byLabel, {
  ResultLookup lookup = noLookup,
}) => score.resultFor(pick(score, byLabel), lookup);

void main() {
  group('Cincinnati', () {
    test('all normal', () {
      final r = eval(cincinnati, {
        'face': 'Normal',
        'arm': 'Normal',
        'speech': 'Normal',
      });
      expect((r.value, r.display, r.severity), (0, '0/3', Severity.ok));
    });
    test('any finding suggests stroke', () {
      final r = eval(cincinnati, {
        'face': 'Alterado',
        'arm': 'Normal',
        'speech': 'Normal',
      });
      expect((r.value, r.severity), (1, Severity.danger));
    });
  });

  group('GCS', () {
    test('15 is mild with breakdown', () {
      final r = eval(gcs, {
        'eyes': 'Espontânea',
        'verbal': 'Orientada',
        'motor': 'Obedece a ordens',
      });
      expect((r.value, r.severity, r.breakdown), (15, Severity.ok, 'O4 V5 M6'));
    });
    for (final (eyes, verbal, motor, total, severity) in [
      ('Sem resposta', 'Sem resposta', 'Sem resposta', 3, Severity.danger),
      ('À dor', 'Sons incompreensíveis', 'Fuga à dor', 8, Severity.danger),
      ('À dor', 'Palavras inapropriadas', 'Fuga à dor', 9, Severity.warning),
      ('À voz', 'Confusa', 'Localiza a dor', 12, Severity.warning),
      ('À voz', 'Confusa', 'Obedece a ordens', 13, Severity.ok),
    ]) {
      test('$total → $severity', () {
        final r = eval(gcs, {'eyes': eyes, 'verbal': verbal, 'motor': motor});
        expect((r.value, r.severity), (total, severity));
      });
    }
    test('incomplete shows partial sum without interpretation', () {
      final r = eval(gcs, {'eyes': 'Espontânea'});
      expect(
        (r.value, r.severity, r.label, r.answered, r.total),
        (4, Severity.incomplete, '', 1, 3),
      );
    });
  });

  group('MGAP', () {
    ScoreResult gcsOf(int v) => ScoreResult(
      value: v,
      display: '$v',
      severity: Severity.ok,
      label: '',
      answered: 3,
      total: 3,
    );
    const incompleteGcs = ScoreResult(
      value: null,
      display: '–',
      severity: Severity.incomplete,
      label: '',
      answered: 0,
      total: 3,
    );

    test('best case is 29, low risk', () {
      final r = eval(mgap, {
        'mechanism': 'Fechado',
        'age': '< 60 anos',
        'sbp': '> 120 mmHg',
      }, lookup: (_) => gcsOf(15));
      expect((r.value, r.severity), (29, Severity.ok));
    });
    test('intermediate and high risk bands', () {
      final mid = eval(mgap, {
        'mechanism': 'Penetrante',
        'age': '< 60 anos',
        'sbp': '60 – 120 mmHg',
      }, lookup: (_) => gcsOf(14)); // 0 + 5 + 3 + 14
      expect((mid.value, mid.severity), (22, Severity.warning));
      final high = eval(mgap, {
        'mechanism': 'Penetrante',
        'age': '≥ 60 anos',
        'sbp': '< 60 mmHg',
      }, lookup: (_) => gcsOf(15));
      expect((high.value, high.severity), (15, Severity.danger));
    });
    test('needs GCS to be complete', () {
      final r = eval(mgap, {
        'mechanism': 'Fechado',
        'age': '< 60 anos',
        'sbp': '> 120 mmHg',
      }, lookup: (_) => incompleteGcs);
      expect((r.severity, r.answered, r.total), (Severity.incomplete, 3, 4));
    });
  });

  group('RTS', () {
    test('GCS coding', () {
      expect([3, 4, 5, 6, 8, 9, 12, 13, 15].map(gcsToRts), [
        0,
        1,
        1,
        2,
        2,
        3,
        3,
        4,
        4,
      ]);
    });
    test('normal patient scores 12', () {
      final r = eval(
        rts,
        {'rr': '10 – 29 cpm', 'sbp': '> 89 mmHg'},
        lookup: (_) => const ScoreResult(
          value: 15,
          display: '15',
          severity: Severity.ok,
          label: '',
          answered: 3,
          total: 3,
        ),
      );
      expect((r.value, r.severity), (12, Severity.ok));
    });
    test('11 is altered, 10 is severe', () {
      const gcs15 = ScoreResult(
        value: 15,
        display: '15',
        severity: Severity.ok,
        label: '',
        answered: 3,
        total: 3,
      );
      expect(
        eval(rts, {
          'rr': '> 29 cpm',
          'sbp': '> 89 mmHg',
        }, lookup: (_) => gcs15).severity,
        Severity.warning,
      );
      expect(
        eval(rts, {
          'rr': '6 – 9 cpm',
          'sbp': '> 89 mmHg',
        }, lookup: (_) => gcs15).severity,
        Severity.danger,
      );
    });
  });

  group('NEWS2', () {
    const normal = {
      'rr': '12 – 20',
      'spo2': '≥ 96',
      'o2': 'Ar ambiente',
      'sbp': '111 – 219',
      'hr': '51 – 90',
      'avds': 'Alerta',
      'temp': '36,1 – 38,0',
    };
    test('normal is 0, low risk', () {
      final r = eval(news2, normal);
      expect((r.value, r.severity, r.complete), (0, Severity.ok, true));
    });
    test('single parameter of 3 is low-medium', () {
      final r = eval(news2, {...normal, 'avds': 'Confusão recente, V, D ou S'});
      expect((r.value, r.severity), (3, Severity.warning));
      expect(r.label, contains('baixo-médio'));
    });
    test('aggregate 5 is medium, 7 is high', () {
      // rr 21–24 (2) + O2 (2) + HR 91–110 (1) = 5
      final mid = eval(news2, {
        ...normal,
        'rr': '21 – 24',
        'o2': 'Oxigénio suplementar',
        'hr': '91 – 110',
      });
      expect((mid.value, mid.label), (5, 'Risco médio'));
      // + temp 38.1–39 (1) + SBP 101–110 (1) = 7
      final high = eval(news2, {
        ...normal,
        'rr': '21 – 24',
        'o2': 'Oxigénio suplementar',
        'hr': '91 – 110',
        'temp': '38,1 – 39,0',
        'sbp': '101 – 110',
      });
      expect((high.value, high.severity), (7, Severity.danger));
    });
    test('SpO2 scale 2 replaces scale 1', () {
      final answers = {...normal, 'scale': 'Escala 2', 'spo2_2': '88 – 92'}
        ..remove('spo2');
      final r = eval(news2, answers);
      expect((r.value, r.complete), (0, true));
      final hidden = news2.visibleItems(pick(news2, answers)).map((i) => i.id);
      expect(hidden, isNot(contains('spo2')));
    });
    test('scale choice is optional', () {
      expect(eval(news2, normal).total, 7);
    });
  });

  group('ProACS', () {
    // Points from Table 2 of the derivation paper: age >=72 = 2, SBP <116 = 1,
    // Killip II/III = 1, Killip IV = 3, ST elevation = 1 (maximum 7).
    Map<String, Object> patient({
      String age = '< 72 anos',
      String sbp = '≥ 116 mmHg',
      String killip = 'I',
      String st = 'Não',
    }) => {'age': age, 'sbp': sbp, 'killip': killip, 'st': st};

    test('lowest and highest totals', () {
      final low = eval(proacs, patient());
      expect((low.value, low.severity), (0, Severity.ok));
      final high = eval(
        proacs,
        patient(age: '≥ 72 anos', sbp: '< 116 mmHg', killip: 'IV', st: 'Sim'),
      );
      expect((high.value, high.severity), (7, Severity.danger));
    });

    test('age counts two points', () {
      final r = eval(proacs, patient(age: '≥ 72 anos'));
      expect((r.value, r.severity), (2, Severity.warning));
    });

    test('1 and 2 are intermediate, 3 is high', () {
      expect(eval(proacs, patient(st: 'Sim')).severity, Severity.warning);
      expect(
        eval(proacs, patient(age: '≥ 72 anos', sbp: '< 116 mmHg')).severity,
        Severity.danger, // 2 + 1
      );
      expect(eval(proacs, patient(killip: 'IV')).severity, Severity.danger);
    });

    test('labels carry the published mortality ranges', () {
      expect(eval(proacs, patient()).label, contains('< 1 %'));
      expect(eval(proacs, patient(st: 'Sim')).label, contains('1–4 %'));
      expect(eval(proacs, patient(killip: 'IV')).label, contains('> 4 %'));
    });
  });

  group('RACE', () {
    test('left deficit asks agnosia, right asks aphasia', () {
      List<String> ids(String side) => race
          .visibleItems(pick(race, {'side': side}))
          .map((i) => i.id)
          .toList();
      expect(
        ids('Esquerdo'),
        allOf(contains('agnosia'), isNot(contains('aphasia'))),
      );
      expect(
        ids('Direito'),
        allOf(contains('aphasia'), isNot(contains('agnosia'))),
      );
    });
    test('max 9 suggests large vessel occlusion', () {
      final r = eval(race, {
        'side': 'Direito',
        'face': 'Moderada a grave',
        'arm': 'Grave',
        'leg': 'Grave',
        'gaze': 'Presente',
        'aphasia': 'Não cumpre ordens',
      });
      expect((r.value, r.severity, r.complete), (9, Severity.danger, true));
    });
    test('4 is below the LVO threshold', () {
      final r = eval(race, {
        'side': 'Esquerdo',
        'face': 'Ligeira',
        'arm': 'Moderada',
        'leg': 'Moderada',
        'gaze': 'Presente',
        'agnosia': 'Reconhece braço e défice',
      });
      expect((r.value, r.severity), (4, Severity.warning));
    });
  });

  group('APGAR', () {
    test('bands', () {
      Map<String, Object> all(int points) => {
        for (final item in apgar.items)
          item.id: item.options.firstWhere((o) => o.points == points).label,
      };
      expect(eval(apgar, all(2)).value, 10);
      expect(eval(apgar, all(2)).severity, Severity.ok);
      expect(eval(apgar, all(1)).severity, Severity.warning); // 5
      expect(eval(apgar, all(0)).severity, Severity.danger);
    });
  });

  group('PTS', () {
    test('range is -6 to 12', () {
      Map<String, Object> all(int points) => {
        for (final item in pts.items)
          item.id: item.options.firstWhere((o) => o.points == points).label,
      };
      expect(
        (eval(pts, all(2)).value, eval(pts, all(2)).severity),
        (12, Severity.ok),
      );
      expect(
        (eval(pts, all(1)).value, eval(pts, all(1)).severity),
        (6, Severity.warning),
      );
      expect(
        (eval(pts, all(-1)).value, eval(pts, all(-1)).severity),
        (-6, Severity.danger),
      );
    });
  });

  group('TAP', () {
    test('all normal is stable', () {
      final r = eval(pat, {
        'appearance': 'Sem alterações',
        'breathing': 'Sem alterações',
        'circulation': 'Sem alterações',
      });
      expect((r.display, r.severity, r.label), ('0/3', Severity.ok, 'Estável'));
    });
    test('physiological interpretations', () {
      final r = eval(pat, {
        'appearance': ['Não interage', 'Olhar anormal'],
        'breathing': 'Sem alterações',
        'circulation': 'Pele marmoreada',
      });
      expect(
        (r.display, r.severity, r.label),
        ('2/3', Severity.danger, 'Choque descompensado'),
      );
      final b = eval(pat, {
        'appearance': 'Sem alterações',
        'breathing': 'Tiragem',
        'circulation': 'Sem alterações',
      });
      expect(b.label, 'Dificuldade respiratória');
    });
  });

  group('ScoreStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('single choice replaces, tapping again clears', () async {
      final store = ScoreStore(await SharedPreferences.getInstance());
      final eyes = gcs.items.first;
      store.toggle('gcs', eyes, 0);
      store.toggle('gcs', eyes, 1);
      expect(store.answersFor('gcs').of('eyes'), {1});
      store.toggle('gcs', eyes, 1);
      expect(store.hasAnswers('gcs'), isFalse);
    });

    test('exclusive option clears findings and vice versa', () async {
      final store = ScoreStore(await SharedPreferences.getInstance());
      final appearance = pat.items.first;
      store.toggle('pat', appearance, 1);
      store.toggle('pat', appearance, 2);
      expect(store.answersFor('pat').of('appearance'), {1, 2});
      store.toggle('pat', appearance, 0);
      expect(store.answersFor('pat').of('appearance'), {0});
      store.toggle('pat', appearance, 3);
      expect(store.answersFor('pat').of('appearance'), {3});
    });

    test('MGAP pulls GCS from the store', () async {
      final store = ScoreStore(await SharedPreferences.getInstance());
      for (final item in gcs.items) {
        store.toggle('gcs', item, 0);
      }
      for (final item in mgap.items) {
        store.toggle('mgap', item, 0);
      }
      expect(store.resultFor('mgap').value, 29);
      expect(store.resultFor('rts').answered, 1);
    });

    test('persists and reloads, ignoring junk', () async {
      final prefs = await SharedPreferences.getInstance();
      ScoreStore(prefs).toggle('gcs', gcs.items.first, 2);
      expect(ScoreStore(prefs).answersFor('gcs').of('eyes'), {2});

      await prefs.setString(
        'scores.v2',
        '{"gcs":{"eyes":[99],"nope":[0]},"ghost":{}}',
      );
      expect(ScoreStore(prefs).isEmpty, isTrue);
      await prefs.setString('scores.v2', 'not json');
      expect(ScoreStore(prefs).isEmpty, isTrue);
    });
  });

  test('every option label is unique within its item', () {
    for (final score in allScores.values) {
      for (final item in score.items) {
        final labels = item.options.map((o) => o.label).toList();
        expect(
          labels.toSet().length,
          labels.length,
          reason: '${score.id}.${item.id}',
        );
      }
    }
  });
}
