import 'package:flutter/material.dart';

import '../app.dart';
import '../scores/adult.dart' show race;
import '../scores/model.dart';
import '../scores/score_store.dart';
import '../theme.dart';
import '../vitals/vitals.dart';
import 'via_verde_page.dart';
import 'vitals_page.dart';
import 'widgets.dart';

/// Generic page that renders any [ScoreDefinition].
class ScorePage extends StatelessWidget {
  const ScorePage({super.key, required this.score});

  final ScoreDefinition score;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).scores;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final answers = store.answersFor(score.id);
        final result = store.resultFor(score.id);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score.name),
                Text(
                  score.fullName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Limpar escala',
                icon: const Icon(Icons.restart_alt),
                onPressed: store.hasAnswers(score.id)
                    ? () => store.reset(score.id)
                    : null,
              ),
            ],
          ),
          body: ListView(
            padding: listPadding,
            children: [
              Text(
                score.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              for (final dep in score.dependsOn)
                _LinkedScoreCard(allScores[dep]!),
              for (final item in score.visibleItems(answers))
                ScoreItemSection(
                  item: item,
                  picks: answers.of(item.id),
                  vitals: store.vitals,
                  fromVitals: store.fromVitals(score.id, item) != null,
                  onTap: (i) => store.fromVitals(score.id, item) != null
                      ? pushPage(context, const VitalsPage())
                      : _answer(context, store, score, item, i),
                ),
            ],
          ),
          bottomNavigationBar: _ResultBar(result),
        );
      },
    );
  }
}

/// Records an answer; when it brings RACE to 5 or more (suspected large
/// vessel occlusion), offers a shortcut to the Via Verde AVC.
void _answer(
  BuildContext context,
  ScoreStore store,
  ScoreDefinition score,
  ScoreItem item,
  int index,
) {
  bool lvo() {
    final r = store.resultFor(race.id);
    return r.complete && r.value! >= 5;
  }

  final before = score.id == race.id && lvo();
  store.toggle(score.id, item, index);
  if (score.id != race.id || before || !lvo()) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        backgroundColor: Palette.red,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        content: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RACE ≥ 5',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Oclusão de grande vaso?',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Palette.red,
                shape: const StadiumBorder(),
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                pushPage(context, const ViaVerdePage());
              },
              child: const Text('Via Verde AVC'),
            ),
          ],
        ),
      ),
    );
}

/// One question of a score and its options. Also used outside the score
/// page (the APGAR at each minute after birth).
class ScoreItemSection extends StatelessWidget {
  const ScoreItemSection({
    super.key,
    required this.item,
    required this.picks,
    required this.onTap,
    this.vitals,
    this.fromVitals = false,
  });

  final ScoreItem item;
  final Set<int> picks;

  /// For items answered from the vital signs.
  final VitalSigns? vitals;

  /// Answered by the vital signs: the options open them instead.
  final bool fromVitals;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Short labels fit two per row; long ones get the full width.
    final compact = item.options.every(
      (o) => o.label.length <= 14 && o.detail == null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ItemHeader(
          title: item.label,
          trailing: item.multi
              ? Text('Várias opções', style: theme.textTheme.labelSmall)
              : picks.isNotEmpty
              ? ItemHeader.done(context)
              : null,
        ),
        if (item.hint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              item.hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if ((item.vital, vitals) case (final binding?, final vitals?))
          _VitalsLink(binding: binding, vitals: vitals, used: fromVitals),
        TileGrid(
          columns: compact ? 2 : 1,
          children: [
            for (final (i, option) in item.options.indexed)
              _OptionTile(
                option: option,
                selected: picks.contains(i),
                // Items like "lado do défice" carry no points; don't show "0".
                showPoints:
                    !item.multi && item.options.any((o) => o.points != 0),
                onTap: () => onTap(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.showPoints,
    required this.onTap,
  });

  final ScoreOption option;
  final bool selected;
  final bool showPoints;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final points = option.points > 0 ? '+${option.points}' : '${option.points}';
    return SelectableTile(
      selected: selected,
      onTap: onTap,
      builder: (fg) => Row(
        children: [
          Expanded(
            child: TileLabel(option.label, detail: option.detail, color: fg),
          ),
          if (showPoints)
            Text(
              points,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: fg.withValues(alpha: selected ? 1 : 0.6),
              ),
            )
          else if (selected)
            Icon(Icons.check, color: fg, size: 20),
        ],
      ),
    );
  }
}

/// Where a vital-sign item gets its answer: the recorded value, or a link to
/// record it.
class _VitalsLink extends StatelessWidget {
  const _VitalsLink({
    required this.binding,
    required this.vitals,
    required this.used,
  });

  final VitalBinding binding;
  final VitalSigns vitals;
  final bool used;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = used
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final values = [
      for (final v in binding.vitals)
        if (vitals[v] != null) '${v.short} ${vitals.format(v)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => pushPage(context, const VitalsPage()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  used
                      ? 'Dos sinais vitais: $values'
                      : 'Ou registar nos sinais vitais',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: used ? FontWeight.w600 : null,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the result of a score this one depends on (e.g. GCS inside MGAP).
class _LinkedScoreCard extends StatelessWidget {
  const _LinkedScoreCard(this.score);

  final ScoreDefinition score;

  @override
  Widget build(BuildContext context) {
    final result = AppScope.of(context).scores.resultFor(score.id);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ResultCard(
        title: score.fullName,
        subtitle: result.complete
            ? 'Incluída no total'
            : 'Por preencher — toque para avaliar',
        result: result,
        onTap: () => pushPage(context, ScorePage(score: score)),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar(this.result);

  final ScoreResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = Palette.severity(result.severity, scheme);
    final fg = Palette.onSeverity(result.severity, scheme);
    final title = result.complete
        ? result.label
        : 'Faltam ${result.total - result.answered} de ${result.total}';
    final subtitle = result.complete ? result.breakdown : 'Total parcial';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                      ),
                  ],
                ),
              ),
              Text(
                result.display,
                style: TextStyle(
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
