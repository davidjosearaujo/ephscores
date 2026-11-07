import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../patient/patient.dart';
import 'history.dart';

const _keyName = 'history.key.v1';
const _fileName = 'history.v1.db';

/// History in an SQLCipher database. The 256-bit key is random, made on
/// first use and kept in the Android Keystore through
/// flutter_secure_storage; without it the file can't be read.
class SqliteHistoryStore extends HistoryStore {
  SqliteHistoryStore(this._db) {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        id INTEGER PRIMARY KEY,
        finished INTEGER NOT NULL,
        data TEXT NOT NULL
      )
    ''');
  }

  /// Opens (or creates) the encrypted database at [path] with [key].
  /// Throws if this SQLite build can't encrypt, so patient data is never
  /// written in the clear.
  factory SqliteHistoryStore.open(String path, Uint8List key) {
    final db = sqlite3.open(path);
    try {
      _unlock(db, key);
    } on Object {
      db.close();
      rethrow;
    }
    return SqliteHistoryStore(db);
  }

  /// An encrypted database in memory, for tests.
  @visibleForTesting
  factory SqliteHistoryStore.inMemory(Uint8List key) {
    final db = sqlite3.openInMemory();
    _unlock(db, key);
    return SqliteHistoryStore(db);
  }

  static void _unlock(Database db, Uint8List key) {
    final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    db.execute("PRAGMA key = \"x'$hex'\"");
    // Only SQLCipher answers this; plain SQLite returns nothing.
    final cipher = db.select('PRAGMA cipher_version');
    if (cipher.isEmpty) {
      throw StateError('SQLite build without encryption');
    }
    // Fails here, not later, if the key doesn't match the file.
    db.select('SELECT count(*) FROM sqlite_master');
  }

  final Database _db;

  @override
  Future<List<HistoryEntry>> entries() async => [
    for (final row in _db.select(
      'SELECT id, data FROM patients ORDER BY id DESC',
    ))
      ?HistoryStore.parse(row['id'] as int, row['data'] as String),
  ];

  @override
  Future<void> save(PatientStore patient) async {
    if (!patient.isFinished) return;
    _db.execute(
      'INSERT OR REPLACE INTO patients (id, finished, data) VALUES (?, ?, ?)',
      [
        HistoryStore.idOf(patient),
        patient.finishedAt!.millisecondsSinceEpoch,
        jsonEncode(patient.toJson()),
      ],
    );
    notifyListeners();
  }

  @override
  Future<void> delete(int id) async {
    _db.execute('DELETE FROM patients WHERE id = ?', [id]);
    notifyListeners();
  }

  @override
  Future<void> deleteAll() async {
    _db.execute('DELETE FROM patients');
    // Don't leave deleted pages behind in the file.
    _db.execute('VACUUM');
    notifyListeners();
  }

  @override
  Future<void> purge({DateTime? now}) async {
    final limit = (now ?? DateTime.now()).subtract(historyRetention);
    _db.execute('DELETE FROM patients WHERE finished < ?', [
      limit.millisecondsSinceEpoch,
    ]);
    if (_db.updatedRows > 0) notifyListeners();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }
}

/// Opens the history in the app's private storage, creating the key on
/// first use. If the key is lost (e.g. the Keystore was reset) the old file
/// can't be read and is replaced by an empty one. Returns an unavailable
/// store if encryption can't be set up.
Future<HistoryStore> openHistory() async {
  try {
    const storage = FlutterSecureStorage();
    var encoded = await storage.read(key: _keyName);
    if (encoded == null) {
      final random = Random.secure();
      encoded = base64Encode(List.generate(32, (_) => random.nextInt(256)));
      await storage.write(key: _keyName, value: encoded);
    }
    final key = base64Decode(encoded);
    final dir = await getApplicationSupportDirectory();
    final path = '${dir.path}/$_fileName';
    try {
      return SqliteHistoryStore.open(path, key);
    } on SqliteException catch (e) {
      debugPrint('History unreadable with this key, starting again: $e');
      await File(path).delete();
      return SqliteHistoryStore.open(path, key);
    }
  } on Object catch (e) {
    debugPrint('History unavailable: $e');
    return MemoryHistoryStore(available: false);
  }
}
