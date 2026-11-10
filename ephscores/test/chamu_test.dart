import 'package:ephscores/patient/chamu.dart';
import 'package:ephscores/patient/patient.dart';
import 'package:ephscores/patient/summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChamuQuestion q(String id) => chamuQuestions.firstWhere((q) => q.id == id);

void main() {
  group('picking', () {
    test('circumstances take one answer', () {
      final c = const Chamu().toggle(q('c'), 'fall').toggle(q('c'), 'road');
      expect(c.picked(q('c')), {'road'});
    });

    test('several diseases, and "none" rules out the others', () {
      var c = const Chamu();
      c = c.toggle(q('h'), 'diabetes').toggle(q('h'), 'heart');
      expect(c.picked(q('h')), {'diabetes', 'heart'});
      c = c.toggle(q('h'), 'none');
      expect(c.picked(q('h')), {'none'});
      c = c.toggle(q('h'), 'stroke');
      expect(c.picked(q('h')), {'stroke'});
      c = c.toggle(q('h'), 'stroke');
      expect(c.isEmpty, isTrue);
    });

    test('allergies: "none" and "unknown" each rule out the rest', () {
      var c = const Chamu().toggle(q('a'), 'drug').toggle(q('a'), 'latex');
      expect(c.picked(q('a')), {'drug', 'latex'});
      c = c.toggle(q('a'), 'unknown');
      expect(c.picked(q('a')), {'unknown'});
      c = c.toggle(q('a'), 'none');
      expect(c.picked(q('a')), {'none'});
      c = c.toggle(q('a'), 'food');
      expect(c.picked(q('a')), {'food'});
    });

    test('notes are trimmed and dropped when empty', () {
      var c = const Chamu().withNote('m', '  varfarina ');
      expect(c.note('m'), 'varfarina');
      c = c.withNote('m', '   ');
      expect(c.notes, isEmpty);
    });
  });

  group('the text box', () {
    test('opens for "Outra", not for the other circumstances', () {
      var c = const Chamu().toggle(q('c'), 'fall');
      expect(c.showsNote(q('c')), isFalse);
      c = c.toggle(q('c'), 'other');
      expect(c.showsNote(q('c')), isTrue);
    });

    test('opens for any allergy, not for none or unknown', () {
      expect(const Chamu().toggle(q('a'), 'food').showsNote(q('a')), isTrue);
      expect(const Chamu().toggle(q('a'), 'none').showsNote(q('a')), isFalse);
      expect(
        const Chamu().toggle(q('a'), 'unknown').showsNote(q('a')),
        isFalse,
      );
    });

    test('medication is only text', () {
      expect(q('m').textOnly, isTrue);
      expect(const Chamu().showsNote(q('m')), isTrue);
      expect(const Chamu().lineFor(q('m')), isNull);
      expect(
        const Chamu().withNote('m', 'Varfarina, metformina').lineFor(q('m')),
        'Varfarina, metformina',
      );
    });
  });

  group('one line per letter', () {
    test('picked options in order, with the text on "Outra"', () {
      final c = const Chamu()
          .toggle(q('h'), 'diabetes')
          .toggle(q('h'), 'other')
          .toggle(q('h'), 'hypertension')
          .withNote('h', 'gota');
      expect(c.lineFor(q('h')), 'Hipertensão, Diabetes, Outra: gota');
      expect(c.answered(q('h')), isTrue);
    });

    test('allergies carry the text on the first option picked', () {
      final c = const Chamu()
          .toggle(q('a'), 'food')
          .toggle(q('a'), 'drug')
          .withNote('a', 'penicilina, amendoim');
      expect(
        c.lineFor(q('a')),
        'Medicamentos: penicilina, amendoim, Alimentos',
      );
    });

    test('text left under a closed box is not an answer', () {
      var c = const Chamu().toggle(q('c'), 'other').withNote('c', 'caiu');
      expect(c.lineFor(q('c')), 'Outra: caiu');
      c = c.toggle(q('c'), 'other');
      expect(c.lineFor(q('c')), isNull);
      c = c.toggle(q('c'), 'fall');
      expect(c.lineFor(q('c')), 'Queda');
    });
  });

  test('JSON round trip drops unknown options', () {
    final c = const Chamu()
        .toggle(q('a'), 'drug')
        .withNote('a', 'penicilina')
        .withLastMeal(DateTime(2026, 11, 8, 13, 5));
    expect(Chamu.fromJson(c.toJson()).toJson(), c.toJson());
    final loaded = Chamu.fromJson({
      'picks': {
        'a': ['nope', 'latex'],
        'm': ['anticoagulant'], // medication has no list any more
        'zz': ['x'],
      },
    });
    expect(loaded.picked(q('a')), {'latex'});
    expect(loaded.picks.keys, ['a']);
  });

  test('counts the letters answered', () {
    var c = const Chamu();
    expect(c.answeredCount, 0);
    c = c.toggle(q('c'), 'fall').withNote('m', 'insulina');
    expect(c.answeredCount, 2);
    c = c.withLastMeal(DateTime(2026, 11, 8, 12));
    expect(c.answeredCount, 3);
  });

  test('kept with the patient and in the handover', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final start = DateTime(2026, 11, 8, 14);
    final patient = PatientStore(prefs)..start(at: start);
    expect(backgroundLines(patient.chamu), [
      'A completar: antecedentes, alergias, medicação habitual, '
          'última refeição',
    ]);

    patient.chamu = patient.chamu
        .toggle(q('c'), 'fall')
        .toggle(q('a'), 'none')
        .withNote('m', 'Varfarina')
        .withLastMeal(DateTime(2026, 11, 8, 12, 30));
    expect(PatientStore(prefs).chamu.toJson(), patient.chamu.toJson());

    expect(backgroundLines(patient.chamu), [
      'Alergias: Sem alergias conhecidas',
      'Medicação habitual: Varfarina',
      'Última refeição: 12:30',
      'A completar: antecedentes',
    ]);
    final text = patientSummary(
      patient,
      now: start.add(const Duration(minutes: 5)),
    );
    expect(text, contains('- Circunstâncias: Queda'));
    expect(text, contains('- Medicação habitual: Varfarina'));

    patient.clear();
    expect(patient.chamu.isEmpty, isTrue);
  });
}
