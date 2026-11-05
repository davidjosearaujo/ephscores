import '../burn/burn.dart';
import '../format.dart';
import '../scores/model.dart';
import '../scores/score_store.dart';
import '../viaverde/via_verde.dart';
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

/// Plain-text summary to paste into a report or message.
String patientSummary(PatientStore patient, {DateTime? now}) {
  final start = patient.startedAt!;
  final end = patient.finishedAt ?? now ?? DateTime.now();
  final out = StringBuffer()
    ..writeln('EPHScores — evolução do doente')
    ..writeln('Início: ${formatDate(start)} ${formatClock(start)}')
    ..writeln(
      patient.isFinished
          ? 'Fim: ${formatClock(end)} (${formatDuration(end.difference(start))})'
          : 'Em curso há ${formatDuration(end.difference(start))}',
    )
    ..writeln('Avaliações: ${patient.evaluations.length}');
  if (patient.onset case final onset?) {
    out.writeln(
      '${onset.label}: ${formatDate(onset.at)} ${formatClock(onset.at)}',
    );
  }
  for (final (i, e) in patient.evaluations.indexed) {
    out
      ..writeln()
      ..writeln(
        'Avaliação ${i + 1} — ${formatClock(e.registeredAt)} '
        '(duração ${formatDuration(e.duration)})',
      );
    if (!e.scores.vitals.isEmpty) {
      out.writeln('- Sinais vitais: ${e.scores.vitals.summary()}');
    }
    for (final MapEntry(key: id, value: result) in e.results.entries) {
      out.writeln('- ${scoreLine(allScores[id]!, result)}');
    }
    if (e.burns.hasBurns) out.writeln('- ${burnLine(e.burns)}');
    if (e.results.isEmpty && !e.burns.hasBurns && e.scores.vitals.isEmpty) {
      out.writeln('- Sem dados');
    }
  }
  final pathways = viaVerdeLines(patient);
  if (pathways.isNotEmpty) {
    out
      ..writeln()
      ..writeln('Vias Verdes (avaliação ${patient.evaluations.length}):');
    pathways.forEach(out.writeln);
  }
  return out.toString().trimRight();
}

/// The pathways with any criterion met at the last evaluation:
/// "- Via Verde AVC: Critérios cumpridos: contactar CODU — Assimetria facial
/// (Cincinnati); Idade ≥ 18 anos; ...".
List<String> viaVerdeLines(PatientStore patient) {
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
      if (p.check(state) case final c when c.reasons.isNotEmpty)
        '- ${p.fullName}: ${c.result.label} — ${c.metLabels.join('; ')}',
  ];
}
