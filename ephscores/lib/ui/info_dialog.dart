import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_info.dart';
import 'brand.dart';

/// Small grey "i" that opens [showAppInfo].
class InfoButton extends StatelessWidget {
  const InfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Informação',
      iconSize: 20,
      color: Theme.of(context).colorScheme.outline,
      onPressed: () => showAppInfo(context),
      icon: const Icon(Icons.info_outline),
    );
  }
}

Future<void> showAppInfo(BuildContext context) async {
  final info = await AppInfo.load();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => _InfoDialog(info),
  );
}

class _InfoDialog extends StatelessWidget {
  const _InfoDialog(this.info);

  final AppInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const AppLogo(size: 44),
          const SizedBox(width: 12),
          Expanded(child: Wordmark(style: theme.textTheme.titleLarge)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            _Field('Versão', info.fullVersion),
            _Field('Pacote', info.applicationId),
            _Field('Autor', info.developer, url: info.developerUrl),
            if (info.homepage != null)
              _Field('Website', info.homepage!, url: info.homepage),
            if (info.repository != null)
              _Field('Repositório', info.repository!, url: info.repository),
            const SizedBox(height: 16),
            Text(
              'Auxiliar de cálculo. Não substitui a avaliação clínica nem '
              'os protocolos em vigor.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: info.name,
            applicationVersion: info.fullVersion,
          ),
          child: const Text('Licenças'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.url});

  final String label;
  final String value;

  /// Makes [value] a link to this address.
  final String? url;

  bool get link => url != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      value,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: link ? theme.colorScheme.primary : null,
        decoration: link ? TextDecoration.underline : null,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          if (link)
            InkWell(
              onTap: () => launchUrl(
                Uri.parse(url!),
                mode: LaunchMode.externalApplication,
              ),
              child: text,
            )
          else
            SelectableText(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
