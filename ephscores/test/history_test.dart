import 'dart:io';
import 'dart:typed_data';

import 'package:ephscores/burn/burn.dart';
import 'package:ephscores/history/history.dart';
import 'package:ephscores/history/sqlite_history.dart';
import 'package:ephscores/patient/patient.dart';
import 'package:ephscores/scores/score_store.dart';
import 'package:ephscores/vitals/vitals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

final t0 = DateTime(2026, 11, 7, 14, 0);
final key = Uint8List.fromList(List.generate(32, (i) => i * 7 % 256));

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// A finished patient with one evaluation, started at [start].
  PatientStore finished(DateTime start) {
    final scores = ScoreStore(prefs)..setVital(Vital.hr, 112);
    return PatientStore(prefs)
      ..start(at: start)
      ..setEvent(PatientEvent.atVictim, start)
      ..register(
        scores.sheet,
        BurnSheet(),
        at: start.add(const Duration(minutes: 5)),
      )
      ..finish(at: start.add(const Duration(minutes: 20)));
  }

  for (final (name, make) in <(String, HistoryStore Function())>[
    ('memory', MemoryHistoryStore.new),
    ('sqlcipher', () => SqliteHistoryStore.inMemory(key)),
  ]) {
    group(name, () {
      test(
        'keeps finished patients, newest first, and reads them back',
        () async {
          final h = make();
          await h.save(finished(t0));
          await h.save(finished(t0.add(const Duration(hours: 2))));
          final list = await h.entries();
          expect(list.map((e) => e.startedAt), [
            t0.add(const Duration(hours: 2)),
            t0,
          ]);
          final p = list.last.patient;
          expect(p.evaluations.single.scores.vitals[Vital.hr], 112);
          expect(p.events[PatientEvent.atVictim], t0);
          expect(
            list.last.expiresAt,
            t0.add(const Duration(minutes: 20, days: 30)),
          );
        },
      );

      test('saving again replaces; open patients are not saved', () async {
        final h = make();
        final p = finished(t0);
        await h.save(p);
        p.removeAt(0);
        await h.save(p);
        expect((await h.entries()).single.patient.evaluations, isEmpty);
        await h.save(
          PatientStore(prefs)..start(at: t0.add(const Duration(days: 1))),
        );
        expect(await h.entries(), hasLength(1));
      });

      test('deletes one, all, and what is older than 30 days', () async {
        final h = make();
        for (final d in [0, 10, 40]) {
          await h.save(finished(t0.subtract(Duration(days: d))));
        }
        await h.purge(now: t0);
        expect((await h.entries()).map((e) => e.startedAt), [
          t0,
          t0.subtract(const Duration(days: 10)),
        ]);
        await h.delete(t0.millisecondsSinceEpoch);
        expect(await h.entries(), hasLength(1));
        await h.deleteAll();
        expect(await h.entries(), isEmpty);
      });
    });
  }

  test('the web keeps nothing', () async {
    final h = MemoryHistoryStore(available: false);
    await h.save(finished(t0));
    expect(await h.entries(), isEmpty);
  });

  group('file', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('history'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('is encrypted on disk and needs the key', () async {
      final path = '${dir.path}/h.db';
      final h = SqliteHistoryStore.open(path, key);
      await h.save(finished(t0));
      h.dispose();

      // No readable SQLite header and none of the patient's data.
      final bytes = File(path).readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
      expect(String.fromCharCodes(bytes), isNot(contains('evaluations')));

      // Wrong key: refused.
      final wrong = Uint8List.fromList(List.filled(32, 1));
      expect(
        () => SqliteHistoryStore.open(path, wrong),
        throwsA(isA<SqliteException>()),
      );

      // Right key: everything is there.
      final again = SqliteHistoryStore.open(path, key);
      expect((await again.entries()).single.startedAt, t0);
      again.dispose();
    });
  });
}
