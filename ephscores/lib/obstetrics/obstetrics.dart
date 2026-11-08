/// The pregnant patient and the birth, following INEM's TAS manual
/// "Emergências de Obstetrícia" (v1.0, March 2024).
library;

import 'package:flutter/foundation.dart';

import '../format.dart';
import '../scores/model.dart';
import '../scores/pediatric.dart' as pediatric show apgar;
import '../vitals/vitals.dart';

const obstetricsSource = 'INEM, TAS Emergências de Obstetrícia (2024)';

enum Presentation {
  cephalic('Cefálica'),
  breech('Pélvica');

  const Presentation(this.label);

  final String label;
}

/// What the amniotic fluid shows; none means clear.
enum FluidSign {
  meconium('Esverdeado'),
  blood('Com sangue'),
  foul('Cheiro fétido');

  const FluidSign(this.label);

  final String label;
}

/// Signs that make hypertension in pregnancy severe.
enum SevereSign {
  headache('Cefaleias intensas'),
  vision('Perturbações visuais', detail: '"Moscas volantes", visão turva'),
  abdominal('Dores abdominais intensas');

  const SevereSign(this.label, {this.detail});

  final String label;
  final String? detail;
}

/// Gestational age bands of the manual.
enum Term {
  notViable('não viável', 'Menos de 24 semanas: feto não viável'),
  preterm('pré-termo', 'Pré-termo (24 a 36 semanas e 6 dias)'),
  term('termo', 'Termo (37 semanas ou mais)');

  const Term(this.short, this.label);

  final String short;
  final String label;

  static Term of(int weeks) =>
      weeks < 24 ? notViable : (weeks < 37 ? preterm : term);
}

/// APGAR is scored at these minutes after birth.
const apgarMinutes = [1, 5, 10];

Set<T> _enums<T extends Enum>(List<T> values, Object? json) => {
  for (final name in (json as List?)?.cast<String>() ?? const <String>[])
    ?values.asNameMap()[name],
};

List<String> _names(Set<Enum> values) => [for (final v in values) v.name];

DateTime? _time(Object? ms) =>
    ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

/// The birth: its times, the newborn's APGAR and the mother after the
/// placenta.
@immutable
class Birth {
  const Birth({
    required this.bornAt,
    this.clampedAt,
    this.placentaAt,
    this.apgar = const {},
    this.uterusFirm,
    this.heavyBleeding = false,
  });

  factory Birth.fromJson(Map<String, dynamic> json) => Birth(
    bornAt: _time(json['born'])!,
    clampedAt: _time(json['clamped']),
    placentaAt: _time(json['placenta']),
    apgar: {
      for (final MapEntry(:key, :value)
          in ((json['apgar'] as Map?) ?? const {}).entries)
        if (int.tryParse(key as String) case final minute?
            when apgarMinutes.contains(minute))
          minute: {
            for (final item in pediatric.apgar.items)
              if ((value as Map)[item.id] case final int i
                  when i >= 0 && i < item.options.length)
                item.id: i,
          },
    },
    uterusFirm: json['uterus'] as bool?,
    heavyBleeding: json['bleeding'] == true,
  );

  final DateTime bornAt;
  final DateTime? clampedAt;
  final DateTime? placentaAt;

  /// The APGAR option picked for each item, by minute.
  final Map<int, Map<String, int>> apgar;

  /// The uterus is contracted after the placenta (the "globo de segurança
  /// de Pinard"); null until checked.
  final bool? uterusFirm;
  final bool heavyBleeding;

  /// The APGAR at [minute], or null when nothing was scored.
  ScoreResult? apgarAt(int minute) {
    final picks = apgar[minute];
    if (picks == null || picks.isEmpty) return null;
    return apgarResult(picks);
  }

  /// Postpartum haemorrhage is suspected: after the placenta, the uterus
  /// isn't contracted, the bleeding is heavy or the shock index is raised.
  bool haemorrhage(VitalSigns v) =>
      placentaAt != null &&
      (uterusFirm == false ||
          heavyBleeding ||
          (v.shockResult?.severity.isAlert ?? false));

  Birth copyWith({
    DateTime? bornAt,
    ValueGetter<DateTime?>? clampedAt,
    ValueGetter<DateTime?>? placentaAt,
    Map<int, Map<String, int>>? apgar,
    ValueGetter<bool?>? uterusFirm,
    bool? heavyBleeding,
  }) => Birth(
    bornAt: bornAt ?? this.bornAt,
    clampedAt: clampedAt == null ? this.clampedAt : clampedAt(),
    placentaAt: placentaAt == null ? this.placentaAt : placentaAt(),
    apgar: apgar ?? this.apgar,
    uterusFirm: uterusFirm == null ? this.uterusFirm : uterusFirm(),
    heavyBleeding: heavyBleeding ?? this.heavyBleeding,
  );

  Map<String, Object> toJson() => {
    'born': bornAt.millisecondsSinceEpoch,
    'clamped': ?clampedAt?.millisecondsSinceEpoch,
    'placenta': ?placentaAt?.millisecondsSinceEpoch,
    if (apgar.isNotEmpty)
      'apgar': {
        for (final MapEntry(:key, :value) in apgar.entries) '$key': value,
      },
    'uterus': ?uterusFirm,
    if (heavyBleeding) 'bleeding': true,
  };
}

/// The APGAR result of [picks] (option index by item id).
ScoreResult apgarResult(Map<String, int> picks) => pediatric.apgar.resultFor(
  Answers({
    for (final MapEntry(:key, :value) in picks.entries) key: {value},
  }),
  (_) => throw StateError('APGAR depends on no other score'),
);

/// What is known about the pregnancy, mostly from the pregnancy health
/// booklet (Boletim de Saúde da Grávida), and the birth once it happens.
@immutable
class Pregnancy {
  const Pregnancy({
    this.weeks,
    this.days,
    this.gesta,
    this.para,
    this.twins = false,
    this.presentation,
    this.booklet = false,
    this.watersAt,
    this.fluid = const {},
    this.severe = const {},
    this.birth,
  });

  factory Pregnancy.fromJson(Map<String, dynamic> json) => Pregnancy(
    weeks: json['weeks'] as int?,
    days: json['days'] as int?,
    gesta: json['gesta'] as int?,
    para: json['para'] as int?,
    twins: json['twins'] == true,
    presentation: Presentation.values.asNameMap()[json['presentation']],
    booklet: json['booklet'] == true,
    watersAt: _time(json['waters']),
    fluid: _enums(FluidSign.values, json['fluid']),
    severe: _enums(SevereSign.values, json['severe']),
    birth: json['birth'] == null
        ? null
        : Birth.fromJson(json['birth'] as Map<String, dynamic>),
  );

  /// Gestational age; [days] (0–6) only when known, e.g. from the date of
  /// the last period.
  final int? weeks;
  final int? days;

  /// Pregnancies, this one included, and births of viable foetuses.
  final int? gesta;
  final int? para;

  final bool twins;
  final Presentation? presentation;

  /// The pregnancy health booklet is with her, to hand over at the
  /// maternity.
  final bool booklet;

  /// When the waters broke, and what the fluid looked like.
  final DateTime? watersAt;
  final Set<FluidSign> fluid;

  final Set<SevereSign> severe;
  final Birth? birth;

  Term? get term => weeks == null ? null : Term.of(weeks!);

  /// From 20 weeks (or when unknown) the uterus compresses the vena cava
  /// lying flat.
  bool get from20Weeks => (weeks ?? 20) >= 20;

  /// "38 semanas e 2 dias".
  String? get gestationLabel {
    final w = weeks;
    if (w == null) return null;
    final d = days ?? 0;
    return d == 0
        ? formatCount(w, 'semana', 'semanas')
        : '${formatCount(w, 'semana', 'semanas')} e '
              '${formatCount(d, 'dia', 'dias')}';
  }

  /// Gestational age on [today] for a last period that began on [lmp].
  static ({int weeks, int days}) fromLastPeriod(DateTime lmp, DateTime today) {
    final total = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(lmp.year, lmp.month, lmp.day)).inDays;
    return (weeks: total ~/ 7, days: total % 7);
  }

  Pregnancy copyWith({
    ValueGetter<int?>? weeks,
    ValueGetter<int?>? days,
    ValueGetter<int?>? gesta,
    ValueGetter<int?>? para,
    bool? twins,
    ValueGetter<Presentation?>? presentation,
    bool? booklet,
    ValueGetter<DateTime?>? watersAt,
    Set<FluidSign>? fluid,
    Set<SevereSign>? severe,
    ValueGetter<Birth?>? birth,
  }) => Pregnancy(
    weeks: weeks == null ? this.weeks : weeks(),
    days: days == null ? this.days : days(),
    gesta: gesta == null ? this.gesta : gesta(),
    para: para == null ? this.para : para(),
    twins: twins ?? this.twins,
    presentation: presentation == null ? this.presentation : presentation(),
    booklet: booklet ?? this.booklet,
    watersAt: watersAt == null ? this.watersAt : watersAt(),
    fluid: fluid ?? this.fluid,
    severe: severe ?? this.severe,
    birth: birth == null ? this.birth : birth(),
  );

  Map<String, Object> toJson() => {
    'weeks': ?weeks,
    'days': ?days,
    'gesta': ?gesta,
    'para': ?para,
    if (twins) 'twins': true,
    'presentation': ?presentation?.name,
    if (booklet) 'booklet': true,
    'waters': ?watersAt?.millisecondsSinceEpoch,
    if (fluid.isNotEmpty) 'fluid': _names(fluid),
    if (severe.isNotEmpty) 'severe': _names(severe),
    'birth': ?birth?.toJson(),
  };

  /// "Grávida: 38 semanas e 2 dias (termo) · G2 P1", or just "Grávida".
  String headline() =>
      ['Grávida', summary()].where((s) => s.isNotEmpty).join(': ');

  /// What is known, on one line: "38 semanas e 2 dias (termo) · G2 P1 ·
  /// gemelar · apresentação pélvica · com Boletim de Saúde da Grávida".
  String summary() => [
    if (gestationLabel case final g?) '$g (${term!.short})',
    if (gesta != null || para != null) 'G${gesta ?? '?'} P${para ?? '?'}',
    if (twins) 'gemelar',
    if (presentation case final p?) 'apresentação ${p.label.toLowerCase()}',
    if (booklet) 'com Boletim de Saúde da Grávida',
  ].join(' · ');
}

/// Only the amber and red [pregnancyAlerts], for the handover and badges.
List<String> pregnancyFlags(Pregnancy p, VitalSigns v) => [
  for (final (s, text) in pregnancyAlerts(p, v))
    if (s.isAlert) text,
];

/// Reminders and warnings for a pregnant patient with vital signs [v]:
/// grey reminders ([Severity.incomplete]), amber and red flags.
List<(Severity, String)> pregnancyAlerts(Pregnancy p, VitalSigns v) {
  final sbp = v[Vital.sbp], dbp = v[Vital.dbp], spo2 = v[Vital.spo2];
  final hypertension = p.from20Weeks && ((sbp ?? 0) >= 140 || (dbp ?? 0) >= 90);
  final severe = p.severe.isNotEmpty;
  return [
    if (hypertension && severe)
      (
        Severity.danger,
        'Hipertensão com sinais de gravidade: comunicar ao CODU',
      )
    else if (hypertension)
      (Severity.warning, 'Hipertensão na gravidez (PA ≥ 140/90 mmHg)')
    else if (severe && sbp == null)
      (Severity.warning, 'Sinais de gravidade: avaliar a pressão arterial'),
    if (p.fluid.isNotEmpty)
      (
        Severity.warning,
        'Líquido amniótico '
            '${[for (final f in p.fluid) f.label.toLowerCase()].join(', ')}: '
            'comunicar ao CODU',
      ),
    if (p.twins)
      (Severity.warning, 'Gemelar: o parto deve ocorrer no hospital'),
    if (p.presentation == Presentation.breech)
      (Severity.warning, 'Pélvica: o parto deve ocorrer na maternidade'),
    if (spo2 != null && spo2 < 92)
      (Severity.warning, 'SpO₂ abaixo do alvo de 92–96%')
    else
      (Severity.incomplete, 'SpO₂ alvo: 92–96%'),
    if (p.from20Weeks)
      (
        Severity.incomplete,
        'Posicionar e transportar em decúbito lateral '
            'esquerdo',
      ),
    (Severity.incomplete, 'NEWS2 não validada na gravidez'),
  ];
}
