import 'package:flutter/material.dart';

import '../app.dart';
import '../format.dart';
import '../history/history.dart';
import '../history/unlock.dart';
import '../patient/summary.dart';
import '../theme.dart';
import 'evolution_page.dart';
import 'widgets.dart';

/// Finished patients kept on the device, behind the phone's screen lock.
/// It locks again whenever the app goes to the background, closing any
/// patient opened from it.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

enum _Lock { unlocking, unlocked, locked, noLock }

class _HistoryPageState extends State<HistoryPage> {
  _Lock _lock = _Lock.unlocking;
  List<HistoryEntry>? _entries;
  late final AppLifecycleListener _lifecycle;
  late final HistoryStore _history;

  /// The patient opened from the list, if any.
  Route<void>? _opened;

  void _open(HistoryEntry e) {
    final route = MaterialPageRoute<void>(
      builder: (_) => EvolutionPage(entry: e),
    );
    _opened = route;
    Navigator.of(context).push(route);
  }

  @override
  void initState() {
    super.initState();
    _history = AppScope.of(context).history..addListener(_load);
    _lifecycle = AppLifecycleListener(onHide: _relock);
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    _history.removeListener(_load);
    _lifecycle.dispose();
    super.dispose();
  }

  void _relock() {
    if (_lock == _Lock.unlocked) {
      // Close a patient opened from here at once: frames stop while the app
      // is in the background, so an animated pop would leave it on screen
      // until the app came back.
      final opened = _opened;
      if (opened != null && opened.isActive) {
        Navigator.of(context).removeRoute(opened);
      }
      _opened = null;
      setState(() {
        _lock = _Lock.locked;
        _entries = null;
      });
    }
  }

  Future<void> _unlock() async {
    setState(() => _lock = _Lock.unlocking);
    final result = await AppScope.of(context).unlocker.unlock();
    if (!mounted) return;
    setState(
      () => _lock = switch (result) {
        UnlockResult.ok => _Lock.unlocked,
        UnlockResult.failed => _Lock.locked,
        UnlockResult.noLock => _Lock.noLock,
      },
    );
    if (_lock == _Lock.unlocked) {
      await _history.purge();
      await _load();
    }
  }

  Future<void> _load() async {
    if (_lock != _Lock.unlocked) return;
    final entries = await _history.entries();
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _deleteAll() async {
    if (await confirmDelete(
      context,
      title: 'Apagar todo o histórico?',
      message: 'Apaga todos os doentes guardados neste dispositivo.',
    )) {
      await _history.deleteAll();
    }
  }

  Future<void> _delete(HistoryEntry e) async {
    if (await confirmDelete(
      context,
      title: 'Apagar doente de ${formatDate(e.startedAt)}?',
      message: 'Apaga o resumo e todas as avaliações deste doente.',
    )) {
      await _history.delete(e.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          if (entries != null && entries.isNotEmpty)
            IconButton(
              tooltip: 'Apagar todo o histórico',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _deleteAll,
            ),
        ],
      ),
      body: switch (_lock) {
        _Lock.unlocked when entries != null => _List(
          entries: entries,
          onOpen: _open,
          onDelete: _delete,
        ),
        _Lock.unlocked ||
        _Lock.unlocking => const Center(child: CircularProgressIndicator()),
        _Lock.locked => _Locked(
          icon: Icons.lock_outline,
          text: 'O histórico está bloqueado.',
          action: 'Desbloquear',
          onPressed: _unlock,
        ),
        _Lock.noLock => const _Locked(
          icon: Icons.no_encryption_outlined,
          text:
              'Para proteger os dados dos doentes, o histórico só abre com '
              'o bloqueio de ecrã do telemóvel. Defina um PIN, padrão, '
              'palavra-passe ou impressão digital nas definições.',
        ),
      },
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({
    required this.icon,
    required this.text,
    this.action,
    this.onPressed,
  });

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.fingerprint),
                label: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.entries,
    required this.onOpen,
    required this.onDelete,
  });

  final List<HistoryEntry> entries;
  final ValueChanged<HistoryEntry> onOpen;
  final ValueChanged<HistoryEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // One heading per day, newest first.
    final byDay = <Widget>[];
    String? day;
    for (final e in entries) {
      final d = formatDate(e.startedAt);
      if (d != day) byDay.add(SectionLabel(day = d));
      byDay.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _EntryCard(
            entry: e,
            onOpen: () => onOpen(e),
            onDelete: () => onDelete(e),
          ),
        ),
      );
    }
    return ListView(
      padding: listPadding,
      children: [
        Card(
          color: theme.colorScheme.secondaryContainer,
          shape: filledCardShape,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Guardados só neste dispositivo, cifrados, e apagados '
                    '${historyRetention.inDays} dias depois de finalizados. '
                    'Mantenha premido um doente para o apagar.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('Sem doentes no histórico.')),
          ),
        ...byDay,
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onOpen,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = entry.patient;
    final n = p.evaluations.length;
    final pathways = [for (final (v, _) in viaVerdeStatus(p)) v.name];
    final last = p.evaluations.lastOrNull;
    final alerts = last == null ? const <String>[] : alterations(last);
    final age = last?.scores.vitals.summary().split(' · ').first;
    final details = [
      if (age != null && age.endsWith('anos')) age,
      if (pathways.isNotEmpty) 'Vias Verdes: ${pathways.join(', ')}',
      ...alerts.take(2),
    ];
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
        title: Text(
          '${formatClock(entry.startedAt)}–${formatClock(entry.finishedAt)}'
          ' · $n ${n == 1 ? 'avaliação' : 'avaliações'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: details.isEmpty ? null : Text(details.join('\n')),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        onTap: onOpen,
        onLongPress: onDelete,
      ),
    );
  }
}
