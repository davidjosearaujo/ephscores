/// Data model shared by every clinical score.
///
/// A score is described as data ([ScoreDefinition]) and evaluated by a pure
/// function, so the UI is generic and the maths can be unit-tested in
/// isolation from Flutter.
library;

/// Clinical severity of a result, mapped to the traffic-light palette.
enum Severity { incomplete, ok, warning, danger }

class ScoreOption {
  const ScoreOption(
    this.label,
    this.points, {
    this.detail,
    this.exclusive = false,
  });

  final String label;
  final int points;

  /// Optional secondary text shown under the label.
  final String? detail;

  /// In multi-select items, picking an exclusive option clears the others
  /// (used for "Sem alterações").
  final bool exclusive;
}

class ScoreItem {
  const ScoreItem({
    required this.id,
    required this.label,
    required this.options,
    this.hint,
    this.multi = false,
    this.optional = false,
    this.visibleWhen,
  });

  final String id;
  final String label;
  final String? hint;
  final List<ScoreOption> options;

  /// Allows several options to be selected at once.
  final bool multi;

  /// Optional items don't count towards completeness.
  final bool optional;

  /// Hides the item unless the predicate holds for the current answers.
  final bool Function(Answers answers)? visibleWhen;

  bool isVisible(Answers answers) => visibleWhen?.call(answers) ?? true;
}

/// The options picked for each item of one score, by option index.
class Answers {
  const Answers(this._picks);

  static const empty = Answers({});

  final Map<String, Set<int>> _picks;

  Set<int> of(String itemId) => _picks[itemId] ?? const {};

  /// The single picked option index, or null.
  int? choice(String itemId) {
    final picks = of(itemId);
    return picks.isEmpty ? null : picks.first;
  }

  bool has(String itemId) => of(itemId).isNotEmpty;

  Map<String, Set<int>> toMap() => _picks;
}

class ScoreResult {
  const ScoreResult({
    required this.value,
    required this.display,
    required this.severity,
    required this.label,
    required this.answered,
    required this.total,
    this.breakdown,
  });

  /// Numeric total, or null when there's nothing to add up yet.
  final int? value;

  /// What to show in large type ("15", "2/3", ...).
  final String display;
  final Severity severity;

  /// Short interpretation ("Risco baixo"). Empty while incomplete.
  final String label;
  final int answered;
  final int total;

  /// Optional component summary, e.g. "O4 V5 M6".
  final String? breakdown;

  bool get complete => answered >= total;
}

/// Lets a score read the result of another score (e.g. MGAP uses GCS).
typedef ResultLookup = ScoreResult Function(String scoreId);

typedef Evaluator = ScoreResult Function(
  ScoreDefinition score,
  Answers answers,
  ResultLookup lookup,
);

class ScoreDefinition {
  const ScoreDefinition({
    required this.id,
    required this.name,
    required this.fullName,
    required this.description,
    required this.items,
    required this.evaluate,
    this.dependsOn = const [],
  });

  final String id;
  final String name;
  final String fullName;
  final String description;
  final List<ScoreItem> items;

  /// Other scores whose result feeds into this one.
  final List<String> dependsOn;

  final Evaluator evaluate;

  ScoreResult resultFor(Answers answers, ResultLookup lookup) =>
      evaluate(this, answers, lookup);

  List<ScoreItem> visibleItems(Answers answers) => [
    for (final item in items)
      if (item.isVisible(answers)) item,
  ];
}

/// Interpretation band: inclusive lower bound with its label and severity.
class Band {
  const Band(this.min, this.severity, this.label);

  final int min;
  final Severity severity;
  final String label;
}

/// Sum of the points of every visible, answered item, and how many required
/// items are answered.
({int sum, int answered, int total}) sumPoints(
  ScoreDefinition score,
  Answers answers,
) {
  var sum = 0, answered = 0, total = 0;
  for (final item in score.visibleItems(answers)) {
    if (!item.optional) total++;
    final picks = answers.of(item.id);
    if (picks.isEmpty) continue;
    if (!item.optional) answered++;
    for (final i in picks) {
      sum += item.options[i].points;
    }
  }
  return (sum: sum, answered: answered, total: total);
}

/// Picks the band with the highest `min` not above [value]. Bands may be in
/// any order.
Band bandFor(int value, List<Band> bands) {
  final sorted = [...bands]..sort((a, b) => b.min.compareTo(a.min));
  return sorted.firstWhere((b) => value >= b.min, orElse: () => sorted.last);
}

/// Standard evaluation for additive scores: sum the points and interpret the
/// total with [bands] once every required item is answered.
Evaluator additive(List<Band> bands, {String Function(int sum)? display}) {
  return (score, answers, _) {
    final s = sumPoints(score, answers);
    final complete = s.answered >= s.total;
    final band = complete ? bandFor(s.sum, bands) : null;
    return ScoreResult(
      value: s.answered == 0 ? null : s.sum,
      display: s.answered == 0 ? '–' : (display?.call(s.sum) ?? '${s.sum}'),
      severity: band?.severity ?? Severity.incomplete,
      label: band?.label ?? '',
      answered: s.answered,
      total: s.total,
    );
  };
}
