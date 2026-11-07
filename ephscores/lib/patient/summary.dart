import '../burn/burn.dart';
import '../format.dart';
import '../scores/model.dart';
import '../scores/score_store.dart';
import '../viaverde/via_verde.dart';
import '../vitals/vitals.dart';
import 'patient.dart';

/// One line per answered score: "ECG: 13 — Ligeiro (O3 V4 M6)".
String scoreLine(ScoreDefinition score, ScoreResult r) {
  if (!r.complete) {
    return '${score.name}: ${r.display} (incompleto, ${r.answered}/${r.total})';
  }
  final breakdown = r.breakdown == null ? '' : ' (${r.breakdown})';
  return '${score.name}: ${r.display} — ${r.label}$breakdown';
}

/// Surface per degree: "2.º grau 9%, 3.º grau 4,5%".
String burnDetail(BurnSheet b) => [
  for (final d in [BurnDegree.second, BurnDegree.third, BurnDegree.first])
    if (b.percentWhere((x) => x == d) > 0)
      '${d.label} ${formatPercent(b.percentWhere((x) => x == d))}',
].join(', ');

/// "Queimados (adulto): SCQ 13,5% — 2.º grau 9%, 3.º grau 4,5%".
String burnLine(BurnSheet b) {
  final who = b.patient == BurnPatient.adult ? 'adulto' : 'criança';
  return 'Queimados ($who): SCQ ${formatPercent(b.tbsa)} — ${burnDetail(b)}';
}

/// Plain-text handover summary in the ISBAR structure of INEM's national
/// form (Identificação, Situação, Background, Avaliação, Recomendações), to
/// read out or paste into a report.
String patientSummary(PatientRecord patient, {DateTime? now}) {
  final start = patient.startedAt!;
  final end = patient.finishedAt ?? now ?? DateTime.now();
  final evaluations = patient.evaluations;
  final last = evaluations.lastOrNull;
  final vitals = last?.scores.vitals;
  final out = StringBuffer()
    ..writeln('EPHScores — resumo ISBAR')
    ..writeln(
      'Início: ${formatDate(start)} ${formatClock(start)} · '
      '${patient.isFinished ? 'fim ${formatClock(end)} '
                '(${formatDuration(end.difference(start))})' : 'em curso há ${formatDuration(end.difference(start))}'}',
    );
  final events = patient.events;
  if (events.isNotEmpty) {
    out.writeln(
      'Horas: ${[for (final MapEntry(:key, :value) in events.entries) '${key.label} ${formatClock(value)}'].join(' · ')}',
    );
  }

  void section(String letter, String title, List<String> lines) {
    out
      ..writeln()
      ..writeln('$letter — $title');
    // Lines starting with two spaces are nested under the one before.
    for (final l in lines) {
      out.writeln(l.startsWith('  ') ? '  - ${l.trimLeft()}' : '- $l');
    }
  }

  final age = vitals?[Vital.age];
  section('I', 'Identificação', [
    age == null ? 'Idade não registada' : 'Vítima de $age anos',
  ]);

  final onset = patient.onset;
  final pathways = viaVerdeStatus(patient);
  final situation = [
    if (onset != null)
      '${onset.label}: ${formatClock(onset.at)} '
          '(há ${formatDuration(end.difference(onset.at))})',
    for (final (p, c) in pathways) '${p.fullName}: ${c.result.label}',
    if (last != null) ...alterations(last),
    if (last == null) 'Sem avaliações registadas',
  ];
  section(
    'S',
    'Situação atual',
    situation.isEmpty ? ['Sem alterações de gravidade'] : situation,
  );

  section('B', 'Antecedentes', [
    'A completar: doenças, medicação habitual, alergias',
  ]);

  section('A', 'Avaliação', [
    if (last != null) ...[
      'Avaliação ${evaluations.length} (${formatClock(last.registeredAt)}):',
      if (!last.scores.vitals.isEmpty)
        '  Sinais vitais: ${last.scores.vitals.summary()}',
      for (final MapEntry(key: id, value: r) in last.results.entries)
        '  ${scoreLine(allScores[id]!, r)}',
      if (last.burns.hasBurns) '  ${burnLine(last.burns)}',
    ],
    if (evaluations.length > 1) ...[
      'Evolução:',
      for (final (i, e) in evaluations.indexed)
        '  #${i + 1} ${formatClock(e.registeredAt)}: ${compactLine(e)}',
    ],
  ]);

  section('R', 'Recomendações', [
    for (final (p, c) in pathways) '${p.fullName}: ${c.metLabels.join('; ')}',
    if (pathways.isEmpty) 'Sem critérios de Via Verde',
  ]);
  return out.toString().trimRight();
}

/// What is abnormal at [e]: scores in amber or red, the shock index and the
/// glucose flag. "NEWS2 8 (Risco alto)".
List<String> alterations(Evaluation e) {
  final v = e.scores.vitals;
  final si = v.shockIndex;
  final glucose = v[Vital.glucose];
  final flag = glucose == null ? null : glucoseFlag(glucose);
  return [
    for (final MapEntry(key: id, value: r) in e.results.entries)
      if (r.complete && r.severity.isAlert)
        '${allScores[id]!.name} ${r.display} (${r.label})',
    if (si == null ? null : shockIndexResult(si) case final r?
        when r.severity.isAlert)
      'Índice de choque ${r.display} (${r.label})',
    ?flag?.$2,
    if (v[Vital.age] case final age?)
      for (final vital in [Vital.rr, Vital.hr, Vital.sbp])
        if (v[vital] case final value?)
          if (childFlag(vital, value, age) case final f?) f.$2,
  ];
}

/// One evaluation on one line, for the trend: "AVDS V · FR 26 · SpO₂ 90 ·
/// FC 122 · PA 84/50 · Temp. 39,2 · IC 1,45 · ECG 13 · NEWS2 16".
String compactLine(Evaluation e) {
  final v = e.scores.vitals;
  final si = v.shockIndex;
  final parts = [
    for (final vital in [Vital.avds, Vital.rr, Vital.spo2, Vital.hr])
      if (v.cell(vital) case final c?) '${vital.short} $c',
    if (v.bloodPressure case final bp?) 'PA $bp',
    if (v.cell(Vital.temp) case final t?) 'Temp. $t',
    if (si != null) 'IC ${formatShockIndex(si)}',
    for (final MapEntry(key: id, value: r) in e.results.entries)
      '${allScores[id]!.name} ${r.display}',
    if (e.burns.hasBurns) 'SCQ ${formatPercent(e.burns.tbsa)}',
  ];
  return parts.isEmpty ? 'sem dados' : parts.join(' · ');
}

/// The pathways met, or with signs to check, at the last evaluation, with
/// their criteria.
List<(ViaVerde, CriteriaCheck)> viaVerdeStatus(PatientRecord patient) {
  if (patient.evaluations.isEmpty) return const [];
  final last = patient.evaluations.last;
  final state = ClinicalState(
    scores: last.scores,
    burns: last.burns,
    onset: patient.onset,
    checks: patient.checks,
    now: last.registeredAt,
  );
  return [
    for (final p in viasVerdes)
      // Met, or signs to check; partial counts ("1 de 4 campos") are noise
      // at handover.
      if (p.check(state) case final c when c.result.severity.isAlert) (p, c),
  ];
}
