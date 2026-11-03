import 'package:flutter/material.dart';

import '../app.dart';
import '../scores/model.dart';
import '../scores/score_store.dart';
import '../theme.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                score.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              for (final dep in score.dependsOn)
                _LinkedScoreCard(allScores[dep]!),
              for (final item in score.visibleItems(answers))
                _ItemSection(
                  item: item,
                  picks: answers.of(item.id),
                  onTap: (i) => store.toggle(score.id, item, i),
                ),
            ],
          ),
          bottomNavigationBar: _ResultBar(result),
        );
      },
    );
  }
}

class _ItemSection extends StatelessWidget {
  const _ItemSection({
    required this.item,
    required this.picks,
    required this.onTap,
  });

  final ScoreItem item;
  final Set<int> picks;
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
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.multi)
                Text('Várias opções', style: theme.textTheme.labelSmall)
              else if (picks.isNotEmpty)
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final width = compact
                ? (constraints.maxWidth - gap) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (i, option) in item.options.indexed)
                  SizedBox(
                    width: width,
                    child: _OptionTile(
                      option: option,
                      selected: picks.contains(i),
                      // Items like "lado do défice" carry no points; don't show "0".
                      showPoints:
                          !item.multi && item.options.any((o) => o.points != 0),
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            );
          },
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
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    final points = option.points > 0 ? '+${option.points}' : '${option.points}';
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: fg,
                          ),
                        ),
                        if (option.detail != null)
                          Text(
                            option.detail!,
                            style: TextStyle(
                              fontSize: 13,
                              color: fg.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
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
            ),
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
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          title: Text(
            score.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            result.complete
                ? 'Incluída no total'
                : 'Por preencher — toque para avaliar',
          ),
          trailing: ResultPill(result),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => ScorePage(score: score)),
          ),
        ),
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
