import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../format.dart';
import '../platform/install_hint.dart';
import '../theme.dart';
import 'contacts_page.dart';
import 'evolution_page.dart';
import 'info_dialog.dart';
import 'start_page.dart';
import 'widgets.dart';

const _installHintKey = 'installHintDismissed.v2';

/// Start screen: begins a new patient. START triage and contacts live here
/// too, since they aren't tied to a patient.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
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

  Future<void> _newPatient() async {
    final scope = AppScope.of(context);
    if (scope.patient.isFinished &&
        !await confirm(
          context,
          title: 'Novo doente?',
          message: 'O resumo do doente anterior será apagado.',
          action: 'Novo doente',
        )) {
      return;
    }
    scope.startPatient();
  }

  Future<void> _deleteLastPatient() async {
    final scope = AppScope.of(context);
    if (await confirmDelete(
      context,
      title: 'Apagar último doente?',
      message: 'Apaga o resumo e todas as avaliações deste doente.',
    )) {
      scope.discardPatient();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patient = AppScope.of(context).patient;
    // Rebuilds when the last patient is deleted.
    return ListenableBuilder(
      listenable: patient,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.topRight,
                        child: InfoButton(),
                      ),
                      if (_showInstallHint)
                        _InstallHint(onDismiss: _dismissInstallHint),
                      const Spacer(),
                      const Center(child: AppLogo(size: 152)),
                      const SizedBox(height: 24),
                      Text(
                        'EPHScores',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Escalas de emergência pré-hospitalar',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(64),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: _newPatient,
                        icon: const Icon(Icons.person_add_alt, size: 28),
                        label: const Text('Novo doente'),
                      ),
                      if (patient.isFinished) ...[
                        const SizedBox(height: 12),
                        _LastPatientCard(
                          onTap: () => pushPage(context, const EvolutionPage()),
                          onLongPress: _deleteLastPatient,
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _SecondaryButton(
                              icon: Icons.groups,
                              label: 'Triagem START',
                              onPressed: () =>
                                  pushPage(context, const StartPage()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SecondaryButton(
                              icon: Icons.phone,
                              label: 'Contactos',
                              onPressed: () =>
                                  pushPage(context, const ContactsPage()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: scheme.tile,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
    );
  }
}

/// Entry to the finished patient's summary, kept until the next patient.
class _LastPatientCard extends StatelessWidget {
  const _LastPatientCard({required this.onTap, required this.onLongPress});

  final VoidCallback onTap;

  /// Deletes the patient (after confirmation).
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patient = AppScope.of(context).patient;
    final n = patient.evaluations.length;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
        leading: const Icon(Icons.timeline),
        title: const Text(
          'Último doente',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${formatClock(patient.startedAt!)}–'
          '${formatClock(patient.finishedAt!)} · '
          '$n ${n == 1 ? 'avaliação' : 'avaliações'}\n'
          'Mantenha premido para apagar',
        ),
        isThreeLine: true,
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
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
