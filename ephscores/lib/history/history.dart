/// History of finished patients, kept on the device for [historyRetention]
/// and then deleted. On Android it is an SQLCipher-encrypted database
/// ([openHistory]); the web app keeps no history.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../patient/patient.dart';

/// How long a finished patient is kept.
const historyRetention = Duration(days: 30);

/// One finished patient in the history.
class HistoryEntry {
  HistoryEntry({required this.id, required this.patient});

  /// The patient's start time in milliseconds, which identifies it.
  final int id;
  final SavedPatient patient;

  DateTime get startedAt => patient.startedAt!;
  DateTime get finishedAt => patient.finishedAt!;

  /// When it will be deleted automatically.
  DateTime get expiresAt => finishedAt.add(historyRetention);
}

/// Where finished patients are kept. Newest first.
abstract class HistoryStore extends ChangeNotifier {
  /// False where the platform keeps no history (the web app).
  bool get available => true;

  Future<List<HistoryEntry>> entries();

  /// Adds or replaces the finished patient [patient].
  Future<void> save(PatientStore patient);

  Future<void> delete(int id);

  Future<void> deleteAll();

  /// Deletes what finished before [now] minus [historyRetention].
  Future<void> purge({DateTime? now});

  /// The id a patient is kept under: its start time.
  static int idOf(PatientRecord patient) =>
      patient.startedAt!.millisecondsSinceEpoch;

  /// Rows as stored: the patient's JSON (the format of
  /// [PatientStore.toJson]) by id. For implementations.
  @protected
  static HistoryEntry? parse(int id, String json) {
    try {
      final saved = SavedPatient.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      if (saved == null || saved.finishedAt == null) return null;
      return HistoryEntry(id: id, patient: saved);
    } on Object catch (e) {
      debugPrint('Skipping unreadable history entry $id: $e');
      return null;
    }
  }
}

/// History kept in memory only: used in tests, and on the web, where it is
/// [available] false and saves nothing.
class MemoryHistoryStore extends HistoryStore {
  MemoryHistoryStore({this.available = true});

  @override
  final bool available;

  final _rows = <int, String>{};

  @override
  Future<List<HistoryEntry>> entries() async => [
    for (final id in _rows.keys.toList()..sort((a, b) => b.compareTo(a)))
      ?HistoryStore.parse(id, _rows[id]!),
  ];

  @override
  Future<void> save(PatientStore patient) async {
    if (!available || !patient.isFinished) return;
    _rows[HistoryStore.idOf(patient)] = jsonEncode(
      patient.toJson(),
    );
    notifyListeners();
  }

  @override
  Future<void> delete(int id) async {
    if (_rows.remove(id) != null) notifyListeners();
  }

  @override
  Future<void> deleteAll() async {
    _rows.clear();
    notifyListeners();
  }

  @override
  Future<void> purge({DateTime? now}) async {
    final limit = (now ?? DateTime.now()).subtract(historyRetention);
    final before = _rows.length;
    _rows.removeWhere(
      (id, json) =>
          HistoryStore.parse(id, json)?.finishedAt.isBefore(limit) ?? true,
    );
    if (_rows.length != before) notifyListeners();
  }
}
