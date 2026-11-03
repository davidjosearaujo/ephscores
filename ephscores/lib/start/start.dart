import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

import '../persistence.dart';

/// START triage categories.
enum StartCategory {
  p1('P1', 'Emergente', 'Vermelho'),
  p2('P2', 'Urgente', 'Amarelo'),
  p3('P3', 'Não urgente', 'Verde'),
  p4('P4', 'Morto', 'Preto');

  const StartCategory(this.code, this.label, this.colorName);

  final String code;
  final String label;
  final String colorName;
}

/// One question of the START algorithm.
enum StartQuestion {
  walks('Caminha?', 'Todas as vítimas que caminham são P3.'),
  breathes('Respira?', 'Verificar ventilação espontânea.'),
  breathesAfterAirway(
    'Respira após permeabilizar a via aérea?',
    'Extensão da cabeça / subluxação da mandíbula.',
  ),
  rrOver30('Frequência respiratória > 30 cpm?', null),
  perfusion('Preenchimento capilar > 2 s ou pulso radial ausente?', null),
  obeys('Cumpre ordens simples?', 'Ex.: "aperte a minha mão".');

  const StartQuestion(this.text, this.hint);

  final String text;
  final String? hint;
}

/// Outcome of answering a question: either the next question or a category.
typedef StartStep = ({StartQuestion? next, StartCategory? category});

StartStep _ask(StartQuestion q) => (next: q, category: null);
StartStep _done(StartCategory c) => (next: null, category: c);

/// The START decision tree.
StartStep startAnswer(StartQuestion question, bool yes) => switch (question) {
  StartQuestion.walks =>
    yes ? _done(StartCategory.p3) : _ask(StartQuestion.breathes),
  StartQuestion.breathes =>
    yes
        ? _ask(StartQuestion.rrOver30)
        : _ask(StartQuestion.breathesAfterAirway),
  StartQuestion.breathesAfterAirway =>
    yes ? _done(StartCategory.p1) : _done(StartCategory.p4),
  StartQuestion.rrOver30 =>
    yes ? _done(StartCategory.p1) : _ask(StartQuestion.perfusion),
  StartQuestion.perfusion =>
    yes ? _done(StartCategory.p1) : _ask(StartQuestion.obeys),
  StartQuestion.obeys =>
    yes ? _done(StartCategory.p2) : _done(StartCategory.p1),
};

class TriageRecord {
  const TriageRecord(this.category, this.time);

  final StartCategory category;
  final DateTime time;

  Map<String, Object> toJson() => {
    'c': category.name,
    't': time.millisecondsSinceEpoch,
  };

  static TriageRecord fromJson(Map<String, dynamic> json) => TriageRecord(
    StartCategory.values.byName(json['c'] as String),
    DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
  );
}

/// Log of triaged victims for the current incident.
class StartStore extends PersistedStore {
  StartStore(SharedPreferences prefs) : super(prefs, 'start.v2') {
    load();
  }

  final List<TriageRecord> _records = [];

  /// Read-only view, oldest first; no copy is made.
  List<TriageRecord> get records => UnmodifiableListView(_records);

  int count(StartCategory c) => _records.where((r) => r.category == c).length;

  int get total => _records.length;

  void add(StartCategory c, {DateTime? at}) {
    _records.add(TriageRecord(c, at ?? DateTime.now()));
    changed();
  }

  /// Removes the most recent victim of category [c], if any.
  void removeLast(StartCategory c) {
    final i = _records.lastIndexWhere((r) => r.category == c);
    if (i == -1) return;
    _records.removeAt(i);
    changed();
  }

  void clear() {
    _records.clear();
    changed();
  }

  @override
  Object toJson() => [for (final r in _records) r.toJson()];

  @override
  void restore(Object? json) {
    _records.addAll([
      for (final r in json as List)
        TriageRecord.fromJson(r as Map<String, dynamic>),
    ]);
  }
}
