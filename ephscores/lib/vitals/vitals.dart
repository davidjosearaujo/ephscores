/// Vital signs, recorded once and shared by every score that uses them.
///
/// The fields follow the assessment row of INEM's national incident form
/// (Verbete Nacional de Socorro, Mod.INEM.415/01), plus the age, which feeds
/// MGAP, ProACS and the Via Verde criteria.
library;

import '../format.dart';
import '../scores/model.dart';

/// Levels of the AVDS consciousness scale, as on the national form.
const avdsLevels = [
  ('A', 'Alerta'),
  ('V', 'Responde à voz'),
  ('D', 'Responde à dor'),
  ('S', 'Sem resposta'),
];

enum Vital {
  age('Idade', 'Idade', 'anos', 0, 120),
  avds('Estado de consciência (AVDS)', 'AVDS', '', 0, 3),
  rr('Frequência respiratória', 'FR', 'cpm', 0, 80),
  spo2('Saturação periférica de O₂', 'SpO₂', '%', 0, 100),
  o2('Oxigénio suplementar', 'O₂', 'l/min', 0, 25, decimals: true),
  hr('Frequência cardíaca', 'FC', 'bpm', 0, 300),
  sbp('Pressão arterial sistólica', 'PAS', 'mmHg', 0, 300),
  dbp('Pressão arterial diastólica', 'PAD', 'mmHg', 0, 200),
  temp('Temperatura', 'Temp.', '°C', 25, 45, decimals: true),
  pain('Dor', 'Dor', '/10', 0, 10),
  glucose('Glicemia capilar', 'Glic.', 'mg/dL', 10, 1000);

  const Vital(
    this.label,
    this.short,
    this.unit,
    this.min,
    this.max, {
    this.decimals = false,
  });

  final String label;

  /// Column name in the evolution table and the summary.
  final String short;
  final String unit;
  final num min;
  final num max;

  /// Accepts one decimal place (temperature, oxygen flow).
  final bool decimals;

  bool accepts(num v) => v >= min && v <= max;

  /// Parses user input ("36,8" or "36.8"); null if empty, invalid or out of
  /// range.
  num? parse(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final num? v = decimals ? double.tryParse(t) : int.tryParse(t);
    if (v == null || !accepts(v)) return null;
    return decimals ? (v * 10).round() / 10 : v;
  }
}

/// The vital signs of one moment. The live copy is edited through
/// `ScoreStore`; registered evaluations keep a [copy].
class VitalSigns {
  VitalSigns() : _values = {}, _newConfusion = false, _painFaces = false;

  VitalSigns._(this._values, this._newConfusion, this._painFaces);

  /// Parses [toJson] output, dropping unknown or out-of-range values.
  factory VitalSigns.fromJson(Object? json) {
    final values = <Vital, num>{};
    final map = json as Map<String, dynamic>;
    for (final vital in Vital.values) {
      final v = map[vital.name];
      if (v is num && vital.accepts(v)) {
        values[vital] = vital.decimals ? v.toDouble() : v.toInt();
      }
    }
    return VitalSigns._(values, map['confusion'] == true, map['faces'] == true);
  }

  final Map<Vital, num> _values;
  bool _newConfusion;
  bool _painFaces;

  num? operator [](Vital vital) => _values[vital];

  /// Alert (AVDS "A") but newly confused, which NEWS2 scores like V, D or S.
  bool get newConfusion => _newConfusion && _values[Vital.avds] == 0;

  /// The pain was rated on the faces scale rather than typed as a number.
  bool get painFaces => _painFaces && _values[Vital.pain] != null;

  bool get isEmpty => _values.isEmpty;

  /// Sets or, with null, clears a value. Out-of-range values are ignored.
  /// A pain value set here counts as typed; see [setPainFaces].
  void set(Vital vital, num? value) {
    if (vital == Vital.pain) _painFaces = false;
    if (value == null) {
      _values.remove(vital);
    } else if (vital.accepts(value)) {
      // One numeric type per vital, so equal sheets encode the same.
      _values[vital] = vital.decimals ? value.toDouble() : value.toInt();
    }
  }

  set newConfusion(bool value) => _newConfusion = value;

  /// Pain rated on the faces scale (0, 2, 4, 6, 8 or 10).
  void setPainFaces(int value) {
    set(Vital.pain, value);
    _painFaces = true;
  }

  void clear() {
    _values.clear();
    _newConfusion = false;
    _painFaces = false;
  }

  VitalSigns copy() => VitalSigns._({..._values}, _newConfusion, _painFaces);

  /// Heart rate over systolic pressure, when both are known.
  double? get shockIndex {
    final hr = _values[Vital.hr], sbp = _values[Vital.sbp];
    if (hr == null || sbp == null || sbp == 0) return null;
    return hr / sbp;
  }

  /// The [shockIndex] graded, when known.
  ScoreResult? get shockResult => switch (shockIndex) {
    final si? => shockIndexResult(si),
    null => null,
  };

  /// One value with its unit: "36,8 °C", "95%", "A", "3/10".
  String format(Vital vital) {
    final v = _values[vital];
    if (v == null) return '–';
    return switch (vital) {
      Vital.avds =>
        avdsLevels[v.toInt()].$1 + (newConfusion ? ' (confuso)' : ''),
      Vital.pain => '${v.toInt()}/10${painFaces ? ' (faces)' : ''}',
      Vital.o2 when v == 0 => 'ar ambiente',
      Vital.spo2 => '${v.toInt()}%',
      _ => '${formatNumber(v.toDouble())} ${vital.unit}',
    };
  }

  /// A value without its unit, for table cells: "36,8", "A", "Ar".
  String? cell(Vital vital) {
    final v = _values[vital];
    if (v == null) return null;
    return switch (vital) {
      Vital.avds => avdsLevels[v.toInt()].$1 + (newConfusion ? '+C' : ''),
      Vital.o2 when v == 0 => 'Ar',
      _ => formatNumber(v.toDouble()),
    };
  }

  /// Blood pressure as "120/80", or just the known half.
  String? get bloodPressure {
    final s = _values[Vital.sbp], d = _values[Vital.dbp];
    if (s == null && d == null) return null;
    return '${s ?? '–'}/${d ?? '–'}';
  }

  /// One-line summary in form order: "45 anos · AVDS A · FR 18 cpm · ...
  /// · PA 120/80 mmHg · ... · IC 0,73".
  String summary() {
    String? part(Vital vital) => switch (vital) {
      Vital.sbp => bloodPressure == null ? null : 'PA $bloodPressure mmHg',
      Vital.dbp => null,
      _ when _values[vital] == null => null,
      Vital.age => '${_values[vital]} anos',
      _ => '${vital.short} ${format(vital)}',
    };
    final si = shockIndex;
    return [
      for (final vital in Vital.values) ?part(vital),
      if (si != null) 'IC ${formatShockIndex(si)}',
    ].join(' · ');
  }

  /// Sorted keys, so equal sheets always encode to the same string.
  Map<String, Object> toJson() => {
    for (final vital in Vital.values)
      if (_values[vital] != null) vital.name: _values[vital]!,
    if (newConfusion) 'confusion': true,
    if (painFaces) 'faces': true,
  };
}

String formatShockIndex(double si) =>
    si.toStringAsFixed(2).replaceAll('.', ',');

/// Shock index (FC/PAS) interpretation in adults. 0,7 is the alert threshold
/// of the Portuguese pre-hospital sepsis recommendations (2025); 1 or more
/// suggests shock.
ScoreResult shockIndexResult(double si) {
  final (severity, label) = si >= 1
      ? (Severity.danger, 'Sugere choque (≥ 1)')
      : si >= 0.7
      ? (Severity.warning, 'Elevado (≥ 0,7)')
      : (Severity.ok, 'Normal (< 0,7)');
  return ScoreResult(
    value: null,
    display: formatShockIndex(si),
    severity: severity,
    label: label,
    answered: 1,
    total: 1,
  );
}

/// Capillary glucose flag, with the thresholds of INEM's TAS manual
/// (hypoglycaemia below 60 mg/dL, hyperglycaemia above 200 mg/dL).
(Severity, String)? glucoseFlag(num mgdl) => mgdl < 60
    ? (Severity.danger, 'Hipoglicemia (< 60 mg/dL)')
    : mgdl > 200
    ? (Severity.warning, 'Hiperglicemia (> 200 mg/dL)')
    : null;

/// Links a score item to the vital signs: [pick] returns the option index
/// the recorded values select, or null when they don't decide it. [own] are
/// the score's manual answers (e.g. the NEWS2 SpO₂ scale).
class VitalBinding {
  const VitalBinding(this.vitals, this.pick);

  final List<Vital> vitals;
  final int? Function(VitalSigns v, Answers own) pick;
}

/// Normal awake ranges by age for children (under 16, where NEWS2 doesn't
/// apply), from PALS (AHA, 2020); the respiratory rates are also those of
/// DGS Norma 012/2022. Rows: (up to this age in years, FR, FC, PAS).
const _childNormals = [
  (0, (30, 53), (100, 180), (72, 104)),
  (2, (22, 37), (98, 140), (86, 106)),
  (3, (22, 37), (80, 120), (89, 112)),
  (5, (20, 28), (80, 120), (89, 112)),
  (9, (18, 25), (75, 118), (97, 115)),
  (11, (18, 25), (75, 118), (102, 120)),
  (12, (18, 25), (60, 100), (102, 120)),
  (15, (12, 20), (60, 100), (110, 131)),
];

/// The normal range of [vital] for a child of [age] years, or null for
/// adults and for vitals without a table.
(int, int)? childNormal(Vital vital, num age) {
  if (age >= 16) return null;
  final row = _childNormals.firstWhere((r) => age <= r.$1);
  return switch (vital) {
    Vital.rr => row.$2,
    Vital.hr => row.$3,
    Vital.sbp => row.$4,
    _ => null,
  };
}

/// PALS hypotension: PAS below 70 in the first year, 70 + 2 × age up to
/// 10 years, 90 from then on.
int childHypotension(num age) =>
    age < 1 ? 70 : (age < 10 ? 70 + 2 * age.toInt() : 90);

/// Estimated weight in kg of a child of [age] years, by the APLS formulas:
/// 3,5 kg newborn, 0,5 × months + 4 in the first year, 2 × years + 8 from 1
/// to 5, 3 × years + 7 from 6 to 12. A range in the first year, since the
/// age is in whole years; null from 13.
(double, double)? childWeight(num age) {
  if (age < 1) return (3.5, 9.5);
  if (age <= 5) return (2.0 * age + 8, 2.0 * age + 8);
  if (age <= 12) return (3.0 * age + 7, 3.0 * age + 7);
  return null;
}

/// "cerca de 18 kg", "cerca de 3,5 a 9,5 kg" (first year); null from 13.
String? childWeightLabel(num age) => switch (childWeight(age)) {
  (final low, final high) when low == high =>
    'cerca de ${formatNumber(low)} kg',
  (final low, final high) =>
    'cerca de ${formatNumber(low)} a ${formatNumber(high)} kg',
  null => null,
};

/// "aos 4 anos", "no 1.º ano de vida".
String childAgeLabel(num age) => age < 1
    ? 'no 1.º ano de vida'
    : 'aos ${formatCount(age.toInt(), 'ano', 'anos')}';

/// Flags a child's value outside the normal range for the age, in red for
/// hypotension.
(Severity, String)? childFlag(Vital vital, num value, num age) {
  final range = childNormal(vital, age);
  if (range == null) return null;
  if (vital == Vital.sbp && value < childHypotension(age)) {
    return (
      Severity.danger,
      'Hipotensão para a idade (< ${childHypotension(age)} mmHg)',
    );
  }
  final (lo, hi) = range;
  if (value < lo || value > hi) {
    return (
      Severity.warning,
      '${vital.short} ${value < lo ? 'baixa' : 'elevada'} para a idade '
          '(normal $lo–$hi ${vital.unit})',
    );
  }
  return null;
}
