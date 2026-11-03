import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [ChangeNotifier] that saves itself as one JSON value under [_key] after
/// every change, so nothing is lost if the app is killed, and restores itself
/// on start-up, discarding data it can't read instead of crashing.
abstract class PersistedStore extends ChangeNotifier {
  PersistedStore(this._prefs, this._key);

  final SharedPreferences _prefs;
  final String _key;

  /// JSON-encodable snapshot of the state.
  Object toJson();

  /// Restores the state from a [toJson] snapshot. May throw on bad data.
  void restore(Object? json);

  /// Loads the saved state. Call at the end of the subclass constructor.
  @protected
  void load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      restore(jsonDecode(raw));
    } on Object catch (e) {
      debugPrint('Discarding saved $_key: $e');
    }
  }

  /// Notifies listeners and saves. Call after every mutation.
  @protected
  void changed() {
    notifyListeners();
    _prefs.setString(_key, jsonEncode(toJson()));
  }
}
