import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adult.dart';
import 'model.dart';
import 'pediatric.dart';

final allScores = {
  for (final s in [...adultScores, ...pediatricScores]) s.id: s,
};

/// Answers for every score of the current patient, saved on every change so
/// nothing is lost if the app is killed mid-assessment.
class ScoreStore extends ChangeNotifier {
  ScoreStore(this._prefs) {
    _load();
  }

  static const _key = 'scores.v2';

  final SharedPreferences _prefs;
  final Map<String, Map<String, Set<int>>> _answers = {};

  Answers answersFor(String scoreId) => Answers(_answers[scoreId] ?? const {});

  ScoreResult resultFor(String scoreId) =>
      allScores[scoreId]!.resultFor(answersFor(scoreId), resultFor);

  bool get isEmpty => _answers.values.every((m) => m.isEmpty);

  bool hasAnswers(String scoreId) => _answers[scoreId]?.isNotEmpty ?? false;

  /// Selects or deselects an option, honouring single/multi/exclusive rules.
  void toggle(String scoreId, ScoreItem item, int index) {
    final score = _answers.putIfAbsent(scoreId, () => {});
    final current = {...?score[item.id]};
    if (current.contains(index)) {
      current.remove(index);
    } else if (!item.multi || item.options[index].exclusive) {
      current
        ..clear()
        ..add(index);
    } else {
      current
        ..removeWhere((i) => item.options[i].exclusive)
        ..add(index);
    }
    if (current.isEmpty) {
      score.remove(item.id);
    } else {
      score[item.id] = current;
    }
    _changed();
  }

  void reset(String scoreId) {
    _answers.remove(scoreId);
    _changed();
  }

  void resetAll() {
    _answers.clear();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _prefs.setString(
      _key,
      jsonEncode({
        for (final MapEntry(key: id, value: items) in _answers.entries)
          id: {for (final e in items.entries) e.key: e.value.toList()},
      }),
    );
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      for (final MapEntry(key: id, value: items) in data.entries) {
        final score = allScores[id];
        if (score == null) continue;
        final parsed = <String, Set<int>>{};
        for (final MapEntry(key: itemId, value: picks)
            in (items as Map).entries) {
          final item = score.items.where((it) => it.id == itemId).firstOrNull;
          if (item == null) continue;
          final valid = (picks as List)
              .cast<int>()
              .where((i) => i >= 0 && i < item.options.length)
              .toSet();
          if (valid.isNotEmpty) parsed[itemId as String] = valid;
        }
        _answers[id] = parsed;
      }
    } on Object catch (e) {
      // Corrupt or outdated data: start clean rather than crash.
      debugPrint('Discarding saved scores: $e');
    }
  }
}
