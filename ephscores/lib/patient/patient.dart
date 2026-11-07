import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

import '../burn/burn.dart';
import '../persistence.dart';
import '../scores/model.dart';
import '../scores/score_store.dart';
import '../viaverde/via_verde.dart';

/// Times of the occurrence, in the order of the national form (verbete),
/// plus the CODU contact.
enum PatientEvent {
  toScene('A caminho do local'),
  atVictim('Chegada à vítima'),
  codu('Contacto CODU'),
  toHospital('A caminho da unidade de saúde'),
  atHospital('Chegada à unidade de saúde'),
  available('Disponível');

  const PatientEvent(this.label);

  final String label;
}

/// One registered evaluation: a snapshot of every score and the burn map.
class Evaluation {
  Evaluation({
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

  /// Result of every answered score, in display order. A registered
  /// evaluation never changes, so this is computed once, not on each rebuild.
  late final Map<String, ScoreResult> results = {
    for (final s in scores.answered) s.id: scores.resultFor(s.id),
  };

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
  Onset? _onset;
  final Set<String> _checks = {};
  final Map<PatientEvent, DateTime> _events = {};

  /// Times stamped so far, in form order.
  Map<PatientEvent, DateTime> get events => {
    for (final e in PatientEvent.values)
      if (_events[e] != null) e: _events[e]!,
  };

  /// Stamps [event] at [at] (now by default), or clears it with null.
  void setEvent(PatientEvent event, DateTime? at) {
    if (at == null) {
      _events.remove(event);
    } else {
      _events[event] = at;
    }
    changed();
  }

  /// When the symptoms began (or the patient was last seen well).
  Onset? get onset => _onset;

  set onset(Onset? value) {
    _onset = value;
    changed();
  }

  /// Via Verde criteria ticked by hand, as "pathway.criterion" ids.
  Set<String> get checks => UnmodifiableSetView(_checks);

  void toggleCheck(String id) {
    if (!_checks.remove(id)) _checks.add(id);
    changed();
  }

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
    _onset = null;
    _checks.clear();
    _events.clear();
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

  /// Deletes the evaluation at [index] (oldest is 0), e.g. one registered
  /// by mistake. Later evaluations keep their recorded durations.
  void removeAt(int index) {
    _evaluations.removeAt(index);
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
    _onset = null;
    _checks.clear();
    _events.clear();
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
    if (_onset != null) 'onset': _onset!.toJson(),
    if (_checks.isNotEmpty) 'checks': _checks.toList()..sort(),
    if (_events.isNotEmpty)
      'events': {
        for (final MapEntry(:key, :value) in events.entries)
          key.name: value.millisecondsSinceEpoch,
      },
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
    final onset = data['onset'] as Map<String, dynamic>?;
    final checks = (data['checks'] as List?)?.cast<String>() ?? const [];
    _startedAt = DateTime.fromMillisecondsSinceEpoch(start);
    _finishedAt = end == null ? null : DateTime.fromMillisecondsSinceEpoch(end);
    _evaluations.addAll(evaluations);
    _onset = onset == null ? null : Onset.fromJson(onset);
    _checks.addAll(checks);
    final events = (data['events'] as Map<String, dynamic>?) ?? const {};
    for (final e in PatientEvent.values) {
      if (events[e.name] case final int ms) {
        _events[e] = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
  }
}
