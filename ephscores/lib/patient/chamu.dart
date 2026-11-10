/// CHAMU, INEM's mnemonic for the history taken in the secondary survey and
/// written on the national form (verbete): Circunstâncias, História,
/// Alergias, Medicação habitual, Última refeição.
library;

import 'package:flutter/foundation.dart';

class ChamuOption {
  const ChamuOption(this.id, this.label);

  final String id;
  final String label;
}

/// One letter of CHAMU: a choice from a list, with a text box that opens
/// for some of the options (or always, when there is no list).
class ChamuQuestion {
  const ChamuQuestion({
    required this.id,
    required this.letter,
    required this.title,
    required this.summaryTitle,
    this.options = const [],
    this.exclusive = const {},
    this.textWhen = const {},
    this.single = false,
    this.textHint = 'Notas',
  });

  final String id;
  final String letter;
  final String title;

  /// Heading in the handover: "Antecedentes", "Alergias", ...
  final String summaryTitle;

  /// Empty for a question answered only in the text box.
  final List<ChamuOption> options;

  /// Options that rule out the others ("Sem antecedentes conhecidos").
  final Set<String> exclusive;

  /// Options that open the text box ("Outra").
  final Set<String> textWhen;

  /// Only one option can be picked.
  final bool single;

  final String textHint;

  bool get textOnly => options.isEmpty;
}

const chamuQuestions = [
  ChamuQuestion(
    id: 'c',
    letter: 'C',
    title: 'Circunstâncias',
    summaryTitle: 'Circunstâncias',
    single: true,
    textWhen: {'other'},
    textHint: 'Descreva a situação',
    options: [
      ChamuOption('road', 'Acidente de viação'),
      ChamuOption('fall', 'Queda'),
      ChamuOption('illness', 'Doença súbita'),
      ChamuOption('assault', 'Agressão'),
      ChamuOption('poisoning', 'Intoxicação'),
      ChamuOption('fire', 'Fogo ou explosão'),
      ChamuOption('other', 'Outra'),
    ],
  ),
  ChamuQuestion(
    id: 'h',
    letter: 'H',
    title: 'História de doenças e/ou gravidez',
    summaryTitle: 'Antecedentes',
    exclusive: {'none'},
    textWhen: {'other'},
    textHint: 'Quais outras doenças',
    options: [
      ChamuOption('hypertension', 'Hipertensão'),
      ChamuOption('diabetes', 'Diabetes'),
      ChamuOption('heart', 'Doença cardíaca'),
      ChamuOption('stroke', 'AVC prévio'),
      ChamuOption('respiratory', 'Doença respiratória'),
      ChamuOption('kidney', 'Doença renal'),
      ChamuOption('epilepsy', 'Epilepsia'),
      ChamuOption('cancer', 'Doença oncológica'),
      ChamuOption('other', 'Outra'),
      ChamuOption('none', 'Sem antecedentes conhecidos'),
    ],
  ),
  ChamuQuestion(
    id: 'a',
    letter: 'A',
    title: 'Alergias',
    summaryTitle: 'Alergias',
    exclusive: {'none', 'unknown'},
    // Whichever is picked, to say to what.
    textWhen: {'drug', 'food', 'latex', 'insect', 'other'},
    textHint: 'A quê',
    options: [
      ChamuOption('drug', 'Medicamentos'),
      ChamuOption('food', 'Alimentos'),
      ChamuOption('latex', 'Látex'),
      ChamuOption('insect', 'Picadas de insetos'),
      ChamuOption('other', 'Outra'),
      ChamuOption('none', 'Sem alergias conhecidas'),
      ChamuOption('unknown', 'Desconhece'),
    ],
  ),
  ChamuQuestion(
    id: 'm',
    letter: 'M',
    title: 'Medicação habitual',
    summaryTitle: 'Medicação habitual',
    textHint: 'Nomes dos medicamentos',
  ),
];

/// Where the last meal is noted (the "U"), next to its time.
const chamuMealNote = 'u';

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

/// The CHAMU answers for a patient. Immutable.
@immutable
class Chamu {
  const Chamu({this.picks = const {}, this.notes = const {}, this.lastMeal});

  factory Chamu.fromJson(Map<String, dynamic> json) {
    final picks = <String, Set<String>>{};
    for (final q in chamuQuestions) {
      final valid = {for (final o in q.options) o.id};
      final ids = {
        for (final id in (json['picks']?[q.id] as List?) ?? const [])
          if (valid.contains(id)) id as String,
      };
      if (ids.isNotEmpty) picks[q.id] = ids;
    }
    return Chamu(
      picks: picks,
      notes: {
        for (final MapEntry(:key, :value)
            in ((json['notes'] as Map?) ?? const {}).entries)
          if ((value as String).isNotEmpty) key as String: value,
      },
      lastMeal: switch (json['meal']) {
        final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
        _ => null,
      },
    );
  }

  final Map<String, Set<String>> picks;
  final Map<String, String> notes;
  final DateTime? lastMeal;

  Set<String> picked(ChamuQuestion q) => picks[q.id] ?? const {};

  String note(String id) => notes[id] ?? '';

  bool get isEmpty => picks.isEmpty && notes.isEmpty && lastMeal == null;

  /// The text box of [q] is open: always without a list, otherwise when an
  /// option that asks for it is picked.
  bool showsNote(ChamuQuestion q) =>
      q.textOnly || picked(q).any(q.textWhen.contains);

  /// Something was answered for [q].
  bool answered(ChamuQuestion q) => lineFor(q) != null;

  /// The last meal has a time or a note.
  bool get mealAnswered => lastMeal != null || note(chamuMealNote).isNotEmpty;

  /// How many of the five letters have an answer.
  int get answeredCount =>
      chamuQuestions.where(answered).length + (mealAnswered ? 1 : 0);

  Chamu _copy({
    Map<String, Set<String>>? picks,
    Map<String, String>? notes,
    ValueGetter<DateTime?>? lastMeal,
  }) => Chamu(
    picks: picks ?? this.picks,
    notes: notes ?? this.notes,
    lastMeal: lastMeal == null ? this.lastMeal : lastMeal(),
  );

  /// Picks [optionId] of [q], or unpicks it, honouring single-choice and
  /// the options that rule out the others.
  Chamu toggle(ChamuQuestion q, String optionId) {
    final now = picked(q);
    final Set<String> next;
    if (now.contains(optionId)) {
      next = {...now}..remove(optionId);
    } else if (q.single || q.exclusive.contains(optionId)) {
      next = {optionId};
    } else {
      next = {...now}
        ..removeAll(q.exclusive)
        ..add(optionId);
    }
    return _copy(
      picks: {
        for (final MapEntry(:key, :value) in picks.entries)
          if (key != q.id) key: value,
        if (next.isNotEmpty) q.id: next,
      },
    );
  }

  Chamu withNote(String id, String text) {
    final trimmed = text.trim();
    return _copy(
      notes: {
        for (final MapEntry(:key, :value) in notes.entries)
          if (key != id) key: value,
        if (trimmed.isNotEmpty) id: trimmed,
      },
    );
  }

  Chamu withLastMeal(DateTime? at) => _copy(lastMeal: () => at);

  /// What was answered for [q] on one line: "Hipertensão, Outra: gota".
  /// The text goes with the first option that asked for it; text left in a
  /// box that has since closed isn't an answer. Null when nothing was.
  String? lineFor(ChamuQuestion q) {
    final text = showsNote(q) ? note(q.id) : '';
    if (q.textOnly) return text.nullIfEmpty;
    final ticked = [
      for (final o in q.options)
        if (picked(q).contains(o.id)) o,
    ];
    if (ticked.isEmpty) return null;
    final host = text.isEmpty
        ? null
        : ticked.where((o) => q.textWhen.contains(o.id)).firstOrNull;
    return [for (final o in ticked) o == host ? '${o.label}: $text' : o.label]
        .join(', ');
  }

  Map<String, Object> toJson() => {
    if (picks.isNotEmpty)
      'picks': {
        for (final MapEntry(:key, :value) in picks.entries)
          key: (value.toList()..sort()),
      },
    if (notes.isNotEmpty) 'notes': notes,
    'meal': ?lastMeal?.millisecondsSinceEpoch,
  };
}
