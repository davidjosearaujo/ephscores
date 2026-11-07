import 'package:ephscores/burn/burn.dart';
import 'package:ephscores/format.dart';
import 'package:ephscores/patient/patient.dart';
import 'package:ephscores/patient/summary.dart';
import 'package:ephscores/scores/adult.dart';
import 'package:ephscores/scores/score_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final t0 = DateTime(2026, 11, 3, 14, 20);
DateTime at(int minutes, [int seconds = 0]) =>
    t0.add(Duration(minutes: minutes, seconds: seconds));

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
    patient = PatientStore(prefs)..start(at: t0);
  });

  void gcs15() {
    for (final item in gcs.items) {
      scores.toggle('gcs', item, 0);
    }
  }

  group('evaluations', () {
    test('snapshots are unaffected by later edits', () {
      gcs15();
      burns.paint(burns.regions[1], BurnDegree.second);
      final first = patient.register(scores.sheet, burns.sheet, at: at(3));

      scores.toggle('gcs', gcs.items[1], 2); // verbal 5 -> 3
      burns.paint(burns.regions[1], BurnDegree.second); // clears it
      expect(scores.resultFor('gcs').value, 13);
      expect(first.scores.resultFor('gcs').value, 15);
      expect(first.burns.tbsa, 9);
      expect(burns.tbsa, 0);
    });

    test('each duration runs from the previous registration', () {
      gcs15();
      patient.register(scores.sheet, burns.sheet, at: at(2, 30));
      patient.register(scores.sheet, burns.sheet, at: at(10));
      expect(patient.evaluations.map((e) => e.duration), [
        const Duration(minutes: 2, seconds: 30),
        const Duration(minutes: 7, seconds: 30),
      ]);
      expect(patient.evaluationStartedAt, at(10));
    });

    test('unsaved changes compare with the last evaluation', () {
      expect(patient.hasUnsavedChanges(scores.sheet, burns.sheet), isFalse);
      gcs15();
      expect(patient.hasUnsavedChanges(scores.sheet, burns.sheet), isTrue);
      patient.register(scores.sheet, burns.sheet, at: at(1));
      expect(patient.hasUnsavedChanges(scores.sheet, burns.sheet), isFalse);

      // Re-selecting the same answer in a different order is not a change.
      scores.toggle('gcs', gcs.items[0], 0);
      scores.toggle('gcs', gcs.items[0], 0);
      expect(patient.hasUnsavedChanges(scores.sheet, burns.sheet), isFalse);

      burns.patient = BurnPatient.child;
      expect(patient.hasUnsavedChanges(scores.sheet, burns.sheet), isTrue);
    });

    test('delete any evaluation, finish, clear and start again', () {
      gcs15();
      patient
        ..register(scores.sheet, burns.sheet, at: at(1))
        ..register(scores.sheet, burns.sheet, at: at(4))
        ..register(scores.sheet, burns.sheet, at: at(6))
        ..removeAt(1);
      expect(patient.evaluations.map((e) => e.registeredAt), [at(1), at(6)]);
      // The later one keeps the duration it was recorded with.
      expect(patient.evaluations.last.duration, const Duration(minutes: 2));

      patient.finish(at: at(8));
      expect((patient.isActive, patient.isFinished), (false, true));
      patient.removeAt(0); // still allowed once finished
      expect(patient.evaluations, hasLength(1));

      patient.start(at: at(30));
      expect((patient.isActive, patient.evaluations.length), (true, 0));
      patient.clear();
      expect((patient.isActive, patient.startedAt), (false, null));
    });
  });

  group('persistence', () {
    test('patient and evaluations survive a restart', () {
      gcs15();
      burns.paint(burns.regions[0], BurnDegree.third);
      patient.register(scores.sheet, burns.sheet, at: at(4));

      final reloaded = PatientStore(prefs);
      expect(reloaded.isActive, isTrue);
      expect(reloaded.startedAt, t0);
      expect(reloaded.evaluations.single.registeredAt, at(4));
      expect(reloaded.evaluations.single.scores.resultFor('gcs').value, 15);
      expect(reloaded.evaluations.single.burns.tbsa, 4.5);
    });

    test('corrupt data starts with no patient', () async {
      await prefs.setString('patient.v2', '{"start": "yesterday"}');
      expect(PatientStore(prefs).startedAt, isNull);
      await prefs.setString('patient.v2', 'not json');
      expect(PatientStore(prefs).startedAt, isNull);
    });
  });

  group('summary', () {
    test('lists each evaluation with its scores and burns', () {
      gcs15();
      patient.register(scores.sheet, burns.sheet, at: at(2, 10));
      scores.toggle('gcs', gcs.items[1], 1); // verbal 4 -> GCS 14
      scores.toggle('news2', news2.items[0], 2); // partial NEWS2
      burns.paint(burns.regions[1], BurnDegree.second);
      burns.paint(burns.regions[4], BurnDegree.third);
      patient
        ..register(scores.sheet, burns.sheet, at: at(9))
        ..finish(at: at(35));

      expect(patientSummary(patient), '''
EPHScores — resumo ISBAR
Início: 03/11/2026 14:20 · fim 14:55 (35 min 00 s)

I — Identificação
- Idade não registada

S — Situação atual
- Sem alterações de gravidade

B — Antecedentes
- A completar: doenças, medicação habitual, alergias

A — Avaliação
- Avaliação 2 (14:29):
  - ECG: 14 — Ligeiro (O4 V4 M6)
  - NEWS2: 0 (incompleto, 1/7)
  - Queimados (adulto): SCQ 13,5% — 2.º grau 9%, 3.º grau 4,5%
- Evolução:
  - #1 14:22: ECG 15
  - #2 14:29: ECG 14 · NEWS2 0 · SCQ 13,5%

R — Recomendações
- Sem critérios de Via Verde''');
    });

    test('says when the patient is still open', () {
      expect(
        patientSummary(patient, now: at(61)),
        contains('em curso há 1 h 01 min'),
      );
    });
  });

  group('events', () {
    test('are stamped, edited, cleared and saved', () {
      patient
        ..setEvent(PatientEvent.codu, at(5))
        ..setEvent(PatientEvent.atVictim, at(1))
        ..setEvent(PatientEvent.toScene, at(-8));
      // Always in the order of the national form.
      expect(patient.events.keys, [
        PatientEvent.toScene,
        PatientEvent.atVictim,
        PatientEvent.codu,
      ]);
      patient.setEvent(PatientEvent.toScene, null);
      final restored = PatientStore(prefs);
      expect(restored.events, {
        PatientEvent.atVictim: at(1),
        PatientEvent.codu: at(5),
      });
      restored.start(at: at(60));
      expect(restored.events, isEmpty);
    });

    test('appear at the top of the summary', () {
      patient
        ..setEvent(PatientEvent.atVictim, at(1))
        ..setEvent(PatientEvent.codu, at(5));
      expect(
        patientSummary(patient, now: at(10)).split('\n')[2],
        'Horas: Chegada à vítima 14:21 · Contacto CODU 14:25',
      );
    });
  });

  group('format', () {
    test('numbers and percentages', () {
      expect(
        [formatNumber(9), formatNumber(4.5), formatPercent(22.5)],
        ['9', '4,5', '22,5%'],
      );
    });
    test('clock, date, timer and duration', () {
      final t = DateTime(2026, 1, 5, 7, 4);
      expect((formatClock(t), formatDate(t)), ('07:04', '05/01/2026'));
      expect(formatTimer(const Duration(minutes: 4, seconds: 9)), '04:09');
      expect(formatTimer(const Duration(hours: 1, seconds: 9)), '1:00:09');
      expect(formatDuration(const Duration(seconds: 45)), '45 s');
      expect(
        formatDuration(const Duration(minutes: 4, seconds: 9)),
        '4 min 09 s',
      );
      expect(
        formatDuration(const Duration(hours: 1, minutes: 4)),
        '1 h 04 min',
      );
    });
  });
}
