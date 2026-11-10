import 'package:ephscores/burn/burn.dart';
import 'package:ephscores/injuries/injuries.dart';
import 'package:ephscores/patient/patient.dart';
import 'package:ephscores/patient/summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

BodyRegion region(String id, [BurnPatient p = BurnPatient.adult]) =>
    bodyRegions[p]!.firstWhere((r) => r.id == id);

void main() {
  test('ticking types per region', () {
    final arm = region('front.rightArm');
    var m = const InjuryMap();
    expect(m.isEmpty, isTrue);
    m = m.toggle(arm, InjuryType.fracture).toggle(arm, InjuryType.pain);
    expect(m.typesOf(arm), {InjuryType.fracture, InjuryType.pain});
    // The worst level shows.
    expect(m.levelOf(arm), InjuryLevel.serious);
    m = m.toggle(arm, InjuryType.bleeding);
    expect(m.levelOf(arm), InjuryLevel.major);
    expect(m.affected, [arm]);
    expect(m.levelOf(region('back.head')), isNull);

    m = m.clearRegion(arm);
    expect(m.isEmpty, isTrue);
  });

  test('adult and child bodies keep their own marks', () {
    final head = region('front.head');
    var m = const InjuryMap().toggle(head, InjuryType.wound);
    final child = m.withPatient(BurnPatient.child);
    expect(child.affected, isEmpty);
    expect(child.withPatient(BurnPatient.adult).affected, [head]);
    expect(child.isEmpty, isFalse);
  });

  test('lines for the handover', () {
    final m = const InjuryMap()
        .toggle(region('front.rightArm'), InjuryType.pain)
        .toggle(region('front.rightArm'), InjuryType.fracture)
        .toggle(region('back.head'), InjuryType.wound);
    expect(m.lines(), [
      'Membro superior direito (anterior): fratura suspeita, dor',
      'Cabeça (posterior): ferida',
    ]);
  });

  test('JSON round trip drops unknown regions and types', () {
    final m = const InjuryMap(patient: BurnPatient.child)
        .toggle(region('front.torso', BurnPatient.child), InjuryType.bleeding);
    expect(InjuryMap.fromJson(m.toJson()).toJson(), m.toJson());
    final loaded = InjuryMap.fromJson({
      'patient': 'adult',
      'adult': {
        'front.torso': ['fracture'], // a child-only region
        'front.head': ['nope', 'wound'],
      },
    });
    expect(loaded.lines(), ['Cabeça (anterior): ferida']);
  });

  test('kept with the patient and in the handover', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final start = DateTime(2026, 11, 8, 14);
    final patient = PatientStore(prefs)..start(at: start);
    patient.injuries = patient.injuries.toggle(
      region('front.lowerTorso'),
      InjuryType.penetrating,
    );
    expect(PatientStore(prefs).injuries.toJson(), patient.injuries.toJson());
    final text = patientSummary(patient, now: start);
    expect(
      text,
      contains('- Lesões:\n  - Abdómen (anterior): ferida penetrante'),
    );
    patient.clear();
    expect(patient.injuries.isEmpty, isTrue);
  });
}
