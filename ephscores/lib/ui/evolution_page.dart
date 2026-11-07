import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../format.dart';
import '../patient/patient.dart';
import '../patient/summary.dart';
import '../scores/model.dart';
import '../scores/score_store.dart';
import '../theme.dart';
import '../vitals/vitals.dart';
import 'widgets.dart';

/// Timeline of the patient's registered evaluations.
class EvolutionPage extends StatelessWidget {
  const EvolutionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final patient = scope.patient;
    return ListenableBuilder(
      listenable: scope.patientState,
      builder: (context, _) {
        if (patient.startedAt == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Evolução')),
            body: const Center(child: Text('Sem doente')),
          );
        }
        final evaluations = patient.evaluations;
        return Scaffold(
          appBar: AppBar(title: const Text('Evolução')),
          body: ListView(
            padding: listPadding,
            children: [
              _SummaryCard(
                patient: patient,
                unsaved: patient.isActive && scope.hasUnsavedChanges,
              ),
              if (evaluations.isEmpty)
                _EmptyState(patient: patient)
              else ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: patientSummary(patient)),
                    );
                    if (context.mounted) showToast(context, 'Resumo copiado');
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar resumo (ISBAR)'),
                ),
                const SectionLabel('Tendência'),
                _TrendTable(evaluations: evaluations),
                const SectionLabel('Avaliações'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    'Mantenha premida uma avaliação para a apagar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final (i, e) in evaluations.indexed.toList().reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EvaluationCard(
                      index: i,
                      evaluation: e,
                      isLatest: i == evaluations.length - 1,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.patient, required this.unsaved});

  final PatientStore patient;
  final bool unsaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onPrimaryContainer;
    final start = patient.startedAt!;
    final end = patient.finishedAt;
    final n = patient.evaluations.length;
    final body = theme.textTheme.bodyMedium?.copyWith(color: fg);
    return Card(
      color: theme.colorScheme.primaryContainer,
      shape: filledCardShape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              end == null ? 'Em curso' : 'Finalizado',
              style: theme.textTheme.titleMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Início: ${formatDate(start)} ${formatClock(start)}',
              style: body,
            ),
            Text(
              end == null
                  ? 'Há ${formatDuration(DateTime.now().difference(start))}'
                  : 'Fim: ${formatClock(end)} · '
                        'duração ${formatDuration(end.difference(start))}',
              style: body,
            ),
            Text('$n ${n == 1 ? 'avaliação' : 'avaliações'}', style: body),
            for (final MapEntry(key: event, value: at)
                in patient.events.entries)
              Text('${event.label}: ${formatClock(at)}', style: body),
            if (patient.onset case final onset?)
              Text(
                '${onset.label}: ${formatClock(onset.at)} '
                '(há ${formatDuration((end ?? DateTime.now()).difference(onset.at))})',
                style: body,
              ),
            if (unsaved) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.edit_note, size: 18, color: fg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Há alterações por registar no painel.',
                      style: body?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.patient});

  final PatientStore patient;

  Future<void> _cancelPatient(BuildContext context) async {
    final scope = AppScope.of(context);
    if (!await confirm(
      context,
      title: 'Cancelar doente?',
      message: 'Descarta o doente e todas as respostas, sem guardar nada.',
      action: 'Cancelar doente',
    )) {
      return;
    }
    if (context.mounted) Navigator.pop(context);
    scope.discardPatient();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.timeline, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'Ainda sem avaliações registadas.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'No painel, use "Registar" para guardar a avaliação atual.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (patient.isActive) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _cancelPatient(context),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar doente'),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _resultCell(ScoreResult? result, Widget empty) =>
    result == null ? empty : ResultPill(result, compact: true);

/// Scores as rows, evaluations as columns. The names stay put while the
/// values scroll; the newest evaluation is shown first.
class _TrendTable extends StatelessWidget {
  const _TrendTable({required this.evaluations});

  final List<Evaluation> evaluations;

  static const _headerHeight = 44.0;
  static const _rowHeight = 44.0;
  static const _cellWidth = 64.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ids = {for (final e in evaluations) ...e.results.keys};
    final scores = [
      for (final s in allScores.values)
        if (ids.contains(s.id)) s,
    ];
    final burns = evaluations.any((e) => e.burns.hasBurns);
    final dash = Text('–', style: TextStyle(color: theme.colorScheme.outline));
    // Vital signs first, as on the national form; age doesn't trend, and
    // the two pressures share a row.
    final vitals = [
      for (final v in Vital.values)
        if (v != Vital.age &&
            v != Vital.dbp &&
            evaluations.any(
              (e) => v == Vital.sbp
                  ? e.scores.vitals.bloodPressure != null
                  : e.scores.vitals[v] != null,
            ))
          v,
    ];
    final shock = evaluations.any((e) => e.scores.vitals.shockIndex != null);
    Widget vitalCell(VitalSigns v, Vital vital) {
      final text = vital == Vital.sbp ? v.bloodPressure : v.cell(vital);
      return text == null
          ? dash
          : FitText(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            );
    }

    Widget cell(Widget child) => SizedBox(
      height: _rowHeight,
      child: Center(child: child),
    );
    Widget name(String text) => SizedBox(
      height: _rowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FitText(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: _headerHeight),
                  for (final v in vitals) name(v == Vital.sbp ? 'PA' : v.short),
                  if (shock) name('IC'),
                  for (final s in scores) name(s.name),
                  if (burns) name('SCQ'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    for (final (i, e) in evaluations.indexed)
                      SizedBox(
                        width: _cellWidth,
                        child: Column(
                          children: [
                            SizedBox(
                              height: _headerHeight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '#${i + 1}',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      formatClock(e.registeredAt),
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            for (final v in vitals)
                              cell(vitalCell(e.scores.vitals, v)),
                            if (shock)
                              cell(
                                e.scores.vitals.shockIndex == null
                                    ? dash
                                    : ResultPill(
                                        shockIndexResult(
                                          e.scores.vitals.shockIndex!,
                                        ),
                                        compact: true,
                                      ),
                              ),
                            for (final s in scores)
                              cell(_resultCell(e.results[s.id], dash)),
                            if (burns)
                              cell(
                                e.burns.hasBurns
                                    ? BurnPill(e.burns.tbsa, compact: true)
                                    : dash,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({
    required this.index,
    required this.evaluation,
    required this.isLatest,
  });

  /// Position in the timeline, oldest first.
  final int index;
  final Evaluation evaluation;
  final bool isLatest;

  Future<void> _delete(BuildContext context) async {
    final patient = AppScope.of(context).patient;
    if (await confirmDelete(
      context,
      title: 'Apagar avaliação ${index + 1}?',
      message: 'As respostas atuais no painel não são alteradas.',
    )) {
      patient.removeAt(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = evaluation;
    final vitals = e.scores.vitals;
    final si = vitals.shockIndex;
    final n =
        e.results.length +
        (e.burns.hasBurns ? 1 : 0) +
        (vitals.isEmpty ? 0 : 1);
    return GestureDetector(
      onLongPress: () => _delete(context),
      child: Card(
        child: ExpansionTile(
          // Keyed by time so expansion state follows the evaluation, not its
          // position, when another one is deleted.
          key: PageStorageKey(e.registeredAt),
          initiallyExpanded: isLatest,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            'Avaliação ${index + 1} · ${formatClock(e.registeredAt)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Duração ${formatDuration(e.duration)} · '
            '$n ${n == 1 ? 'registo' : 'registos'}',
          ),
          children: [
            if (!vitals.isEmpty)
              _ResultRow(
                title: 'Sinais vitais',
                subtitle: vitals.summary(),
                trailing: si == null
                    ? null
                    : ResultPill(shockIndexResult(si), compact: true),
              ),
            for (final MapEntry(key: id, value: r) in e.results.entries)
              _ResultRow(
                title: allScores[id]!.name,
                subtitle: _detail(r),
                trailing: ResultPill(r, compact: true),
              ),
            if (e.burns.hasBurns)
              _ResultRow(
                title: 'Queimados',
                subtitle: burnDetail(e.burns),
                trailing: BurnPill(e.burns.tbsa, compact: true),
              ),
            if (n == 0) const ListTile(dense: true, title: Text('Sem dados')),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _detail(ScoreResult r) {
    if (!r.complete) return 'Incompleto (${r.answered}/${r.total})';
    return [r.label, ?r.breakdown].join(' · ');
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}
