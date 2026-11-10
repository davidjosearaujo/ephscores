import 'package:flutter/material.dart';

import '../app.dart';
import '../burn/burn.dart';
import '../injuries/injuries.dart';
import '../theme.dart';
import '../vitals/vitals.dart';
import 'body_diagram.dart';
import 'burn_page.dart' show degreeColor;
import 'widgets.dart';

Color levelColor(InjuryLevel level) => switch (level) {
  InjuryLevel.major => Palette.red,
  InjuryLevel.serious => Palette.orange,
  InjuryLevel.minor => Palette.amber,
};

/// What was found where on the body: tap a region and tick the types of
/// injury. Uses the same regions as the burn map.
class InjuriesPage extends StatefulWidget {
  const InjuriesPage({super.key});

  @override
  State<InjuriesPage> createState() => _InjuriesPageState();
}

class _InjuriesPageState extends State<InjuriesPage> {
  @override
  void initState() {
    super.initState();
    // A child's body, when the age says so and nothing is marked yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scope = AppScope.of(context);
      final age = scope.scores.vitals[Vital.age];
      if (scope.patient.injuries.isEmpty && age != null && age < 16) {
        scope.patient.injuries = scope.patient.injuries.withPatient(
          BurnPatient.child,
        );
      }
    });
  }

  Future<void> _edit(BodyRegion region) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _RegionSheet(region: region),
  );

  @override
  Widget build(BuildContext context) {
    final patient = AppScope.of(context).patient;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: patient,
      builder: (context, _) {
        final map = patient.injuries;
        final affected = map.affected;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mapa de lesões'),
            actions: [
              IconButton(
                tooltip: 'Limpar mapa de lesões',
                icon: const Icon(Icons.restart_alt),
                onPressed: map.isEmpty
                    ? null
                    : () async {
                        if (await confirm(
                          context,
                          title: 'Limpar mapa de lesões?',
                          message: 'Apaga todas as lesões marcadas.',
                        )) {
                          patient.injuries = InjuryMap(patient: map.patient);
                        }
                      },
              ),
            ],
          ),
          body: ListView(
            padding: listPadding,
            children: [
              PatientTypeSelector(
                selected: map.patient,
                onChanged: (p) => patient.injuries = map.withPatient(p),
              ),
              const SizedBox(height: 16),
              const _Legend(),
              const SizedBox(height: 16),
              BodyPair(
                patient: map.patient,
                regions: map.regions,
                colorFor: (r) => switch (map.levelOf(r)) {
                  final level? => levelColor(level),
                  null => degreeColor(BurnDegree.none, scheme),
                },
                labelFor: (r) {
                  final n = map.typesOf(r).length;
                  return n == 0 ? '' : '$n';
                },
                onTap: _edit,
              ),
              const SizedBox(height: 8),
              Text(
                'Toque numa região para marcar as lesões encontradas.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (affected.isNotEmpty) ...[
                const SectionLabel('Regiões com lesões'),
                Card(
                  child: Column(
                    children: [
                      for (final r in affected)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 8,
                            backgroundColor: levelColor(map.levelOf(r)!),
                          ),
                          title: Text(r.label),
                          subtitle: Text(
                            '${r.view == BodyView.front ? 'Anterior' : 'Posterior'}'
                            ' · ${[for (final t in InjuryType.values)
                              if (map.typesOf(r).contains(t)) t.label].join(', ')}',
                          ),
                          onTap: () => _edit(r),
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

/// What the colours mean.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    Widget dot(InjuryLevel level, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 6, backgroundColor: levelColor(level)),
        const SizedBox(width: 6),
        Text(text, style: style),
      ],
    );
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        dot(InjuryLevel.major, 'Hemorragia, penetrante, amputação'),
        dot(InjuryLevel.serious, 'Fratura, deformidade'),
        dot(InjuryLevel.minor, 'Ferida, contusão, dor'),
      ],
    );
  }
}

/// The injury types of one region, ticked as they are found.
class _RegionSheet extends StatelessWidget {
  const _RegionSheet({required this.region});

  final BodyRegion region;

  @override
  Widget build(BuildContext context) {
    final patient = AppScope.of(context).patient;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: patient,
      builder: (context, _) {
        final map = patient.injuries;
        final types = map.typesOf(region);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  region.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  region.view == BodyView.front ? 'Anterior' : 'Posterior',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TileGrid(
                  children: [
                    for (final t in InjuryType.values)
                      CheckTile(
                        label: t.label,
                        selected: types.contains(t),
                        onTap: () => patient.injuries = map.toggle(region, t),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: types.isEmpty
                            ? null
                            : () => patient.injuries = map.clearRegion(region),
                        child: const Text('Limpar região'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
