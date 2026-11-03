import 'package:flutter/material.dart';

import '../app.dart';
import '../scores/model.dart';
import 'score_page.dart';
import 'widgets.dart';

class ScoreListPage extends StatelessWidget {
  const ScoreListPage({super.key, required this.title, required this.scores});

  final String title;
  final List<ScoreDefinition> scores;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).scores;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final anyAnswered = scores.any((s) => store.hasAnswers(s.id));
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                tooltip: 'Limpar todas',
                icon: const Icon(Icons.restart_alt),
                onPressed: !anyAnswered
                    ? null
                    : () async {
                        if (await confirm(
                          context,
                          title: 'Limpar escalas?',
                          message: 'Apaga as respostas de todas as escalas desta lista.',
                        )) {
                          for (final s in scores) {
                            store.reset(s.id);
                          }
                        }
                      },
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: scores.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final score = scores[i];
              final result = store.resultFor(score.id);
              final theme = Theme.of(context);
              return Card(
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ScorePage(score: score),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                score.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                result.complete
                                    ? result.label
                                    : result.answered > 0
                                    ? 'Faltam ${result.total - result.answered} de ${result.total}'
                                    : score.fullName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: result.complete
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ResultPill(result),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
