import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../burn/burn.dart';
import '../platform/install_hint.dart';
import '../scores/adult.dart';
import '../scores/model.dart';
import '../scores/pediatric.dart';
import '../theme.dart';
import 'burn_page.dart';
import 'contacts_page.dart';
import 'score_list_page.dart';
import 'start_page.dart';
import 'widgets.dart';

const _installHintKey = 'installHintDismissed.v2';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showInstallHint = false;

  @override
  void initState() {
    super.initState();
    if (shouldSuggestInstall) {
      SharedPreferences.getInstance().then((prefs) {
        if (mounted && !(prefs.getBool(_installHintKey) ?? false)) {
          setState(() => _showInstallHint = true);
        }
      });
    }
  }

  Future<void> _dismissInstallHint() async {
    setState(() => _showInstallHint = false);
    (await SharedPreferences.getInstance()).setBool(_installHintKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    void open(Widget page) => pushPage(context, page);

    String? inProgress(List<ScoreDefinition> scores) {
      final n = scores.where((s) => scope.scores.hasAnswers(s.id)).length;
      return n == 0 ? null : '$n em curso';
    }

    return AnnotatedRegion(
      // Light status bar icons over the navy header.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListenableBuilder(
          listenable: Listenable.merge([scope.scores, scope.start, scope.burn]),
          builder: (context, _) {
            final entries = [
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
            ];
            return CustomScrollView(
              slivers: [
                // Fills the screen when everything fits; scrolls otherwise.
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(scope: scope),
                      if (_showInstallHint)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _InstallHint(onDismiss: _dismissInstallHint),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                      SafeArea(
                        top: false,
                        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: const _Footer(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scope});

  final AppScope scope;

  Future<void> _newPatient(BuildContext context) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPatient = !scope.scores.isEmpty || !scope.burn.isEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: Palette.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 24),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/EPHScores_logo.png'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EPHScores',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Escalas de emergência\npré-hospitalar',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPatient)
                _HeaderAction(
                  icon: Icons.person_add_alt,
                  label: 'Novo doente',
                  onTap: () => _newPatient(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact white-on-navy button for the header.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.outline,
        textStyle: theme.textTheme.bodySmall,
      ),
      onPressed: () => showLicensePage(
        context: context,
        applicationName: 'EPHScores',
        applicationLegalese:
            'Auxiliar de cálculo. Não substitui a avaliação clínica '
            'nem os protocolos em vigor.',
      ),
      icon: const Icon(Icons.wifi_off, size: 14),
      label: const Text('Funciona sem rede. Nenhum dado sai do dispositivo.'),
    );
  }
}

class _InstallHint extends StatelessWidget {
  const _InstallHint({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSecondaryContainer;
    return Card(
      color: theme.colorScheme.secondaryContainer,
      shape: filledCardShape,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Icon(Icons.ios_share, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Instale no iPhone: ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: 'toque em Partilhar e depois em '),
                    TextSpan(
                      text: '"Adicionar ao ecrã principal"',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          '. Abra-a uma vez com rede para ficar disponível '
                          'sem rede.',
                    ),
                  ],
                ),
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              ),
            ),
            IconButton(
              tooltip: 'Fechar',
              color: fg,
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
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
