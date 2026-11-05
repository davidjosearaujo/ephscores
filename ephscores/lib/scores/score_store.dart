import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../persistence.dart';
import '../vitals/vitals.dart';
import 'adult.dart';
import 'model.dart';
import 'pediatric.dart';

final allScores = {
  for (final s in [...adultScores, ...pediatricScores]) s.id: s,
};

/// Key of the vital signs in [ScoreSheet.toJson], next to the score ids.
const _vitalsKey = 'vitals';

/// The answers to every score and the vital signs at one moment, and their
/// results. The store keeps the live sheet; each registered evaluation keeps
/// a [copy].
class ScoreSheet {
  ScoreSheet() : _answers = {}, vitals = VitalSigns();

  ScoreSheet._(this._answers, this.vitals);

  /// Parses [toJson] output, dropping unknown scores, items and options.
  /// Sheets saved before vital signs existed simply have none.
  factory ScoreSheet.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    final answers = <String, Map<String, Set<int>>>{};
    for (final MapEntry(key: id, value: items) in map.entries) {
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
      if (parsed.isNotEmpty) answers[id] = parsed;
    }
    final vitals = map[_vitalsKey];
    return ScoreSheet._(
      answers,
      vitals == null ? VitalSigns() : VitalSigns.fromJson(vitals),
    );
  }

  final Map<String, Map<String, Set<int>>> _answers;

  /// Vital signs; items bound to them are answered from here.
  final VitalSigns vitals;

  Answers _manual(String scoreId) => Answers(_answers[scoreId] ?? const {});

  /// The option the vital signs select for [item], if they decide it.
  int? fromVitals(String scoreId, ScoreItem item) =>
      item.vital?.pick(vitals, _manual(scoreId));

  /// The manual answers, with the items the vital signs decide replaced by
  /// their value.
  Answers answersFor(String scoreId) {
    final manual = _answers[scoreId] ?? const <String, Set<int>>{};
    Map<String, Set<int>>? merged;
    for (final item in allScores[scoreId]!.items) {
      final pick = fromVitals(scoreId, item);
      if (pick != null) (merged ??= {...manual})[item.id] = {pick};
    }
    return Answers(merged ?? manual);
  }

  ScoreResult resultFor(String scoreId) =>
      allScores[scoreId]!.resultFor(answersFor(scoreId), resultFor);

  bool get isEmpty => vitals.isEmpty && _answers.values.every((m) => m.isEmpty);

  /// Has answers given by hand (vital signs aside).
  bool hasAnswers(String scoreId) => _answers[scoreId]?.isNotEmpty ?? false;

  /// Answered by hand, or completed by the vital signs alone (NEWS2, or RTS
  /// once the GCS is in).
  bool isFilled(String scoreId) =>
      hasAnswers(scoreId) || resultFor(scoreId).complete;

  /// Filled scores, in display order.
  List<ScoreDefinition> get answered => [
    for (final s in allScores.values)
      if (isFilled(s.id)) s,
  ];

  /// Deep copy: later changes to this sheet don't affect it.
  ScoreSheet copy() => ScoreSheet._({
    for (final MapEntry(key: id, value: items) in _answers.entries)
      id: {
        for (final e in items.entries) e.key: {...e.value},
      },
  }, vitals.copy());

  /// Sorted, so equal sheets always encode to the same string.
  Map<String, Object> toJson() => {
    for (final id in _answers.keys.toList()..sort())
      if (_answers[id]!.isNotEmpty)
        id: {
          for (final item in _answers[id]!.keys.toList()..sort())
            item: _answers[id]![item]!.toList()..sort(),
        },
    if (!vitals.isEmpty) _vitalsKey: vitals.toJson(),
  };

  bool sameAs(ScoreSheet other) =>
      jsonEncode(toJson()) == jsonEncode(other.toJson());
}

/// Answers for every score of the current patient, saved on every change so
/// nothing is lost if the app is killed mid-assessment.
class ScoreStore extends PersistedStore {
  ScoreStore(SharedPreferences prefs) : super(prefs, 'scores.v2') {
    load();
  }

  ScoreSheet _sheet = ScoreSheet();

  /// The live answers. Take a [ScoreSheet.copy] to keep a snapshot.
  ScoreSheet get sheet => _sheet;

  Answers answersFor(String scoreId) => _sheet.answersFor(scoreId);

  ScoreResult resultFor(String scoreId) => _sheet.resultFor(scoreId);

  bool get isEmpty => _sheet.isEmpty;

  bool hasAnswers(String scoreId) => _sheet.hasAnswers(scoreId);

  bool isFilled(String scoreId) => _sheet.isFilled(scoreId);

  VitalSigns get vitals => _sheet.vitals;

  int? fromVitals(String scoreId, ScoreItem item) =>
      _sheet.fromVitals(scoreId, item);

  /// Sets or, with null, clears one vital sign.
  void setVital(Vital vital, num? value) {
    _sheet.vitals.set(vital, value);
    changed();
  }

  set newConfusion(bool value) {
    _sheet.vitals.newConfusion = value;
    changed();
  }

  void clearVitals() {
    _sheet.vitals.clear();
    changed();
  }

  /// Selects or deselects an option, honouring single/multi/exclusive rules.
  void toggle(String scoreId, ScoreItem item, int index) {
    final score = _sheet._answers.putIfAbsent(scoreId, () => {});
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
    changed();
  }

  void reset(String scoreId) {
    _sheet._answers.remove(scoreId);
    changed();
  }

  void resetAll() {
    _sheet._answers.clear();
    _sheet.vitals.clear();
    changed();
  }

  @override
  Object toJson() => _sheet.toJson();

  @override
  void restore(Object? json) => _sheet = ScoreSheet.fromJson(json);
}
