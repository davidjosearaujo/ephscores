import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../cpr/cpr.dart';
import '../cpr/metronome.dart';
import '../format.dart';
import '../theme.dart';
import 'widgets.dart';

/// Name of the CPR page's route: the pull tab hides while it is open.
const cprRoute = 'cpr';

/// Starts the resuscitation at once, from anywhere (the pull tab, the
/// launcher shortcut): opens a patient if none is open, stamps the start and
/// shows the CPR page with the metronome running. Where a resuscitation is
/// already registered, just opens its page.
Future<void> beginCpr(NavigatorState navigator) async {
  final scope = AppScope.of(navigator.context);
  final patient = scope.patient;
  if (!patient.isActive) {
    // Starting a patient replaces the last one; where nothing else keeps it,
    // ask first.
    if (patient.isFinished &&
        !scope.history.available &&
        !await confirm(
          navigator.context,
          title: 'Novo doente?',
          message: 'O resumo do doente anterior será apagado.',
          action: 'Novo doente',
        )) {
      return;
    }
    scope.startPatient();
  }
  patient.cpr ??= Cpr(startedAt: DateTime.now());
  navigator.push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: cprRoute),
      builder: (_) => CprPage(startMetronome: patient.cpr!.isOngoing),
    ),
  );
}

/// Cardiac arrest: the metronome that paces the compressions, a tap counter
/// for the cycles (a tap each time the AED analyses), a shock counter, and
/// the end of the resuscitation. The screen stays on while it is open.
class CprPage extends StatefulWidget {
  const CprPage({super.key, this.startMetronome = false});

  /// Start beating as soon as the page opens.
  final bool startMetronome;

  @override
  State<CprPage> createState() => _CprPageState();
}

class _CprPageState extends State<CprPage> with KeepScreenOn {
  final _metronome = Metronome();
  late final _patient = AppScope.of(context).patient;
  late final Timer _clock;

  @override
  void initState() {
    super.initState();
    if (widget.startMetronome) _metronome.start();
    // Only a resuscitation under way has a clock to redraw.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_patient.cpr?.isOngoing ?? false) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _metronome.dispose();
    super.dispose();
  }

  void _update(Cpr Function(Cpr cpr) change) =>
      _patient.cpr = change(_patient.cpr!);

  void _start() {
    HapticFeedback.mediumImpact();
    _patient.cpr = Cpr(startedAt: DateTime.now());
    _metronome.start();
  }

  void _end(CprEnd how) {
    _metronome.stop();
    _update((c) => c.finish(how, DateTime.now()));
  }

  void _resume() {
    _update((c) => c.resume());
    _metronome.start();
  }

  Future<void> _delete() async {
    if (!await confirm(
      context,
      title: 'Apagar a RCP?',
      message: 'Apaga a hora de início, os ciclos e os choques registados.',
      action: 'Apagar',
    )) {
      return;
    }
    _metronome.stop();
    _patient.cpr = null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _patient,
      builder: (context, _) {
        final cpr = _patient.cpr;
        return Scaffold(
          appBar: AppBar(
            title: const FitText('Paragem cardiorrespiratória'),
            actions: [
              if (cpr != null)
                IconButton(
                  tooltip: 'Apagar a RCP',
                  icon: const Icon(Icons.restart_alt),
                  onPressed: _delete,
                ),
            ],
          ),
          body: cpr == null ? _notStarted() : _board(cpr),
        );
      },
    );
  }

  Widget _notStarted() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Center(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.red,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(120),
        ),
        onPressed: _start,
        child: const FitText('Começar SBV/DAE'),
      ),
    ),
  );

  Widget _board(Cpr cpr) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final ongoing = cpr.isOngoing;
    return ListView(
      padding: listPadding,
      children: [
        const SizedBox(height: 8),
        HeroCard(
          title: ongoing ? 'RCP em curso' : cpr.end!.label,
          children: [
            Text(
              formatTimer(cpr.duration(now)),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: HeroCard.foreground(context),
              ),
            ),
            Text(
              ongoing
                  ? 'Início às ${formatClock(cpr.startedAt)}'
                  : 'Das ${formatClock(cpr.startedAt)} às '
                        '${formatClock(cpr.endedAt!)}',
            ),
          ],
        ),
        if (ongoing) ...[
          const SizedBox(height: 12),
          _MetronomeCard(metronome: _metronome),
        ],
        const SizedBox(height: 12),
        _CounterButton(
          count: cpr.cycles,
          label: cpr.cycles == 1 ? 'ciclo' : 'ciclos',
          height: 200,
          hint: _cycleHint(cpr, now),
          overdue: ongoing && cpr.sinceLastCycle(now) >= cprCycleLength,
          onTap: ongoing
              ? () => _update((c) => c.addCycle(DateTime.now()))
              : null,
          onUndo: cpr.cycles == 0
              ? null
              : () => _update((c) => c.removeLastCycle()),
          undoTooltip: 'Desfazer o último ciclo',
        ),
        const SizedBox(height: 12),
        _CounterButton(
          count: cpr.shocks,
          label: cpr.shocks == 1 ? 'choque' : 'choques',
          height: 110,
          hint: ongoing ? 'Toque a cada choque dado' : null,
          onTap: ongoing
              ? () => _update((c) => c.addShock(DateTime.now()))
              : null,
          onUndo: cpr.shocks == 0
              ? null
              : () => _update((c) => c.removeLastShock()),
          undoTooltip: 'Desfazer o último choque',
        ),
        const ItemHeader(title: 'Fim da RCP'),
        if (ongoing)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(64),
                  ),
                  onPressed: () => _end(CprEnd.rosc),
                  child: const FitText('Recuperou circulação'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(64),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _end(CprEnd.stopped),
                  child: const FitText('Suspender RCP'),
                ),
              ),
            ],
          )
        else ...[
          TimeStampTile(
            label: cpr.end!.label,
            at: cpr.endedAt,
            // Clearing the time takes the ending back.
            onChanged: (at) =>
                at == null ? _resume() : _update((c) => c.finish(c.end!, at)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: _resume,
            child: const Text('Retomar a RCP'),
          ),
        ],
        const ItemHeader(title: 'Início'),
        TimeStampTile(
          label: 'Início da RCP',
          at: cpr.startedAt,
          onChanged: (at) {
            if (at != null) return _update((c) => c.copyWith(startedAt: at));
            _delete();
          },
        ),
        const SizedBox(height: 8),
        TimeStampTile(
          label: 'SIV/SAV',
          detail: cpr.sivAt == null
              ? 'Toque quando a equipa chegar ao local'
              : null,
          at: cpr.sivAt,
          onChanged: (at) => _update((c) => c.withSiv(at)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
          child: Text(
            'Compressões a $cprMinRate–$cprMaxRate por minuto '
            '(ERC e AHA). O metrónomo usa o volume de multimédia.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  /// What the cycle button says under the count.
  String? _cycleHint(Cpr cpr, DateTime now) {
    if (!cpr.isOngoing) return null;
    if (cpr.cycles == 0) return 'Toque a cada análise do DAE';
    final since = formatTimer(cpr.sinceLastCycle(now));
    return cpr.sinceLastCycle(now) >= cprCycleLength
        ? 'Último ciclo há $since · mais de 2 min'
        : 'Último ciclo há $since';
  }
}

/// A big tap target that counts: the cycles and the shocks. The undo button
/// sits over its top left corner, away from the times bubble.
class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.count,
    required this.label,
    required this.height,
    required this.onTap,
    required this.onUndo,
    required this.undoTooltip,
    this.hint,
    this.overdue = false,
  });

  final int count;
  final String label;
  final double height;
  final String? hint;

  /// The last count is older than expected: the hint is highlighted.
  final bool overdue;

  /// Null while resuscitation is over.
  final VoidCallback? onTap;
  final VoidCallback? onUndo;
  final String undoTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final big = height > 150;
    final fg = onTap == null ? scheme.onSurface : scheme.onPrimaryContainer;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Card(
              color: onTap == null ? null : scheme.primaryContainer,
              shape: filledCardShape,
              child: InkWell(
                onTap: onTap == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onTap!();
                      },
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: big ? 96 : 40,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                      Text(
                        label,
                        style:
                            (big
                                    ? theme.textTheme.titleLarge
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      if (hint != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            hint!,
                            style: TextStyle(
                              color: fg,
                              fontWeight: overdue
                                  ? FontWeight.w800
                                  : FontWeight.w400,
                              decoration: overdue
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onUndo != null)
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                tooltip: undoTooltip,
                color: fg,
                onPressed: onUndo,
                icon: const Icon(Icons.undo),
              ),
            ),
        ],
      ),
    );
  }
}

/// The metronome: a light that beats, the rate with − and +, and play/stop.
class _MetronomeCard extends StatelessWidget {
  const _MetronomeCard({required this.metronome});

  final Metronome metronome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: metronome,
      builder: (context, _) {
        final m = metronome;
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                // Lights up with each beat.
                SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      width: m.flash ? 44 : 32,
                      height: m.flash ? 44 : 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: m.flash
                            ? Palette.red
                            : m.running
                            ? Palette.red.withValues(alpha: 0.35)
                            : scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mais lento',
                  iconSize: 30,
                  onPressed: m.rate > cprMinRate
                      ? () => m.rate = m.rate - cprRateStep
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: FitText(
                    '${m.rate} /min',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mais rápido',
                  iconSize: 30,
                  onPressed: m.rate < cprMaxRate
                      ? () => m.rate = m.rate + cprRateStep
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton.filled(
                  tooltip: m.running
                      ? 'Parar o metrónomo'
                      : 'Iniciar o metrónomo',
                  iconSize: 30,
                  onPressed: m.toggle,
                  icon: Icon(m.running ? Icons.stop : Icons.play_arrow),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
