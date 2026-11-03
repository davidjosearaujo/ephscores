import 'package:flutter/material.dart';

import '../app.dart';
import '../scores/adult.dart';
import '../scores/model.dart';
import '../scores/pediatric.dart';
import '../theme.dart';
import 'burn_page.dart';
import 'contacts_page.dart';
import 'score_list_page.dart';
import 'start_page.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final theme = Theme.of(context);

    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

    String? inProgress(List<ScoreDefinition> scores) {
      final n = scores.where((s) => scope.scores.hasAnswers(s.id)).length;
      return n == 0 ? null : '$n em curso';
    }

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.scores, scope.start, scope.burn]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  Image.asset('assets/EPHScores_logo.png', height: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EPHScores',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Escalas de emergência pré-hospitalar',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _MenuCard(
                icon: Icons.person,
                title: 'Escalas gerais',
                subtitle: adultScores.map((s) => s.name).join(' · '),
                badge: inProgress(adultScores),
                onTap: () => open(
                  ScoreListPage(title: 'Escalas gerais', scores: adultScores),
                ),
              ),
              _MenuCard(
                icon: Icons.child_care,
                title: 'Escalas pediátricas',
                subtitle: pediatricScores.map((s) => s.name).join(' · '),
                badge: inProgress(pediatricScores),
                onTap: () => open(
                  ScoreListPage(
                    title: 'Escalas pediátricas',
                    scores: pediatricScores,
                  ),
                ),
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
                icon: Icons.groups,
                title: 'Triagem START',
                subtitle: 'Multivítimas · contagem por prioridade',
                badge: scope.start.total == 0
                    ? null
                    : '${scope.start.total} ${scope.start.total == 1 ? 'vítima' : 'vítimas'}',
                onTap: () => open(const StartPage()),
              ),
              _MenuCard(
                icon: Icons.phone,
                title: 'Contactos úteis',
                subtitle: 'Linhas de apoio e emergência',
                onTap: () => open(const ContactsPage()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: scope.scores.isEmpty && scope.burn.isEmpty
                    ? null
                    : () async {
                        if (await confirm(
                          context,
                          title: 'Novo doente?',
                          message:
                              'Apaga todas as escalas e a avaliação do queimado. '
                              'A contagem da triagem START mantém-se.',
                          action: 'Novo doente',
                        )) {
                          scope.scores.resetAll();
                          scope.burn.clearAll();
                        }
                      },
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Novo doente'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Funciona sem rede. Nenhum dado sai do dispositivo.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Palette.navy,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
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
