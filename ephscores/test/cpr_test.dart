import 'package:ephscores/cpr/cpr.dart';
import 'package:ephscores/cpr/metronome.dart';
import 'package:ephscores/patient/patient.dart';
import 'package:ephscores/patient/summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime at(int h, int m, [int s = 0]) => DateTime(2026, 11, 10, h, m, s);

void main() {
  test('counting cycles and shocks, with undo', () {
    var cpr = Cpr(startedAt: at(14, 0));
    expect(cpr.isOngoing, isTrue);
    expect(cpr.counts, '0 ciclos · 0 choques');
    // Before the first cycle the wait counts from the start.
    expect(cpr.sinceLastCycle(at(14, 1)), const Duration(minutes: 1));

    cpr = cpr.addCycle(at(14, 2)).addShock(at(14, 2, 10)).addCycle(at(14, 4));
    expect(cpr.cycles, 2);
    expect(cpr.counts, '2 ciclos · 1 choque');
    expect(cpr.sinceLastCycle(at(14, 5)), const Duration(minutes: 1));

    cpr = cpr.removeLastCycle();
    expect(cpr.cycleAt, [at(14, 2)]);
    // Undoing with nothing counted does nothing.
    expect(Cpr(startedAt: at(14, 0)).removeLastCycle().cycles, 0);
    expect(Cpr(startedAt: at(14, 0)).removeLastShock().shocks, 0);
  });

  test('ending, and going on after it', () {
    final done = Cpr(startedAt: at(14, 0))
        .addCycle(at(14, 2))
        .finish(CprEnd.rosc, at(14, 9));
    expect(done.isOngoing, isFalse);
    expect(done.duration(at(15, 0)), const Duration(minutes: 9));
    final again = done.resume();
    expect(again.isOngoing, isTrue);
    expect(again.end, isNull);
    expect(again.cycles, 1);
    expect(again.duration(at(14, 12)), const Duration(minutes: 12));
  });

  test('the SIV/SAV arrival is kept through the ending and shows in lines', () {
    var cpr = Cpr(startedAt: at(14, 0));
    expect(cpr.sivAt, isNull);
    cpr = cpr.withSiv(at(14, 12));
    expect(cpr.sivAt, at(14, 12));
    expect(cpr.lines(at(14, 15)), [
      'RCP em curso desde as 14:00 (há 15 min 00 s)',
      '  SIV/SAV no local às 14:12',
    ]);
    final done = cpr.finish(CprEnd.stopped, at(14, 30));
    expect(done.sivAt, at(14, 12));
    expect(done.resume().sivAt, at(14, 12));
    expect(done.resume().end, isNull);
    expect(Cpr.fromJson(done.toJson()).sivAt, at(14, 12));
    // Clearing it.
    expect(cpr.withSiv(null).sivAt, isNull);
    expect(cpr.withSiv(null).toJson().containsKey('siv'), isFalse);
  });

  test('JSON round trip', () {
    final cpr = Cpr(startedAt: at(14, 0))
        .addCycle(at(14, 2))
        .addShock(at(14, 3))
        .finish(CprEnd.stopped, at(14, 20));
    final back = Cpr.fromJson(cpr.toJson());
    expect(back.toJson(), cpr.toJson());
    expect(back.end, CprEnd.stopped);
    expect(back.cycleAt, [at(14, 2)]);
    final bare = Cpr.fromJson(Cpr(startedAt: at(14, 0)).toJson());
    expect(bare.isOngoing, isTrue);
    expect(bare.cycles, 0);
    // Unknown or damaged values are ignored.
    final odd = Cpr.fromJson({
      'start': at(14, 0).millisecondsSinceEpoch,
      'cycles': [at(14, 2).millisecondsSinceEpoch, 'x', null],
      'end': 'nope',
    });
    expect(odd.cycles, 1);
    expect(odd.end, isNull);
  });

  test('lines for the handover', () {
    final going = Cpr(startedAt: at(14, 0))
        .addCycle(at(14, 2))
        .addShock(at(14, 3));
    expect(going.lines(at(14, 5)), [
      'RCP em curso desde as 14:00 (há 5 min 00 s)',
      '  1 ciclo, o último às 14:02',
      '  1 choque, o último às 14:03',
    ]);
    expect(Cpr(startedAt: at(14, 0)).lines(at(14, 5), open: false), [
      'RCP iniciada às 14:00, sem hora de fim',
    ]);
    expect(
      going.finish(CprEnd.rosc, at(14, 9)).lines(at(15, 0)).first,
      'RCP das 14:00 às 14:09 (9 min 00 s): recuperação de circulação espontânea',
    );
  });

  test('the patient keeps it, in the summary and when restored', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final patient = PatientStore(prefs)..start(at: at(14, 0));
    expect(patient.cpr, isNull);
    patient.cpr = Cpr(startedAt: at(14, 1)).addCycle(at(14, 3));
    expect(
      patientSummary(patient, now: at(14, 6)),
      contains(
        'RCP em curso desde as 14:01 (há 5 min 00 s)\n  - 1 ciclo, o último às 14:03',
      ),
    );

    final restored = PatientStore(prefs);
    expect(restored.cpr!.cycles, 1);
    expect(restored.cpr!.startedAt, at(14, 1));

    patient.finish(at: at(14, 30));
    final saved = SavedPatient.fromJson(
      patient.toJson() as Map<String, dynamic>,
    )!;
    expect(saved.cpr!.isOngoing, isTrue);
    expect(
      patientSummary(saved),
      contains('RCP iniciada às 14:01, sem hora de fim'),
    );

    patient.start();
    expect(patient.cpr, isNull);
  });

  testWidgets('the metronome beats at its rate and keeps within the range', (
    tester,
  ) async {
    var beats = 0;
    final m = Metronome(onBeat: () => beats++);
    addTearDown(m.dispose);
    expect(m.rate, cprDefaultRate);

    m.start();
    expect(beats, 1, reason: 'the first beat is at once');
    expect(m.flash, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    expect(m.flash, isFalse);
    // 110 per minute: one beat every 545 ms.
    await tester.pump(const Duration(seconds: 6));
    expect(beats, 12);

    m.rate = 120;
    expect(m.rate, 120);
    m.rate = 500;
    expect(m.rate, cprMaxRate);
    m.rate = 10;
    expect(m.rate, cprMinRate);
    beats = 0;
    await tester.pump(const Duration(seconds: 6));
    expect(beats, 10, reason: '100 per minute: one beat every 600 ms');

    m.stop();
    expect(m.running, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(beats, 10);
    m.toggle();
    expect(m.running, isTrue);
    m.stop();
  });
}
