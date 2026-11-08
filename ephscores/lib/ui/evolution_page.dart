import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../format.dart';
import '../history/history.dart';
import '../patient/patient.dart';
import '../patient/summary.dart';
import '../scores/model.dart';
import '../scores/score_store.dart';
import '../theme.dart';
import '../vitals/vitals.dart';
import 'widgets.dart';

/// Timeline of the patient's registered evaluations: the patient in
/// progress (or the last one), or, read-only, one from the history.
class EvolutionPage extends StatelessWidget {
  const EvolutionPage({super.key, this.entry});

  /// A patient from the history; null for the live patient.
  final HistoryEntry? entry;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    if (entry != null) {
      return _Evolution(
        title: 'Doente de ${formatDate(entry.startedAt)}',
        patient: entry.patient,
        expiresAt: entry.expiresAt,
      );
    }
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
        return _Evolution(
          title: 'Evolução',
          patient: patient,
          unsaved: patient.isActive && scope.hasUnsavedChanges,
          onDelete: scope.removeEvaluation,
          empty: _EmptyState(patient: patient),
        );
      },
    );
  }
}

class _Evolution extends StatelessWidget {
  const _Evolution({
    required this.title,
    required this.patient,
    this.unsaved = false,
    this.onDelete,
    this.empty,
    this.expiresAt,
  });

  final String title;
  final PatientRecord patient;
  final bool unsaved;

  /// Deletes an evaluation by index; null when read-only.
  final ValueChanged<int>? onDelete;
  final Widget? empty;

  /// When a patient from the history will be deleted.
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final evaluations = patient.evaluations;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: listPadding,
        children: [
          _SummaryCard(
            patient: patient,
            unsaved: unsaved,
            expiresAt: expiresAt,
          ),
          if (evaluations.isEmpty)
            empty ??
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Sem avaliações registadas.')),
                )
          else ...[
            const SizedBox(height: 12),
            _ShareButton(patient),
            const SectionLabel('Tendência'),
            _TrendTable(evaluations: evaluations),
            const SectionLabel('Avaliações'),
            if (onDelete != null)
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
                  onDelete: onDelete == null ? null : () => onDelete!(i),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Opens the system share menu with the ISBAR summary: messaging apps,
/// notes, e-mail, and Quick Share / AirDrop to a phone nearby. Where the
/// browser can't share, copies it instead.
class _ShareButton extends StatelessWidget {
  const _ShareButton(this.patient);

  final PatientRecord patient;

  Future<void> _share(BuildContext context) async {
    final text = patientSummary(patient);
    // iPad shows the menu as a popover anchored to the button.
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'EPHScores — resumo ISBAR',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) showToast(context, 'Resumo copiado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      onPressed: () => _share(context),
      icon: const Icon(Icons.share),
      label: const Text('Partilhar resumo (ISBAR)'),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.patient,
    required this.unsaved,
    this.expiresAt,
  });

  final PatientRecord patient;
  final DateTime? expiresAt;
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
            Text(formatCount(n, 'avaliação', 'avaliações'), style: body),
            for (final MapEntry(key: event, value: at)
                in patient.events.entries)
              Text('${event.label}: ${formatClock(at)}', style: body),
            if (patient.pregnancy case final p?)
              Text(p.headline(), style: body),
            if (patient.pregnancy?.birth case final b?)
              Text('Nascimento: ${formatClock(b.bornAt)}', style: body),
            if (patient.onset case final onset?)
              Text(onsetLine(onset, end ?? DateTime.now()), style: body),
            if (expiresAt case final at?)
              Text('Guardado até ${formatDate(at)}', style: body),
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
    Widget pill(ScoreResult? r) =>
        r == null ? dash : ResultPill(r, compact: true);
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
                            if (shock) cell(pill(e.scores.vitals.shockResult)),
                            for (final s in scores) cell(pill(e.results[s.id])),
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
    this.onDelete,
  });

  /// Deletes this evaluation (after confirmation); null when read-only.
  final VoidCallback? onDelete;

  /// Position in the timeline, oldest first.
  final int index;
  final Evaluation evaluation;
  final bool isLatest;

  Future<void> _delete(BuildContext context) async {
    if (await confirmDelete(
      context,
      title: 'Apagar avaliação ${index + 1}?',
      message: 'As respostas atuais no painel não são alteradas.',
    )) {
      onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = evaluation;
    final vitals = e.scores.vitals;
    final shock = vitals.shockResult;
    final n =
        e.results.length +
        (e.burns.hasBurns ? 1 : 0) +
        (vitals.isEmpty ? 0 : 1);
    return GestureDetector(
      onLongPress: onDelete == null ? null : () => _delete(context),
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
            '${formatCount(n, 'registo', 'registos')}',
          ),
          children: [
            if (!vitals.isEmpty)
              _ResultRow(
                title: 'Sinais vitais',
                subtitle: vitals.summary(),
                trailing: shock == null
                    ? null
                    : ResultPill(shock, compact: true),
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
