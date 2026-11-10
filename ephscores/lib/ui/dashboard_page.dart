import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../cpr/cpr.dart';
import '../format.dart';
import '../history/history.dart';
import '../obstetrics/obstetrics.dart';
import '../patient/chamu.dart';
import '../patient/patient.dart';
import '../scores/adult.dart';
import '../scores/model.dart';
import '../scores/pediatric.dart';
import '../theme.dart';
import '../viaverde/via_verde.dart';
import '../vitals/vitals.dart';
import 'brand.dart';
import 'burn_page.dart';
import 'chamu_page.dart';
import 'contacts_page.dart';
import 'cpr_page.dart';
import 'evolution_page.dart';
import 'injuries_page.dart';
import 'obstetrics_page.dart';
import 'score_list_page.dart';
import 'via_verde_page.dart';
import 'vitals_page.dart';
import 'widgets.dart';

/// The open patient: entry to every assessment tool, plus the bar to
/// register evaluations, see the evolution and finish.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    void open(Widget page) => pushPage(context, page);

    String? filled(List<ScoreDefinition> scores) {
      final n = scores.where((s) => scope.scores.isFilled(s.id)).length;
      return n == 0 ? null : formatCount(n, 'preenchida', 'preenchidas');
    }

    return AnnotatedRegion(
      // Light status bar icons over the navy header.
      value: SystemUiOverlayStyle.light,
      child: ListenableBuilder(
        listenable: scope.patientState,
        builder: (context, _) {
          if (!scope.patient.isActive) return const SizedBox.shrink();
          final vitals = scope.scores.vitals;
          final recorded = Vital.values.where((v) => vitals[v] != null).length;
          final entries = [
            _MenuCard(
              icon: Icons.favorite,
              title: 'PCR e RCP',
              subtitle: 'SBV/DAE · metrónomo · ciclos · choques',
              badge: _cprBadge(scope.patient.cpr),
              onTap: () => open(const CprPage()),
            ),
            _MenuCard(
              icon: Icons.monitor_heart,
              title: 'Sinais vitais',
              subtitle: 'AVDS · FR · SpO₂ · FC · PA · Temp. · Dor · Glicemia',
              badge: recorded == 0
                  ? null
                  : formatCount(recorded, 'registado', 'registados'),
              onTap: () => open(const VitalsPage()),
            ),
            _MenuCard(
              icon: Icons.assignment,
              title: 'CHAMU',
              subtitle:
                  'Circunstâncias · História · Alergias · Medicação · '
                  'Última refeição',
              badge: _chamuBadge(scope.patient.chamu),
              onTap: () => open(const ChamuPage()),
            ),
            _MenuCard(
              icon: Icons.person,
              title: 'Escalas gerais',
              subtitle: adultScores.map((s) => s.name).join(' · '),
              badge: filled(adultScores),
              onTap: () => open(
                ScoreListPage(title: 'Escalas gerais', scores: adultScores),
              ),
            ),
            _MenuCard(
              icon: Icons.child_care,
              title: 'Escalas pediátricas',
              subtitle: pediatricScores.map((s) => s.name).join(' · '),
              badge: filled(pediatricScores),
              onTap: () => open(
                ScoreListPage(
                  title: 'Escalas pediátricas',
                  scores: pediatricScores,
                ),
              ),
            ),
            _MenuCard(
              icon: Icons.pregnant_woman,
              title: 'Grávida e parto',
              subtitle: 'Idade gestacional · alertas · parto · APGAR',
              badge: _pregnancyBadge(scope.patient.pregnancy, vitals),
              onTap: () => open(const ObstetricsPage()),
            ),
            _MenuCard(
              icon: Icons.personal_injury,
              title: 'Mapa de lesões',
              subtitle: 'Fraturas · feridas · hemorragias · contusões',
              badge: switch (scope.patient.injuries.affected.length) {
                0 => null,
                final n => formatCount(n, 'região', 'regiões'),
              },
              onTap: () => open(const InjuriesPage()),
            ),
            _MenuCard(
              icon: Icons.local_fire_department,
              title: 'Avaliação do queimado',
              subtitle: 'Regra dos nove · adulto e criança',
              badge: scope.burn.isEmpty
                  ? null
                  : 'SCQ ${formatPercent(scope.burn.tbsa)}',
              onTap: () => open(const BurnPage()),
            ),
            _MenuCard(
              icon: Icons.alt_route,
              title: 'Vias Verdes',
              subtitle: viasVerdes.map((p) => p.name).join(' · '),
              badge: _viaVerdeBadge(scope.clinicalState()),
              onTap: () => open(const ViaVerdePage()),
            ),
            _MenuCard(
              icon: Icons.phone,
              title: 'Contactos úteis',
              subtitle: 'Linhas de apoio e emergência',
              onTap: () => open(const ContactsPage()),
            ),
          ];
          return Scaffold(
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // Fills the screen when everything fits; scrolls otherwise.
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(patient: scope.patient),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final (i, entry) in entries.indexed) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    Expanded(child: entry),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Keeps the status bar navy when the cards scroll under it
                // (short screens), so its light icons stay readable.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.paddingOf(context).top,
                  child: const ColoredBox(color: Palette.navy),
                ),
              ],
            ),
            bottomNavigationBar: const _PatientBar(),
          );
        },
      ),
    );
  }
}

/// "Em curso · 3 ciclos · 1 choque".
String? _cprBadge(Cpr? cpr) {
  if (cpr == null) return null;
  return [cpr.isOngoing ? 'Em curso' : cpr.end!.label, cpr.counts].join(' · ');
}

/// "3 de 5": the letters of CHAMU with something recorded.
String? _chamuBadge(Chamu chamu) => switch (chamu.answeredCount) {
  0 => null,
  final n => '$n de 5',
};

/// "38 semanas · Nascimento 14:05 · 2 alertas".
String? _pregnancyBadge(Pregnancy? p, VitalSigns vitals) {
  if (p == null) return null;
  final alerts = pregnancyFlags(p, vitals).length;
  return [
    p.weeks == null ? 'Grávida' : formatCount(p.weeks!, 'semana', 'semanas'),
    if (p.birth case final b?) 'Nascimento ${formatClock(b.bornAt)}',
    if (alerts > 0) formatCount(alerts, 'alerta', 'alertas'),
  ].join(' · ');
}

/// "Critérios: AVC" when a pathway is met, otherwise the ones to check.
String? _viaVerdeBadge(ClinicalState state) {
  final results = {for (final p in viasVerdes) p: p.check(state).result};
  List<String> withSeverity(Severity s) => [
    for (final MapEntry(key: p, value: r) in results.entries)
      if (r.severity == s) p.name,
  ];
  final met = withSeverity(Severity.danger);
  if (met.isNotEmpty) return 'Critérios: ${met.join(', ')}';
  final check = withSeverity(Severity.warning);
  if (check.isNotEmpty) return 'Verificar: ${check.join(', ')}';
  return null;
}

class _Header extends StatelessWidget {
  const _Header({required this.patient});

  final PatientStore patient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = patient.evaluations.length;
    return Container(
      decoration: const BoxDecoration(
        color: Palette.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Row(
            children: [
              const AppLogo(size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doente em avaliação',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Desde as ${formatClock(patient.startedAt!)} · '
                      '${switch (n) {
                        0 => 'nenhuma avaliação registada',
                        1 => '1 avaliação registada',
                        _ => '$n avaliações registadas',
                      }}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              _ReminderMenu(patient: patient),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chooses how often to be reminded to re-assess the patient.
class _ReminderMenu extends StatelessWidget {
  const _ReminderMenu({required this.patient});

  final PatientStore patient;

  @override
  Widget build(BuildContext context) {
    final current = patient.reminderMinutes;
    return PopupMenuButton<int>(
      tooltip: 'Lembrete de reavaliação',
      icon: Icon(
        current == null ? Icons.notifications_none : Icons.notifications_active,
        color: Colors.white,
      ),
      initialValue: current ?? 0,
      onSelected: (m) {
        patient.reminderMinutes = m == 0 ? null : m;
        showToast(
          context,
          m == 0
              ? 'Lembrete de reavaliação desligado'
              : 'Lembrete de reavaliação a cada $m min (com a aplicação aberta)',
        );
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 0, child: Text('Sem lembrete')),
        for (final m in reminderChoices)
          PopupMenuItem(value: m, child: Text('Reavaliar a cada $m min')),
      ],
    );
  }
}

enum _FinishChoice { register, discard }

class _PatientBar extends StatelessWidget {
  const _PatientBar();

  void _register(BuildContext context) {
    final scope = AppScope.of(context);
    final unchanged = !scope.hasUnsavedChanges;
    final e = scope.registerEvaluation();
    showToast(
      context,
      'Avaliação ${scope.patient.evaluations.length} registada às '
      '${formatClock(e.registeredAt)}${unchanged ? ' (sem alterações)' : ''}',
    );
  }

  Future<void> _finish(BuildContext context) async {
    final scope = AppScope.of(context);
    final navigator = Navigator.of(context);
    if (scope.hasUnsavedChanges) {
      final choice = await showDialog<_FinishChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finalizar doente?'),
          content: const Text(
            'Há alterações desde a última avaliação. '
            'Registar a avaliação atual antes de finalizar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _FinishChoice.discard),
              child: const Text('Não registar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _FinishChoice.register),
              child: const Text('Registar'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      if (choice == _FinishChoice.register) scope.registerEvaluation();
    } else if (!await confirm(
      context,
      title: 'Finalizar doente?',
      message: scope.history.available
          ? 'Fica guardado no histórico durante '
                '${historyRetention.inDays} dias.'
          : 'O resumo fica disponível até iniciar um novo doente.',
      action: 'Finalizar',
    )) {
      return;
    }
    scope.finishPatient();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const EvolutionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    // Listens itself: as a const child it is not rebuilt with the page.
    return ListenableBuilder(
      listenable: scope.patientState,
      builder: (context, _) => _buildBar(context, scope),
    );
  }

  Widget _buildBar(BuildContext context, AppScope scope) {
    if (!scope.patient.isActive) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final count = scope.patient.evaluations.length;
    const height = Size.fromHeight(52);
    const text = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    final outlined = OutlinedButton.styleFrom(
      minimumSize: height,
      textStyle: text,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.pageBackground,
        border: Border(top: BorderSide(color: scheme.tileBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      style: outlined,
                      onPressed: () => pushPage(context, const EvolutionPage()),
                      child: FitText(
                        count == 0 ? 'Evolução' : 'Evolução ($count)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: height,
                        textStyle: text,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: scope.canRegister
                          ? () => _register(context)
                          : null,
                      icon: const Icon(Icons.save_alt),
                      label: FitText('Registar'),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton(
                        style: outlined,
                        onPressed: () => _finish(context),
                        child: FitText('Finalizar'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              _Clocks(patient: scope.patient),
            ],
          ),
        ),
      ),
    );
  }
}

/// Time since the patient started and since the last registration, kept
/// small so it doesn't compete with the tools.
class _Clocks extends StatefulWidget {
  const _Clocks({required this.patient});

  final PatientStore patient;

  @override
  State<_Clocks> createState() => _ClocksState();
}

class _ClocksState extends State<_Clocks> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    if (!p.isActive) return const SizedBox.shrink();
    final now = DateTime.now();
    final total = formatTimer(now.difference(p.startedAt!));
    final current = formatTimer(now.difference(p.evaluationStartedAt));
    final next = p.evaluations.length + 1;
    final onset = p.onset;
    final symptoms = onset == null
        ? null
        : formatTimer(now.difference(onset.at));
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      label:
          'Doente há $total, avaliação $next há $current'
          '${symptoms == null ? '' : ', sintomas há $symptoms'}',
      excludeSemantics: true,
      // Shrinks rather than wraps: it must stay a single, quiet line.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: style?.color),
            const SizedBox(width: 4),
            Text('Doente $total', style: style),
            Text('   ·   ', style: style),
            Text('Avaliação $next  $current', style: style),
            if (symptoms != null) ...[
              Text('   ·   ', style: style),
              Text('Sintomas $symptoms', style: style),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 88),
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Palette.navy,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 34, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
