import 'package:ephscores/burn/burn.dart';
import 'package:ephscores/injuries/injuries.dart';
import 'package:ephscores/patient/patient.dart';
import 'package:ephscores/patient/summary.dart';
import 'package:ephscores/scores/adult.dart';
import 'package:ephscores/scores/model.dart';
import 'package:ephscores/scores/score_store.dart';
import 'package:ephscores/ui/widgets.dart' show resolveClockTime;
import 'package:ephscores/viaverde/via_verde.dart';
import 'package:ephscores/vitals/vitals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final now = DateTime(2026, 11, 5, 15, 0);

void main() {
  late SharedPreferences prefs;
  late ScoreStore scores;
  late BurnStore burns;
  late PatientStore patient;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    scores = ScoreStore(prefs);
    burns = BurnStore(prefs);
    patient = PatientStore(prefs)
      ..start(at: now.subtract(const Duration(minutes: 30)));
  });

  ClinicalState state() => ClinicalState(
    scores: scores.sheet,
    burns: burns.sheet,
    onset: patient.onset,
    checks: patient.checks,
    injuries: patient.injuries,
    now: now,
  );

  CriteriaCheck check(ViaVerde p) => p.check(state());

  void answer(ScoreDefinition score, String itemId, String label) {
    final item = score.items.firstWhere((i) => i.id == itemId);
    scores.toggle(
      score.id,
      item,
      item.options.indexWhere((o) => o.label == label),
    );
  }

  void setGcs(int eyes, int verbal, int motor) {
    for (final (item, i) in [
      (gcs.items[0], eyes),
      (gcs.items[1], verbal),
      (gcs.items[2], motor),
    ]) {
      scores.toggle('gcs', item, i);
    }
  }

  void onsetAgo(Duration d, {bool seen = false}) =>
      patient.onset = Onset(now.subtract(d), lastSeenWell: seen);

  group('AVC', () {
    test('no signs, no pathway', () {
      expect(check(viaVerdeAvc).result.severity, Severity.incomplete);
    });

    test('Cincinnati signs need age and onset', () {
      answer(cincinnati, 'face', 'Alterado');
      var c = check(viaVerdeAvc);
      expect(c.isAuto('face'), isTrue);
      expect(c.reasons['face'], 'Cincinnati');
      expect(c.result.severity, Severity.warning);

      scores.setVital(Vital.age, 70);
      onsetAgo(const Duration(hours: 3));
      c = check(viaVerdeAvc);
      expect(c.result.severity, Severity.danger);
      expect(c.reasons['onset'], 'há 3 h 00 min');
    });

    test('more than 24 h is outside the window', () {
      patient.toggleCheck('avc.paresis');
      patient.toggleCheck('avc.age');
      onsetAgo(const Duration(hours: 25), seen: true);
      final c = check(viaVerdeAvc);
      expect(c.met('onset'), isFalse);
      expect(c.result.severity, Severity.warning);
    });

    test('a known age under 18 does not meet the age criterion', () {
      scores.setVital(Vital.age, 16);
      expect(check(viaVerdeAvc).met('age'), isFalse);
    });

    test('the onset can only come from the clock, not a tick', () {
      patient.toggleCheck('avc.onset');
      expect(check(viaVerdeAvc).met('onset'), isFalse);
    });

    test('RACE findings count as signs', () {
      answer(race, 'side', 'Direito');
      answer(race, 'aphasia', 'Não cumpre ordens');
      expect(check(viaVerdeAvc).reasons['speech'], 'RACE');
    });
  });

  group('Coronária', () {
    test('suspicion without ECG asks for one', () {
      patient.toggleCheck('coronaria.pain');
      final r = check(viaVerdeCoronaria).result;
      expect((r.severity, r.display), (Severity.warning, '!'));
    });

    test('ST elevation within 12 h meets it', () {
      patient.toggleCheck('coronaria.pain');
      answer(proacs, 'st', 'Sim');
      onsetAgo(const Duration(hours: 2));
      final c = check(viaVerdeCoronaria);
      expect(c.reasons['st'], 'ProACS');
      expect((c.result.severity, c.result.display), (Severity.danger, '✓'));
    });

    test('ST elevation after 12 h still calls CODU', () {
      patient.toggleCheck('coronaria.st');
      onsetAgo(const Duration(hours: 13));
      final r = check(viaVerdeCoronaria).result;
      expect((r.severity, r.display), (Severity.danger, '!'));
    });
  });

  group('Sépsis', () {
    test('one criterion in each of the four fields', () {
      scores
        ..setVital(Vital.temp, 38.4)
        ..setVital(Vital.hr, 112);
      patient.toggleCheck('sepsis.urinary');
      var c = check(viaVerdeSepsis);
      expect(c.result.display, '3/4');
      expect(c.result.severity, Severity.incomplete);

      scores.setVital(Vital.sbp, 85);
      c = check(viaVerdeSepsis);
      expect((c.result.display, c.result.severity), ('4/4', Severity.danger));
      expect(c.reasons['fever'], 'Temp. 38,4 °C');
      expect(c.reasons['sbp'], 'PAS 85 mmHg');
    });

    test('altered AVDS counts for infection and inflammation', () {
      scores.setVital(Vital.avds, 1);
      final c = check(viaVerdeSepsis);
      expect(
        (c.reasons['consciousness'], c.reasons['avds']),
        ('AVDS V', 'AVDS V'),
      );
    });

    test('thresholds are strict', () {
      scores
        ..setVital(Vital.temp, 37.9)
        ..setVital(Vital.hr, 90)
        ..setVital(Vital.rr, 22)
        ..setVital(Vital.spo2, 90);
      expect(check(viaVerdeSepsis).reasons, isEmpty);
    });
  });

  group('Trauma', () {
    test('GCS below 14', () {
      setGcs(1, 1, 0); // 3 + 4 + 6
      expect(check(viaVerdeTrauma).reasons['gcs'], 'ECG 13');
    });

    test('low SpO₂ only counts on oxygen', () {
      scores.setVital(Vital.spo2, 88);
      expect(check(viaVerdeTrauma).met('spo2'), isFalse);
      scores.setVital(Vital.o2, 10);
      expect(check(viaVerdeTrauma).met('spo2'), isTrue);
    });

    test('major burns from the burn map', () {
      // Chest, abdomen and one leg at 9% each.
      for (final r in burns.regions.where((r) => r.percent == 9).take(3)) {
        burns.paint(r, BurnDegree.second);
      }
      expect(check(viaVerdeTrauma).reasons['burns'], '2.º grau 27%');
    });

    test('RTS of 10 or less refers to a trauma centre', () {
      setGcs(0, 0, 0);
      scores
        ..setVital(Vital.rr, 35)
        ..setVital(Vital.sbp, 80);
      var c = check(viaVerdeTrauma);
      expect(c.reasons['rts'], 'RTS 10');
      expect(c.met('rr'), isTrue);
      // Not until it is marked as a trauma.
      expect(c.result.severity, Severity.incomplete);
      expect(c.result.label, 'Assinalar se é vítima de trauma');
      patient.toggleCheck('trauma.trauma');
      c = check(viaVerdeTrauma);
      expect(c.result.severity, Severity.danger);
    });

    test('the injury map makes it a trauma, and penetrating wounds count', () {
      scores.setVital(Vital.sbp, 80);
      expect(
        check(viaVerdeTrauma).result.label,
        'Assinalar se é vítima de trauma',
      );

      BodyRegion region(String id) =>
          bodyRegions[BurnPatient.adult]!.firstWhere((r) => r.id == id);
      // Pain alone isn't an injury.
      patient.injuries = patient.injuries.toggle(
        region('front.rightArm'),
        InjuryType.pain,
      );
      expect(check(viaVerdeTrauma).met('trauma'), isFalse);

      patient.injuries = patient.injuries.toggle(
        region('front.rightArm'),
        InjuryType.fracture,
      );
      final c = check(viaVerdeTrauma);
      expect(c.met('trauma'), isTrue);
      expect(c.result.severity, Severity.danger);
      expect(c.met('penetrating'), isFalse);

      // A penetrating wound of a limb can't tell how far up; of the trunk can.
      patient.injuries = patient.injuries.toggle(
        region('front.rightArm'),
        InjuryType.penetrating,
      );
      expect(check(viaVerdeTrauma).met('penetrating'), isFalse);
      patient.injuries = patient.injuries.toggle(
        region('front.upperTorso'),
        InjuryType.penetrating,
      );
      expect(check(viaVerdeTrauma).met('penetrating'), isTrue);
    });

    test('vital signs alone are not a trauma', () {
      scores.setVital(Vital.sbp, 85);
      expect(check(viaVerdeTrauma).result.display, '–');
      patient.register(scores.sheet, burns.sheet, at: now);
      expect(
        viaVerdeStatus(patient).map((e) => e.$1),
        isNot(contains(viaVerdeTrauma)),
      );
    });

    test('a mechanism is enough context', () {
      scores.setVital(Vital.sbp, 85);
      patient.toggleCheck('trauma.fall');
      expect(check(viaVerdeTrauma).result.severity, Severity.danger);
    });

    test('mechanism ticked by hand', () {
      patient.toggleCheck('trauma.fall');
      final c = check(viaVerdeTrauma);
      expect((c.met('fall'), c.isAuto('fall')), (true, false));
      expect(c.metLabels, ['Queda superior a 6 metros']);
    });
  });

  group('patient', () {
    test('onset and ticks are saved and cleared with a new patient', () {
      onsetAgo(const Duration(minutes: 40), seen: true);
      patient.toggleCheck('trauma.fall');
      final restored = PatientStore(prefs);
      expect(restored.onset?.at, now.subtract(const Duration(minutes: 40)));
      expect(restored.onset?.lastSeenWell, isTrue);
      expect(restored.checks, {'trauma.fall'});

      restored.start(at: now);
      expect(restored.onset, isNull);
      expect(restored.checks, isEmpty);
    });

    test('ISBAR has the vitals, the onset and the pathways', () {
      onsetAgo(const Duration(hours: 1));
      scores
        ..setVital(Vital.age, 58)
        ..setVital(Vital.hr, 96);
      answer(cincinnati, 'face', 'Normal');
      answer(cincinnati, 'arm', 'Normal');
      answer(cincinnati, 'speech', 'Alterado');
      patient.register(scores.sheet, burns.sheet, at: now);
      final text = patientSummary(patient, now: now);
      // A partial sepsis count (FC > 90) is left out.
      expect(text, isNot(contains('Sépsis')));
      expect(text, contains('I — Identificação\n- Vítima de 58 anos'));
      expect(
        text,
        contains(
          'S — Situação atual\n'
          '- Início dos sintomas: 14:00 (há 1 h 00 min)\n'
          '- Via Verde AVC: Critérios cumpridos: contactar CODU\n'
          '- Cincinnati 1/3 (Suspeita de AVC)',
        ),
      );
      expect(text, contains('  - Sinais vitais: 58 anos · FC 96 bpm'));
      expect(
        text,
        contains(
          'R — Recomendações\n'
          '- Via Verde AVC: Disartria / afasia (Cincinnati); '
          'Idade ≥ 18 anos (Idade 58 anos); '
          'Início dos sintomas há 24 h ou menos (há 1 h 00 min)',
        ),
      );
    });

    test('ISBAR flags a child out of the normal range', () {
      scores
        ..setVital(Vital.age, 4)
        ..setVital(Vital.rr, 34)
        ..setVital(Vital.sbp, 75);
      patient.register(scores.sheet, burns.sheet, at: now);
      final text = patientSummary(patient, now: now);
      expect(text, contains('- FR elevada para a idade (normal 20–28 cpm)'));
      expect(text, contains('- Hipotensão para a idade (< 78 mmHg)'));
    });

    test('vitals alone can be registered', () {
      scores.setVital(Vital.pain, 6);
      expect(patient.hasUnsavedChanges(scores.sheet, burns.sheet), isTrue);
      final e = patient.register(scores.sheet, burns.sheet, at: now);
      expect(e.scores.vitals[Vital.pain], 6);
      expect(patient.hasUnsavedChanges(scores.sheet, burns.sheet), isFalse);
      scores.setVital(Vital.pain, 3);
      expect(patient.hasUnsavedChanges(scores.sheet, burns.sheet), isTrue);
    });
  });

  test('a clock time later than now is yesterday', () {
    expect(
      resolveClockTime(const TimeOfDay(hour: 14, minute: 10), now),
      DateTime(2026, 11, 5, 14, 10),
    );
    expect(
      resolveClockTime(const TimeOfDay(hour: 23, minute: 30), now),
      DateTime(2026, 11, 4, 23, 30),
    );
  });
}
