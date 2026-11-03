import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
class StartStore extends ChangeNotifier {
  StartStore(this._prefs) {
    _load();
  }

  static const _key = 'start.v2';

  final SharedPreferences _prefs;
  final List<TriageRecord> _records = [];

  List<TriageRecord> get records => List.unmodifiable(_records);

  int count(StartCategory c) => _records.where((r) => r.category == c).length;

  int get total => _records.length;

  void add(StartCategory c, {DateTime? at}) {
    _records.add(TriageRecord(c, at ?? DateTime.now()));
    _changed();
  }

  /// Removes the most recent victim of category [c], if any.
  void removeLast(StartCategory c) {
    final i = _records.lastIndexWhere((r) => r.category == c);
    if (i == -1) return;
    _records.removeAt(i);
    _changed();
  }

  void clear() {
    _records.clear();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _prefs.setString(_key, jsonEncode([for (final r in _records) r.toJson()]));
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      _records.addAll([
        for (final r in jsonDecode(raw) as List)
          TriageRecord.fromJson(r as Map<String, dynamic>),
      ]);
    } on Object catch (e) {
      debugPrint('Discarding saved triage: $e');
    }
  }
}
