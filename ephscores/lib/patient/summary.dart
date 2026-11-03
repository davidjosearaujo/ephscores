import '../burn/burn.dart';
import '../format.dart';
import '../scores/model.dart';
import 'patient.dart';

/// One line per answered score: "ECG: 13 — Ligeiro (O3 V4 M6)".
String scoreLine(ScoreDefinition score, ScoreResult r) {
  if (!r.complete) {
    return '${score.name}: ${r.display} (incompleto, ${r.answered}/${r.total})';
  }
  final breakdown = r.breakdown == null ? '' : ' (${r.breakdown})';
  return '${score.name}: ${r.display} — ${r.label}$breakdown';
}

/// "Queimados (adulto): SCQ 13,5% — 2.º grau 9%, 3.º grau 4,5%".
String burnLine(BurnSheet b) {
  final who = b.patient == BurnPatient.adult ? 'adulto' : 'criança';
  final parts = [
    for (final d in [BurnDegree.second, BurnDegree.third, BurnDegree.first])
      if (b.percentWhere((x) => x == d) > 0)
        '${d.label} ${formatPercent(b.percentWhere((x) => x == d))}',
  ];
  return 'Queimados ($who): SCQ ${formatPercent(b.tbsa)} — ${parts.join(', ')}';
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
  for (final (i, e) in patient.evaluations.indexed) {
    out
      ..writeln()
      ..writeln(
        'Avaliação ${i + 1} — ${formatClock(e.registeredAt)} '
        '(duração ${formatDuration(e.duration)})',
      );
    for (final score in e.scores.answered) {
      out.writeln('- ${scoreLine(score, e.scores.resultFor(score.id))}');
    }
    if (e.burns.hasBurns) out.writeln('- ${burnLine(e.burns)}');
    if (e.scores.isEmpty && !e.burns.hasBurns) out.writeln('- Sem dados');
  }
  return out.toString().trimRight();
}
