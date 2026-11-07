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

/// What a patient's summary and evolution are built from: the live patient
/// ([PatientStore]) or one kept in the history ([SavedPatient]).
abstract interface class PatientRecord {
  DateTime? get startedAt;
  DateTime? get finishedAt;
  bool get isFinished;

  /// Oldest first.
  List<Evaluation> get evaluations;
  Onset? get onset;

  /// Via Verde criteria ticked by hand, as "pathway.criterion" ids.
  Set<String> get checks;

  /// Occurrence times, in form order.
  Map<PatientEvent, DateTime> get events;
}

/// A patient read back from its JSON (the format of [PatientStore.toJson]),
/// e.g. from the history. Immutable.
class SavedPatient implements PatientRecord {
  SavedPatient._({
    required DateTime this.startedAt,
    required this.finishedAt,
    required List<Evaluation> evaluations,
    required this.onset,
    required Set<String> checks,
    required Map<PatientEvent, DateTime> events,
  }) : evaluations = List.unmodifiable(evaluations),
       checks = Set.unmodifiable(checks),
       events = Map.unmodifiable(events);

  /// Parses [PatientStore.toJson] output; null when no patient was started.
  /// Throws on malformed data.
  static SavedPatient? fromJson(Map<String, dynamic> data) {
    final start = data['start'] as int?;
    if (start == null) return null;
    final end = data['end'] as int?;
    final onset = data['onset'] as Map<String, dynamic>?;
    final events = (data['events'] as Map<String, dynamic>?) ?? const {};
    return SavedPatient._(
      startedAt: DateTime.fromMillisecondsSinceEpoch(start),
      finishedAt: end == null ? null : DateTime.fromMillisecondsSinceEpoch(end),
      evaluations: [
        for (final e in data['evaluations'] as List)
          Evaluation.fromJson(e as Map<String, dynamic>),
      ],
      onset: onset == null ? null : Onset.fromJson(onset),
      checks: {...?(data['checks'] as List?)?.cast<String>()},
      events: {
        for (final e in PatientEvent.values)
          if (events[e.name] case final int ms)
            e: DateTime.fromMillisecondsSinceEpoch(ms),
      },
    );
  }

  @override
  final DateTime? startedAt;
  @override
  final DateTime? finishedAt;
  @override
  bool get isFinished => finishedAt != null;
  @override
  final List<Evaluation> evaluations;
  @override
  final Onset? onset;
  @override
  final Set<String> checks;
  @override
  final Map<PatientEvent, DateTime> events;
}

/// The patient being assessed (or the last one, once finished) and the
/// timeline of their evaluations. Only one patient is kept here, and
/// nothing identifies them; finished patients also go to the history.
class PatientStore extends PersistedStore implements PatientRecord {
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
  @override
  Map<PatientEvent, DateTime> get events => {
    for (final e in PatientEvent.values)
      e: ?_events[e],
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
  @override
  Onset? get onset => _onset;

  set onset(Onset? value) {
    _onset = value;
    changed();
  }

  /// Via Verde criteria ticked by hand, as "pathway.criterion" ids.
  @override
  Set<String> get checks => UnmodifiableSetView(_checks);

  void toggleCheck(String id) {
    if (!_checks.remove(id)) _checks.add(id);
    changed();
  }

  @override
  DateTime? get startedAt => _startedAt;
  @override
  DateTime? get finishedAt => _finishedAt;

  /// A patient is open: evaluations can be registered.
  bool get isActive => _startedAt != null && _finishedAt == null;

  /// The last patient was finished and its summary is still kept.
  @override
  bool get isFinished => _finishedAt != null;

  /// Oldest first; a read-only view.
  @override
  List<Evaluation> get evaluations => UnmodifiableListView(_evaluations);

  /// When the evaluation in progress began.
  DateTime get evaluationStartedAt =>
      _evaluations.isEmpty ? _startedAt! : _evaluations.last.registeredAt;

  /// Starts a new patient, discarding the previous one.
  void start({DateTime? at}) {
    _reset();
    _startedAt = at ?? DateTime.now();
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
    _reset();
    changed();
  }

  void _reset() {
    _startedAt = null;
    _finishedAt = null;
    _evaluations.clear();
    _onset = null;
    _checks.clear();
    _events.clear();
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
    final saved = SavedPatient.fromJson(json as Map<String, dynamic>);
    if (saved == null) return;
    _startedAt = saved.startedAt;
    _finishedAt = saved.finishedAt;
    _evaluations.addAll(saved.evaluations);
    _onset = saved.onset;
    _checks.addAll(saved.checks);
    _events.addAll(saved.events);
  }
}
