import 'package:ephscores/burn/burn.dart';
import 'package:ephscores/obstetrics/obstetrics.dart';
import 'package:ephscores/patient/patient.dart';
import 'package:ephscores/patient/summary.dart';
import 'package:ephscores/scores/model.dart';
import 'package:ephscores/scores/score_store.dart';
import 'package:ephscores/vitals/vitals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

VitalSigns vitals(Map<Vital, num> values) {
  final v = VitalSigns();
  for (final MapEntry(:key, :value) in values.entries) {
    v.set(key, value);
  }
  return v;
}

/// The amber and red alerts, with their colour.
List<String> flags(Pregnancy p, [Map<Vital, num> v = const {}]) => [
  for (final (s, text) in pregnancyAlerts(p, vitals(v)))
    if (s.isAlert) '${s.name}: $text',
];

void main() {
  group('gestational age', () {
    test('bands of the manual', () {
      expect(Term.of(23), Term.notViable);
      expect(Term.of(24), Term.preterm);
      expect(Term.of(36), Term.preterm);
      expect(Term.of(37), Term.term);
    });

    test('from the last period', () {
      final age = Pregnancy.fromLastPeriod(
        DateTime(2026, 2, 3),
        DateTime(2026, 11, 8, 14, 30),
      );
      expect(age, (weeks: 39, days: 5));
    });

    test('label', () {
      expect(const Pregnancy(weeks: 38).gestationLabel, '38 semanas');
      expect(
        const Pregnancy(weeks: 38, days: 1).gestationLabel,
        '38 semanas e 1 dia',
      );
      expect(const Pregnancy().gestationLabel, isNull);
    });
  });

  group('alerts', () {
    test('only reminders when all is well', () {
      const p = Pregnancy(weeks: 30);
      expect(flags(p, {Vital.sbp: 120, Vital.dbp: 70, Vital.spo2: 97}), []);
      expect(
        [for (final (_, t) in pregnancyAlerts(p, VitalSigns())) t],
        containsAll([
          'SpO₂ alvo: 92–96%',
          'Posicionar e transportar em decúbito lateral esquerdo',
          'NEWS2 não validada na gravidez',
        ]),
      );
    });

    test('hypertension from 20 weeks, red with signs of severity', () {
      const p = Pregnancy(weeks: 32);
      expect(flags(p, {Vital.sbp: 150, Vital.dbp: 85}), [
        'warning: Hipertensão na gravidez (PA ≥ 140/90 mmHg)',
      ]);
      expect(flags(p.copyWith(severe: {SevereSign.vision}), {Vital.dbp: 95}), [
        'danger: Hipertensão com sinais de gravidade: comunicar ao CODU',
      ]);
      // Before 20 weeks it isn't hypertension of pregnancy.
      expect(flags(const Pregnancy(weeks: 16), {Vital.sbp: 150}), isEmpty);
    });

    test('fluid, twins, breech and low saturation', () {
      const p = Pregnancy(
        twins: true,
        presentation: Presentation.breech,
        fluid: {FluidSign.meconium},
      );
      expect(flags(p, {Vital.spo2: 90}), [
        'warning: Líquido amniótico esverdeado: comunicar ao CODU',
        'warning: Gemelar: o parto deve ocorrer no hospital',
        'warning: Pélvica: o parto deve ocorrer na maternidade',
        'warning: SpO₂ abaixo do alvo de 92–96%',
      ]);
    });
  });

  group('birth', () {
    final born = DateTime(2026, 11, 8, 3, 10);

    test('APGAR per minute', () {
      final b = Birth(
        bornAt: born,
        apgar: {
          1: {'color': 1, 'hr': 0, 'reflex': 0, 'tone': 1, 'breathing': 0},
          5: {'color': 0},
        },
      );
      expect(b.apgarAt(1)!.value, 8);
      expect(b.apgarAt(1)!.severity, Severity.ok);
      expect(b.apgarAt(5)!.complete, isFalse);
      expect(b.apgarAt(10), isNull);
    });

    test('haemorrhage after the placenta: soft uterus, heavy bleeding or '
        'raised shock index', () {
      final none = VitalSigns();
      final shock = vitals({Vital.hr: 130, Vital.sbp: 90});
      final after = Birth(bornAt: born, placentaAt: born);
      expect(Birth(bornAt: born, uterusFirm: false).haemorrhage(none), isFalse);
      expect(after.haemorrhage(none), isFalse);
      expect(after.copyWith(uterusFirm: () => true).haemorrhage(none), isFalse);
      expect(after.copyWith(uterusFirm: () => false).haemorrhage(none), isTrue);
      expect(after.copyWith(heavyBleeding: true).haemorrhage(none), isTrue);
      expect(after.haemorrhage(shock), isTrue);
    });

    test('lines for the handover', () {
      final b = Birth(
        bornAt: born,
        clampedAt: born.add(const Duration(minutes: 1)),
        placentaAt: born.add(const Duration(minutes: 14)),
        apgar: {
          1: {'color': 1, 'hr': 0, 'reflex': 0, 'tone': 1, 'breathing': 0},
        },
        uterusFirm: true,
      );
      expect(birthLines(b), [
        'Nascimento às 03:10',
        'Clampagem do cordão às 03:11',
        'APGAR: 1.º min 8',
        'Dequitadura às 03:24',
        'Útero contraído',
      ]);
    });
  });

  test('JSON round trip, ignoring bad APGAR answers', () {
    final p = Pregnancy(
      weeks: 39,
      days: 2,
      gesta: 2,
      para: 1,
      twins: true,
      presentation: Presentation.cephalic,
      booklet: true,
      watersAt: DateTime(2026, 11, 8, 2, 40),
      fluid: const {FluidSign.blood},
      severe: const {SevereSign.headache},
      birth: Birth(
        bornAt: DateTime(2026, 11, 8, 3, 10),
        apgar: const {
          1: {'color': 2},
        },
        uterusFirm: false,
        heavyBleeding: true,
      ),
    );
    final json = p.toJson();
    final back = Pregnancy.fromJson(json);
    expect(back.toJson(), json);
    expect(
      Birth.fromJson({
        'born': 0,
        'apgar': {
          '1': {'color': 7, 'hr': 1, 'nope': 0},
          '3': {'color': 1},
        },
      }).apgar,
      {
        1: {'hr': 1},
      },
    );
  });

  test('kept with the patient and in the ISBAR summary', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final start = DateTime(2026, 11, 8, 3);
    final patient = PatientStore(prefs)..start(at: start);
    final scores = ScoreStore(prefs)
      ..setVital(Vital.sbp, 160)
      ..setVital(Vital.dbp, 100);
    patient.pregnancy = Pregnancy(
      weeks: 36,
      gesta: 1,
      para: 0,
      severe: const {SevereSign.headache},
      birth: Birth(bornAt: start.add(const Duration(minutes: 10))),
    );
    patient.register(
      scores.sheet,
      BurnStore(prefs).sheet,
      at: start.add(const Duration(minutes: 12)),
    );

    final restored = PatientStore(prefs);
    expect(restored.pregnancy!.toJson(), patient.pregnancy!.toJson());

    final text = patientSummary(
      patient,
      now: start.add(const Duration(minutes: 20)),
    );
    expect(text, contains('Grávida: 36 semanas (pré-termo) · G1 P0'));
    expect(
      text,
      contains('- Hipertensão com sinais de gravidade: comunicar ao CODU'),
    );
    expect(text, contains('- Parto:\n  - Nascimento às 03:10'));
    // Reminders stay off the handover.
    expect(text, isNot(contains('NEWS2 não validada')));

    patient.clear();
    expect(patient.pregnancy, isNull);
  });
}
