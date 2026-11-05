import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../format.dart';
import '../patient/patient.dart';
import '../theme.dart';
import '../viaverde/via_verde.dart';
import 'widgets.dart';

/// The time [picked] on the clock, on the most recent day it isn't in the
/// future: a time later than now is taken as yesterday.
DateTime resolveClockTime(TimeOfDay picked, DateTime now) {
  final today = DateTime(
    now.year,
    now.month,
    now.day,
    picked.hour,
    picked.minute,
  );
  return today.isAfter(now) ? today.subtract(const Duration(days: 1)) : today;
}

/// Symptom onset and the criteria of each Via Verde.
class ViaVerdePage extends StatelessWidget {
  const ViaVerdePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.patientState,
      builder: (context, _) {
        final state = scope.clinicalState();
        return Scaffold(
          appBar: AppBar(title: const Text('Vias Verdes')),
          body: ListView(
            padding: listPadding,
            children: [
              _OnsetCard(patient: scope.patient),
              const SizedBox(height: 4),
              for (final p in viasVerdes)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _PathwayCard(
                    // Keyed so the expansion follows the pathway.
                    key: PageStorageKey(p.id),
                    check: p.check(state),
                    onToggle: (c) => scope.patient.toggleCheck('${p.id}.$c'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OnsetCard extends StatefulWidget {
  const _OnsetCard({required this.patient});

  final PatientStore patient;

  @override
  State<_OnsetCard> createState() => _OnsetCardState();
}

class _OnsetCardState extends State<_OnsetCard> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // Keeps "há …" current.
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _pick() async {
    final patient = widget.patient;
    final current = patient.onset;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current?.at ?? DateTime.now()),
      helpText: 'Hora de início dos sintomas',
    );
    if (picked == null) return;
    patient.onset = Onset(
      resolveClockTime(picked, DateTime.now()),
      lastSeenWell: current?.lastSeenWell ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onPrimaryContainer;
    final patient = widget.patient;
    final onset = patient.onset;
    final now = DateTime.now();
    final body = theme.textTheme.bodyMedium?.copyWith(color: fg);
    return Card(
      color: theme.colorScheme.primaryContainer,
      shape: filledCardShape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              onset?.label ?? 'Início dos sintomas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            if (onset == null)
              Text(
                'Não registado. Necessário para as janelas de tempo das '
                'Vias Verdes AVC e Coronária.',
                style: body,
              )
            else ...[
              Text(
                [
                  if (!DateUtils.isSameDay(onset.at, now)) formatDate(onset.at),
                  formatClock(onset.at),
                ].join(' '),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Há ${formatDuration(now.difference(onset.at))}',
                style: body,
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: FitText('Hora exata')),
                  ButtonSegment(
                    value: true,
                    label: FitText('Visto bem pela última vez'),
                  ),
                ],
                selected: {onset.lastSeenWell},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    patient.onset = Onset(onset.at, lastSeenWell: s.first),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => patient.onset = Onset(
                      DateTime.now(),
                      lastSeenWell: onset?.lastSeenWell ?? false,
                    ),
                    child: const FitText('Agora'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _pick,
                    child: FitText(onset == null ? 'Escolher hora' : 'Alterar'),
                  ),
                ),
                if (onset != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Limpar hora',
                    color: fg,
                    onPressed: () => patient.onset = null,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PathwayCard extends StatelessWidget {
  const _PathwayCard({super.key, required this.check, required this.onToggle});

  final CriteriaCheck check;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = check.pathway;
    final result = check.result;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      child: ExpansionTile(
        initiallyExpanded: result.display != '–',
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          p.fullName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        subtitle: Text(
          '${result.label} · ${p.scope}',
          style: TextStyle(
            fontWeight: result.complete ? FontWeight.w600 : null,
          ),
        ),
        trailing: ResultPill(result),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in p.groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      g.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (check.groupMet(g))
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: theme.colorScheme.primary,
                    )
                  else if (g.all)
                    Text('Todos', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            for (final c in g.criteria)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CriterionTile(
                  criterion: c,
                  met: check.met(c.id),
                  reason: check.reasons[c.id],
                  onTap: check.isAuto(c.id) || !c.manual
                      ? null
                      : () => onToggle(c.id),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              'Atuação',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final a in p.actions)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: theme.textTheme.bodyMedium),
                  Expanded(child: Text(a, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
            child: Text('Fonte: ${p.source}', style: small),
          ),
        ],
      ),
    );
  }
}

class _CriterionTile extends StatelessWidget {
  const _CriterionTile({
    required this.criterion,
    required this.met,
    required this.reason,
    required this.onTap,
  });

  final Criterion criterion;
  final bool met;

  /// Why it is met automatically; '' when ticked by hand.
  final String? reason;

  /// Null when the data decide it (automatic, or a time window).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final auto = reason?.isNotEmpty ?? false;
    final note = auto ? 'Automático: $reason' : criterion.detail;
    return SelectableTile(
      selected: met,
      onTap: onTap ?? () => showToast(context, _why(auto)),
      builder: (fg) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  criterion.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 13,
                      color: fg.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
          if (met)
            Icon(auto ? Icons.auto_awesome : Icons.check, color: fg, size: 20),
        ],
      ),
    );
  }

  String _why(bool auto) => auto
      ? 'Cumprido pelos dados registados. Altere-os para o desmarcar.'
      : 'Preenchido automaticamente: ${criterion.detail ?? 'pelos dados registados'}.';
}
