import 'package:flutter/material.dart';

import '../app.dart';
import '../burn/burn.dart';
import '../format.dart';
import '../theme.dart';
import 'body_diagram.dart';
import 'widgets.dart';

Color degreeColor(BurnDegree d, ColorScheme scheme) => switch (d) {
  BurnDegree.none =>
    scheme.brightness == Brightness.dark
        ? scheme.surfaceContainerHighest
        : Color.alphaBlend(
            Palette.navy.withValues(alpha: 0.22),
            scheme.surface,
          ),
  BurnDegree.first => Palette.amber,
  BurnDegree.second => Palette.orange,
  BurnDegree.third => Palette.red,
};

class BurnPage extends StatefulWidget {
  const BurnPage({super.key});

  @override
  State<BurnPage> createState() => _BurnPageState();
}

class _BurnPageState extends State<BurnPage> {
  BurnDegree _brush = BurnDegree.second;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).burn;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final affected = store.regions
            .where((r) => store.degreeOf(r) != BurnDegree.none)
            .toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Avaliação do queimado'),
            actions: [
              IconButton(
                tooltip: 'Limpar',
                icon: const Icon(Icons.restart_alt),
                onPressed: affected.isEmpty ? null : store.clear,
              ),
            ],
          ),
          body: ListView(
            padding: listPadding,
            children: [
              PatientTypeSelector(
                selected: store.patient,
                onChanged: (p) => store.patient = p,
              ),
              const SizedBox(height: 16),
              _TbsaCard(store: store),
              const SizedBox(height: 16),
              _BrushPicker(
                selected: _brush,
                onChanged: (d) => setState(() => _brush = d),
              ),
              const SizedBox(height: 16),
              BodyPair(
                patient: store.patient,
                regions: store.regions,
                colorFor: (r) => degreeColor(store.degreeOf(r), scheme),
                onTap: (r) => store.paint(r, _brush),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque numa região para aplicar o grau selecionado. '
                'Toque de novo para remover.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (affected.isNotEmpty) ...[
                const SectionLabel('Regiões afetadas'),
                Card(
                  child: Column(
                    children: [
                      for (final r in affected)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 8,
                            backgroundColor: degreeColor(
                              store.degreeOf(r),
                              scheme,
                            ),
                          ),
                          title: Text(r.label),
                          subtitle: Text(
                            '${r.view == BodyView.front ? 'Anterior' : 'Posterior'} · ${store.degreeOf(r).label}',
                          ),
                          trailing: Text(formatPercent(r.percent)),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TbsaCard extends StatelessWidget {
  const _TbsaCard({required this.store});

  final BurnStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String pct(BurnDegree d) =>
        formatPercent(store.percentWhere((x) => x == d));
    return Card(
      color: theme.colorScheme.primaryContainer,
      shape: filledCardShape,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Superfície corporal queimada',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2.º grau ${pct(BurnDegree.second)} · 3.º grau ${pct(BurnDegree.third)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '1.º grau ${pct(BurnDegree.first)} (não contabiliza)',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              formatPercent(store.tbsa),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrushPicker extends StatelessWidget {
  const _BrushPicker({required this.selected, required this.onChanged});

  final BurnDegree selected;
  final ValueChanged<BurnDegree> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final d in [
          BurnDegree.first,
          BurnDegree.second,
          BurnDegree.third,
          BurnDegree.none,
        ]) ...[
          if (d != BurnDegree.first) const SizedBox(width: 8),
          Expanded(
            child: _BrushChip(
              label: d == BurnDegree.none ? 'Apagar' : d.label,
              color: d == BurnDegree.none ? null : degreeColor(d, scheme),
              selected: selected == d,
              onTap: () => onChanged(d),
            ),
          ),
        ],
      ],
    );
  }
}

class _BrushChip extends StatelessWidget {
  const _BrushChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectableTile(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 6),
      builder: (fg) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          color == null
              ? Icon(Icons.backspace_outlined, size: 18, color: fg)
              : Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
          const SizedBox(height: 4),
          FitText(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
