/// Cardiac arrest (RCP): when it began, the cycles of analysis and the
/// shocks counted along the way, and how it ended. These are the RCP fields
/// of INEM's national form (Mod.INEM.415/01).
library;

import 'package:flutter/foundation.dart';

import '../format.dart';
import '../persistence.dart' show timeFromJson;

/// How a resuscitation ended.
enum CprEnd {
  rosc('Recuperação de circulação espontânea'),
  stopped('RCP suspensa');

  const CprEnd(this.label);

  final String label;
}

/// Chest compressions per minute that the metronome offers (the range of
/// the ERC and AHA guidelines).
const cprMinRate = 100;
const cprMaxRate = 120;
const cprDefaultRate = 110;

/// How much the metronome's rate changes with each tap of - or +.
const cprRateStep = 5;

/// An AED analyses the rhythm about every two minutes; a cycle taking
/// longer than this is worth a look.
const cprCycleLength = Duration(minutes: 2);

List<DateTime> _times(Object? json) => [
  for (final ms in (json as List?) ?? const []) ?timeFromJson(ms),
];

/// One resuscitation of the patient. Immutable: every change returns a new
/// one.
@immutable
class Cpr {
  const Cpr({
    required this.startedAt,
    this.cycleAt = const [],
    this.shockAt = const [],
    this.sivAt,
    this.endedAt,
    this.end,
  });

  factory Cpr.fromJson(Map<String, dynamic> json) => Cpr(
    startedAt: timeFromJson(json['start'])!,
    cycleAt: _times(json['cycles']),
    shockAt: _times(json['shocks']),
    sivAt: timeFromJson(json['siv']),
    endedAt: timeFromJson(json['endAt']),
    end: CprEnd.values.asNameMap()[json['end']],
  );

  final DateTime startedAt;

  /// When each cycle was counted (the AED analysing), oldest first.
  final List<DateTime> cycleAt;

  /// When each shock was delivered, oldest first.
  final List<DateTime> shockAt;

  /// When the SIV/SAV (the team with a nurse and a doctor) reached the
  /// scene.
  final DateTime? sivAt;

  final DateTime? endedAt;
  final CprEnd? end;

  int get cycles => cycleAt.length;
  int get shocks => shockAt.length;

  /// Resuscitation is still going on.
  bool get isOngoing => endedAt == null;

  /// Counts of cycles and shocks, to show in one line: "3 ciclos · 1 choque".
  String get counts => [
    formatCount(cycles, 'ciclo', 'ciclos'),
    formatCount(shocks, 'choque', 'choques'),
  ].join(' · ');

  /// Since the last cycle was counted, or since the start before the first.
  Duration sinceLastCycle(DateTime now) =>
      now.difference(cycleAt.lastOrNull ?? startedAt);

  /// How long it lasted, up to [now] while still ongoing.
  Duration duration(DateTime now) => (endedAt ?? now).difference(startedAt);

  /// A copy with some fields changed. The ones that can be empty are given
  /// as functions, so that null can be set: `sivAt: () => null`.
  Cpr copyWith({
    DateTime? startedAt,
    List<DateTime>? cycleAt,
    List<DateTime>? shockAt,
    ValueGetter<DateTime?>? sivAt,
    ValueGetter<DateTime?>? endedAt,
    ValueGetter<CprEnd?>? end,
  }) => Cpr(
    startedAt: startedAt ?? this.startedAt,
    cycleAt: cycleAt ?? this.cycleAt,
    shockAt: shockAt ?? this.shockAt,
    sivAt: sivAt != null ? sivAt() : this.sivAt,
    endedAt: endedAt != null ? endedAt() : this.endedAt,
    end: end != null ? end() : this.end,
  );

  Cpr addCycle(DateTime at) => copyWith(cycleAt: [...cycleAt, at]);

  Cpr addShock(DateTime at) => copyWith(shockAt: [...shockAt, at]);

  /// Takes back the last cycle counted by mistake.
  Cpr removeLastCycle() =>
      copyWith(cycleAt: cycleAt.sublist(0, (cycles - 1).clamp(0, cycles)));

  Cpr removeLastShock() =>
      copyWith(shockAt: shockAt.sublist(0, (shocks - 1).clamp(0, shocks)));

  /// Registers (or with null clears) the arrival of the SIV/SAV.
  Cpr withSiv(DateTime? at) => copyWith(sivAt: () => at);

  Cpr finish(CprEnd how, DateTime at) =>
      copyWith(endedAt: () => at, end: () => how);

  /// Goes on after an ending registered by mistake, or a new arrest: the
  /// counts are kept.
  Cpr resume() => copyWith(endedAt: () => null, end: () => null);

  /// For the handover: the resuscitation on one line, and its counts under
  /// it. While [open] it is still going on at [now].
  List<String> lines(DateTime now, {bool open = true}) {
    final ended = endedAt;
    final head = ended != null
        ? 'RCP das ${formatClock(startedAt)} às ${formatClock(ended)} '
              '(${formatDuration(duration(now))}): ${end!.label.toLowerCase()}'
        : open
        ? 'RCP em curso desde as ${formatClock(startedAt)} '
              '(há ${formatDuration(duration(now))})'
        : 'RCP iniciada às ${formatClock(startedAt)}, sem hora de fim';
    return [
      head,
      if (cycles > 0)
        '  ${formatCount(cycles, 'ciclo', 'ciclos')}, '
            'o último às ${formatClock(cycleAt.last)}',
      if (shocks > 0)
        '  ${formatCount(shocks, 'choque', 'choques')}, '
            'o último às ${formatClock(shockAt.last)}',
      if (sivAt case final at?) '  SIV/SAV no local às ${formatClock(at)}',
    ];
  }

  Map<String, Object> toJson() => {
    'start': startedAt.millisecondsSinceEpoch,
    if (cycleAt.isNotEmpty)
      'cycles': [for (final t in cycleAt) t.millisecondsSinceEpoch],
    if (shockAt.isNotEmpty)
      'shocks': [for (final t in shockAt) t.millisecondsSinceEpoch],
    'siv': ?sivAt?.millisecondsSinceEpoch,
    'endAt': ?endedAt?.millisecondsSinceEpoch,
    'end': ?end?.name,
  };
}
