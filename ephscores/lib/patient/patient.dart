import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

import '../burn/burn.dart';
import '../persistence.dart';
import '../scores/score_store.dart';

/// One registered evaluation: a snapshot of every score and the burn map.
class Evaluation {
  const Evaluation({
    required this.startedAt,
    required this.registeredAt,
    required this.scores,
    required this.burns,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) => Evaluation(
    startedAt: DateTime.fromMillisecondsSinceEpoch(json['start'] as int),
    registeredAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
    scores: ScoreSheet.fromJson(json['scores']),
    burns: BurnSheet.fromJson(json['burns']),
  );

  /// When this evaluation began: the previous registration, or the patient
  /// start for the first one.
  final DateTime startedAt;
  final DateTime registeredAt;
  final ScoreSheet scores;
  final BurnSheet burns;

  Duration get duration => registeredAt.difference(startedAt);

  Map<String, Object> toJson() => {
    'start': startedAt.millisecondsSinceEpoch,
    'at': registeredAt.millisecondsSinceEpoch,
    'scores': scores.toJson(),
    'burns': burns.toJson(),
  };
}

/// The patient being assessed (or the last one, once finished) and the
/// timeline of their evaluations. Only one patient is kept, and nothing
/// identifies them.
class PatientStore extends PersistedStore {
  PatientStore(SharedPreferences prefs) : super(prefs, 'patient.v2') {
    load();
  }

  DateTime? _startedAt;
  DateTime? _finishedAt;
  final List<Evaluation> _evaluations = [];

  DateTime? get startedAt => _startedAt;
  DateTime? get finishedAt => _finishedAt;

  /// A patient is open: evaluations can be registered.
  bool get isActive => _startedAt != null && _finishedAt == null;

  /// The last patient was finished and its summary is still kept.
  bool get isFinished => _finishedAt != null;

  /// Oldest first; a read-only view.
  List<Evaluation> get evaluations => UnmodifiableListView(_evaluations);

  /// When the evaluation in progress began.
  DateTime get evaluationStartedAt =>
      _evaluations.isEmpty ? _startedAt! : _evaluations.last.registeredAt;

  /// Starts a new patient, discarding the previous one.
  void start({DateTime? at}) {
    _startedAt = at ?? DateTime.now();
    _finishedAt = null;
    _evaluations.clear();
    changed();
  }

  /// Registers a snapshot of [scores] and [burns]; the live sheets are
  /// copied, so later edits don't change it.
  Evaluation register(ScoreSheet scores, BurnSheet burns, {DateTime? at}) {
    assert(isActive, 'No patient is open');
    final evaluation = Evaluation(
      startedAt: evaluationStartedAt,
      registeredAt: at ?? DateTime.now(),
      scores: scores.copy(),
      burns: burns.copy(),
    );
    _evaluations.add(evaluation);
    changed();
    return evaluation;
  }

  /// Removes the most recent evaluation (e.g. registered by mistake).
  void removeLast() {
    if (!isActive || _evaluations.isEmpty) return;
    _evaluations.removeLast();
    changed();
  }

  void finish({DateTime? at}) {
    assert(isActive, 'No patient is open');
    _finishedAt = at ?? DateTime.now();
    changed();
  }

  /// Forgets the patient entirely.
  void clear() {
    _startedAt = null;
    _finishedAt = null;
    _evaluations.clear();
    changed();
  }

  /// Whether [scores] and [burns] differ from the last registered
  /// evaluation, or hold any data before the first one.
  bool hasUnsavedChanges(ScoreSheet scores, BurnSheet burns) {
    if (_evaluations.isEmpty) return !scores.isEmpty || !burns.isEmpty;
    final last = _evaluations.last;
    return !scores.sameAs(last.scores) || !burns.sameAs(last.burns);
  }

  @override
  Object toJson() => {
    if (_startedAt != null) 'start': _startedAt!.millisecondsSinceEpoch,
    if (_finishedAt != null) 'end': _finishedAt!.millisecondsSinceEpoch,
    'evaluations': [for (final e in _evaluations) e.toJson()],
  };

  @override
  void restore(Object? json) {
    final data = json as Map<String, dynamic>;
    final start = data['start'] as int?;
    if (start == null) return;
    final end = data['end'] as int?;
    final evaluations = [
      for (final e in data['evaluations'] as List)
        Evaluation.fromJson(e as Map<String, dynamic>),
    ];
    _startedAt = DateTime.fromMillisecondsSinceEpoch(start);
    _finishedAt = end == null ? null : DateTime.fromMillisecondsSinceEpoch(end);
    _evaluations.addAll(evaluations);
  }
}
