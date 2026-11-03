import 'package:flutter/material.dart';

import '../app.dart';
import '../start/start.dart';
import '../theme.dart';
import 'widgets.dart';

Color categoryColor(StartCategory c) => switch (c) {
  StartCategory.p1 => Palette.red,
  StartCategory.p2 => Palette.amber,
  StartCategory.p3 => Palette.green,
  StartCategory.p4 => Palette.black,
};

Color onCategoryColor(StartCategory c) =>
    c == StartCategory.p2 ? Palette.black : Colors.white;

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).start;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Triagem START' : 'Resumo da ocorrência'),
      ),
      body: _tab == 0 ? const _TriageFlow() : const _Summary(),
      bottomNavigationBar: ListenableBuilder(
        listenable: store,
        builder: (context, _) => NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.alt_route),
              label: 'Triagem',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: store.total > 0,
                label: Text('${store.total}'),
                child: const Icon(Icons.groups_outlined),
              ),
              selectedIcon: const Icon(Icons.groups),
              label: 'Resumo',
            ),
          ],
        ),
      ),
    );
  }
}

class _TriageFlow extends StatefulWidget {
  const _TriageFlow();

  @override
  State<_TriageFlow> createState() => _TriageFlowState();
}

class _TriageFlowState extends State<_TriageFlow> {
  final List<(StartQuestion, bool)> _answers = [];
  StartQuestion? _question = StartQuestion.walks;
  StartCategory? _result;

  void _answer(bool yes) {
    final step = startAnswer(_question!, yes);
    setState(() {
      _answers.add((_question!, yes));
      _question = step.next;
      _result = step.category;
    });
  }

  void _back() {
    if (_answers.isEmpty) return;
    setState(() {
      _question = _answers.removeLast().$1;
      _result = null;
    });
  }

  void _restart() => setState(() {
    _answers.clear();
    _question = StartQuestion.walks;
    _result = null;
  });

  void _record() {
    final category = _result!;
    AppScope.of(context).start.add(category);
    showToast(
      context,
      'Vítima registada como ${category.code} · ${category.label}',
    );
    _restart();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Path taken so far, so a wrong tap is easy to spot.
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (q, yes) in _answers)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${_short(q)}: ${yes ? 'Sim' : 'Não'}'),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _result != null
                  ? _ResultView(key: ValueKey(_result), category: _result!)
                  : _QuestionView(
                      key: ValueKey(_question),
                      question: _question!,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (_result == null)
            Row(
              children: [
                Expanded(
                  child: _BigButton(
                    label: 'Não',
                    onPressed: () => _answer(false),
                    filled: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BigButton(
                    label: 'Sim',
                    onPressed: () => _answer(true),
                  ),
                ),
              ],
            )
          else
            _BigButton(
              label: 'Registar vítima',
              icon: Icons.check,
              onPressed: _record,
            ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _answers.isEmpty ? null : _back,
                icon: const Icon(Icons.undo),
                label: const Text('Voltar'),
              ),
              TextButton.icon(
                onPressed: _answers.isEmpty ? null : _restart,
                icon: const Icon(Icons.restart_alt),
                label: Text(
                  _result == null ? 'Recomeçar' : 'Descartar',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _short(StartQuestion q) => switch (q) {
    StartQuestion.walks => 'Caminha',
    StartQuestion.breathes => 'Respira',
    StartQuestion.breathesAfterAirway => 'Após VA',
    StartQuestion.rrOver30 => 'FR > 30',
    StartQuestion.perfusion => 'PC > 2 s',
    StartQuestion.obeys => 'Cumpre ordens',
  };
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({super.key, required this.question});

  final StartQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(_icon(question), size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                question.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (question.hint != null) ...[
                const SizedBox(height: 12),
                Text(
                  question.hint!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _icon(StartQuestion q) => switch (q) {
    StartQuestion.walks => Icons.directions_walk,
    StartQuestion.breathes => Icons.air,
    StartQuestion.breathesAfterAirway => Icons.medical_services_outlined,
    StartQuestion.rrOver30 => Icons.speed,
    StartQuestion.perfusion => Icons.favorite_border,
    StartQuestion.obeys => Icons.record_voice_over_outlined,
  };
}

class _ResultView extends StatelessWidget {
  const _ResultView({super.key, required this.category});

  final StartCategory category;

  @override
  Widget build(BuildContext context) {
    final fg = onCategoryColor(category);
    return Card(
      color: categoryColor(category),
      shape: filledCardShape,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.code,
              style: TextStyle(
                fontSize: 96,
                height: 1,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            Text(
              category.colorName,
              style: TextStyle(fontSize: 18, color: fg.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const size = Size.fromHeight(72);
    const text = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 28), const SizedBox(width: 8)],
        Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
      ],
    );
    return filled
        ? FilledButton(
            style: FilledButton.styleFrom(minimumSize: size, textStyle: text),
            onPressed: onPressed,
            child: child,
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: size,
              textStyle: text,
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            onPressed: onPressed,
            child: child,
          );
  }
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).start;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final theme = Theme.of(context);
        final recent = store.records.reversed.take(30).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                for (final c in StartCategory.values) _CountTile(category: c),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Total de vítimas'),
                trailing: Text(
                  '${store.total}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (recent.isNotEmpty) ...[
              const SectionLabel('Registos recentes'),
              Card(
                child: Column(
                  children: [
                    for (final r in recent)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: categoryColor(r.category),
                          child: Text(
                            r.category.code.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: onCategoryColor(r.category),
                            ),
                          ),
                        ),
                        title: Text('${r.category.code} · ${r.category.label}'),
                        trailing: Text(_time(r.time)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: store.total == 0
                  ? null
                  : () async {
                      if (await confirm(
                        context,
                        title: 'Terminar ocorrência?',
                        message:
                            'Apaga a contagem de todas as vítimas triadas.',
                        action: 'Terminar',
                      )) {
                        store.clear();
                      }
                    },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Terminar ocorrência'),
            ),
          ],
        );
      },
    );
  }

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.category});

  final StartCategory category;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).start;
    final fg = onCategoryColor(category);
    final count = store.count(category);
    return Card(
      color: categoryColor(category),
      shape: filledCardShape,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              '${category.code} · ${category.label}',
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: fg,
                    fontSize: 56,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Remover ${category.code}',
                  color: fg,
                  onPressed: count == 0
                      ? null
                      : () => store.removeLast(category),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  tooltip: 'Adicionar ${category.code}',
                  color: fg,
                  onPressed: () => store.add(category),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
