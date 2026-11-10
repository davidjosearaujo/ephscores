import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../format.dart';
import '../obstetrics/obstetrics.dart';
import '../platform/android.dart';
import '../scores/model.dart';
import '../scores/pediatric.dart' as pediatric show apgar;
import '../theme.dart';
import '../vitals/vitals.dart';
import 'score_page.dart' show ScoreItemSection;
import 'widgets.dart';

/// The pregnant patient: gestational age, what the pregnancy health
/// booklet says, automatic reminders, and the birth with the newborn's
/// APGAR and the mother after the placenta. The screen stays on while it is
/// open, since hands are busy.
class ObstetricsPage extends StatefulWidget {
  const ObstetricsPage({super.key});

  @override
  State<ObstetricsPage> createState() => _ObstetricsPageState();
}

class _ObstetricsPageState extends State<ObstetricsPage> {
  @override
  void initState() {
    super.initState();
    keepScreenOn(true);
  }

  @override
  void dispose() {
    keepScreenOn(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final patient = scope.patient;
    return ListenableBuilder(
      listenable: scope.patientState,
      builder: (context, _) {
        final p = patient.pregnancy;
        void update(Pregnancy Function(Pregnancy p) f) =>
            patient.pregnancy = f(patient.pregnancy!);
        final vitals = scope.scores.vitals;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Grávida e parto'),
            actions: [
              if (p != null)
                IconButton(
                  tooltip: 'Apagar dados da gravidez',
                  icon: const Icon(Icons.restart_alt),
                  onPressed: () async {
                    if (await confirm(
                      context,
                      title: 'Apagar dados da gravidez?',
                      message:
                          'Apaga a idade gestacional, o parto e os APGAR '
                          'registados.',
                    )) {
                      patient.pregnancy = null;
                    }
                  },
                ),
            ],
          ),
          body: ListView(
            padding: listPadding,
            children: p == null
                ? [const SizedBox(height: 8), const _Start()]
                : [
                    _GestationCard(pregnancy: p, update: update),
                    for (final (severity, text) in pregnancyAlerts(p, vitals))
                      FlagNote(severity: severity, text: text),
                    ..._pregnancy(p, update),
                    _BirthSection(pregnancy: p, update: update, vitals: vitals),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
                      child: Text(
                        'Fonte: $obstetricsSource',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
          ),
        );
      },
    );
  }
}

/// Changes the pregnancy.
typedef _Update = void Function(Pregnancy Function(Pregnancy p) change);

Widget _column(List<Widget> children) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);

List<Widget> _pregnancy(Pregnancy p, _Update update) => [
  const SectionLabel('Gravidez'),
  _Counter(
    label: 'Gesta',
    detail: 'Gravidezes, incluindo a atual',
    value: p.gesta,
    min: 1,
    onChanged: (v) => update((p) => p.copyWith(gesta: () => v)),
  ),
  const SizedBox(height: 8),
  _Counter(
    label: 'Para',
    detail: 'Partos de fetos viáveis (≥ 24 semanas)',
    value: p.para,
    min: 0,
    onChanged: (v) => update((p) => p.copyWith(para: () => v)),
  ),
  const ItemHeader(title: 'Gestação'),
  _Choice(
    options: const ['Simples', 'Gemelar'],
    selected: p.twins ? 1 : 0,
    onTap: (i) => update((p) => p.copyWith(twins: i == 1)),
  ),
  const ItemHeader(title: 'Apresentação'),
  _Choice(
    options: [for (final v in Presentation.values) v.label],
    selected: p.presentation?.index,
    onTap: (i) => update(
      (p) => p.copyWith(
        presentation: () =>
            p.presentation?.index == i ? null : Presentation.values[i],
      ),
    ),
  ),
  const SizedBox(height: 12),
  CheckTile(
    label: 'Boletim de Saúde da Grávida',
    detail: 'Acompanha a grávida e é entregue na maternidade',
    selected: p.booklet,
    onTap: () => update((p) => p.copyWith(booklet: !p.booklet)),
  ),
  const ItemHeader(title: 'Bolsa de águas'),
  TimeStampTile(
    label: 'Rotura de membranas',
    at: p.watersAt,
    onChanged: (at) => update(
      (p) =>
          p.copyWith(watersAt: () => at, fluid: at == null ? const {} : null),
    ),
  ),
  if (p.watersAt != null)
    for (final f in FluidSign.values)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: CheckTile(
          label: f.label,
          selected: p.fluid.contains(f),
          onTap: () => update((p) => p.copyWith(fluid: _toggled(p.fluid, f))),
        ),
      ),
  const ItemHeader(
    title: 'Sinais de gravidade',
    subtitle: 'Com hipertensão, a partir das 20 semanas',
  ),
  for (final (i, s) in SevereSign.values.indexed)
    Padding(
      padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
      child: CheckTile(
        label: s.label,
        detail: s.detail,
        selected: p.severe.contains(s),
        onTap: () => update((p) => p.copyWith(severe: _toggled(p.severe, s))),
      ),
    ),
];

/// The birth: times, the newborn's APGAR and the mother after the
/// placenta. Ticks every second for the countdowns during the first hour,
/// vibrating when an APGAR comes due.
class _BirthSection extends StatefulWidget {
  const _BirthSection({
    required this.pregnancy,
    required this.update,
    required this.vitals,
  });

  final Pregnancy pregnancy;
  final _Update update;
  final VitalSigns vitals;

  @override
  State<_BirthSection> createState() => _BirthSectionState();
}

class _BirthSectionState extends State<_BirthSection> {
  late final Timer _timer;

  /// APGAR minutes already announced with a vibration.
  final _announced = <int>{};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _tick() {
    final birth = widget.pregnancy.birth;
    if (birth == null) return;
    final age = DateTime.now().difference(birth.bornAt);
    if (age > const Duration(hours: 1)) return;
    setState(() {});
    for (final minute in apgarMinutes) {
      if (age >= Duration(minutes: minute) &&
          birth.apgarAt(minute) == null &&
          _announced.add(minute)) {
        HapticFeedback.heavyImpact();
        showToast(context, 'APGAR ao $minute.º minuto');
      }
    }
  }

  Future<void> _scoreApgar(int minute) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ApgarSheet(minute: minute),
  );

  @override
  Widget build(BuildContext context) {
    final p = widget.pregnancy;
    final update = widget.update;
    final vitals = widget.vitals;
    final birth = p.birth;
    void set(Birth Function(Birth b) f) =>
        update((p) => p.copyWith(birth: () => f(p.birth!)));
    if (birth == null) {
      return _column([
        const SectionLabel('Parto'),
        TimeStampTile(
          label: 'Nascimento',
          detail: 'Registar a hora do nascimento',
          at: null,
          onChanged: (at) =>
              update((p) => p.copyWith(birth: () => Birth(bornAt: at!))),
        ),
      ]);
    }
    final now = DateTime.now();
    final age = now.difference(birth.bornAt);
    final shock = vitals.shockResult;
    return _column([
      const SectionLabel('Parto'),
      TimeStampTile(
        label: 'Nascimento',
        detail: age < const Duration(hours: 1)
            ? 'Há ${formatTimer(age)}'
            : null,
        at: birth.bornAt,
        onChanged: (at) async {
          if (at != null) return set((b) => b.copyWith(bornAt: at));
          if (await confirm(
            context,
            title: 'Apagar o parto?',
            message: 'Apaga as horas do parto e os APGAR registados.',
            action: 'Apagar',
          )) {
            update((p) => p.copyWith(birth: () => null));
          }
        },
      ),
      if ((p.weeks ?? 40) < 32)
        const FlagNote(
          severity: Severity.incomplete,
          text:
              'Menos de 32 semanas: envolver tronco, abdómen e membros '
              'num plástico, sem secar',
        ),
      const SizedBox(height: 8),
      TimeStampTile(
        label: 'Clampagem do cordão',
        detail: birth.clampedAt != null
            ? null
            : age < const Duration(minutes: 1)
            ? 'Se chorar vigorosamente, aguardar cerca de 1 min '
                  '(faltam ${formatTimer(const Duration(minutes: 1) - age)})'
            : 'Se chorar vigorosamente, cerca de 1 min após o nascimento',
        at: birth.clampedAt,
        onChanged: (at) => set((b) => b.copyWith(clampedAt: () => at)),
      ),
      const ItemHeader(title: 'Recém-nascido'),
      for (final (i, minute) in apgarMinutes.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
          child: _ApgarTile(
            minute: minute,
            result: birth.apgarAt(minute),
            due: birth.bornAt.add(Duration(minutes: minute)),
            now: now,
            onTap: () => _scoreApgar(minute),
          ),
        ),
      const ItemHeader(title: 'Dequitadura'),
      TimeStampTile(
        label: 'Saída da placenta',
        detail: birth.placentaAt == null
            ? 'Não aguardar para iniciar o transporte; pode demorar até '
                  '30 min'
            : null,
        at: birth.placentaAt,
        onChanged: (at) => set((b) => b.copyWith(placentaAt: () => at)),
      ),
      if (birth.placentaAt != null) ...[
        const ItemHeader(
          title: 'Útero contraído?',
          subtitle:
              'Globo de segurança de Pinard: duro, ao nível ou abaixo do '
              'umbigo',
        ),
        _Choice(
          options: const ['Sim', 'Não'],
          selected: switch (birth.uterusFirm) {
            true => 0,
            false => 1,
            null => null,
          },
          onTap: (i) => set(
            (b) => b.copyWith(
              uterusFirm: () => b.uterusFirm == (i == 0) ? null : i == 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CheckTile(
          label: 'Perda hemática abundante',
          selected: birth.heavyBleeding,
          onTap: () => set((b) => b.copyWith(heavyBleeding: !b.heavyBleeding)),
        ),
        if (birth.haemorrhage(vitals)) ...[
          FlagNote(
            severity: Severity.danger,
            top: 12,
            text: [
              'Suspeita de hemorragia pós-parto',
              if (shock != null && shock.severity.isAlert)
                'Índice de choque ${shock.display}',
            ].join(' · '),
          ),
          const FlagNote(
            severity: Severity.danger,
            text:
                'Massajar o útero até contrair · Trendelenburg · O₂ a '
                '15 L/min · Passar dados ao CODU',
          ),
        ] else
          const FlagNote(
            severity: Severity.incomplete,
            top: 12,
            text: 'Vigiar as perdas hemáticas no penso higiénico',
          ),
      ],
    ]);
  }
}

Set<T> _toggled<T>(Set<T> set, T value) =>
    set.contains(value) ? ({...set}..remove(value)) : {...set, value};

/// No pregnancy registered yet.
class _Start extends StatelessWidget {
  const _Start();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Idade gestacional, dados do Boletim de Saúde da Grávida, alertas '
          'automáticos a partir dos sinais vitais, e o parto com o APGAR do '
          'recém-nascido.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () =>
              AppScope.of(context).patient.pregnancy = const Pregnancy(),
          icon: const Icon(Icons.pregnant_woman),
          label: const Text('Doente grávida'),
        ),
      ],
    );
  }
}

/// Gestational age: typed in weeks, or worked out from the last period.
class _GestationCard extends StatelessWidget {
  const _GestationCard({required this.pregnancy, required this.update});

  final Pregnancy pregnancy;
  final _Update update;

  Future<void> _weeks(BuildContext context) async {
    final weeks = await showDialog<int>(
      context: context,
      builder: (_) => _WeeksDialog(initial: pregnancy.weeks),
    );
    if (weeks != null) {
      update((p) => p.copyWith(weeks: () => weeks, days: () => null));
    }
  }

  Future<void> _lastPeriod(BuildContext context) async {
    final today = DateTime.now();
    final lmp = await showDatePicker(
      context: context,
      helpText: 'Primeiro dia da última menstruação',
      firstDate: today.subtract(const Duration(days: 45 * 7)),
      lastDate: today,
      initialDate: today.subtract(
        Duration(days: (pregnancy.weeks ?? 30) * 7 + (pregnancy.days ?? 0)),
      ),
    );
    if (lmp == null) return;
    final age = Pregnancy.fromLastPeriod(lmp, today);
    update((p) => p.copyWith(weeks: () => age.weeks, days: () => age.days));
  }

  @override
  Widget build(BuildContext context) {
    final label = pregnancy.gestationLabel;
    return HeroCard(
      title: 'Idade gestacional',
      fill: true,
      children: [
        Text(
          label ?? 'Não registada',
          style: label == null
              ? null
              : Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (pregnancy.term case final term?) Text(term.label),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _weeks(context),
                child: const FitText('Semanas'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => _lastPeriod(context),
                child: const FitText('Última menstruação'),
              ),
            ),
            if (label != null)
              IconButton(
                tooltip: 'Limpar idade gestacional',
                color: HeroCard.foreground(context),
                onPressed: () => update(
                  (p) => p.copyWith(weeks: () => null, days: () => null),
                ),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeeksDialog extends StatefulWidget {
  const _WeeksDialog({this.initial});

  final int? initial;

  @override
  State<_WeeksDialog> createState() => _WeeksDialogState();
}

class _WeeksDialogState extends State<_WeeksDialog> {
  late final _text = TextEditingController(text: '${widget.initial ?? ''}');

  int? get _weeks => switch (int.tryParse(_text.text.trim())) {
    final w? when w >= 1 && w <= 45 => w,
    _ => null,
  };

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _done() {
    if (_weeks case final w?) Navigator.pop(context, w);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Idade gestacional'),
      content: TextField(
        controller: _text,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(suffixText: 'semanas'),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _done(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _weeks == null ? null : _done,
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// A count with large − and + buttons, usable with gloves; − below the
/// minimum clears it.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.detail,
    required this.value,
    required this.min,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final int? value;
  final int min;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tile,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.tileBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: TileLabel(label, detail: detail, color: scheme.onSurface),
            ),
            IconButton.outlined(
              tooltip: 'Menos',
              onPressed: value == null
                  ? null
                  : () => onChanged(value > min ? value - 1 : null),
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 40,
              child: Text(
                value == null ? '–' : '$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: value == null ? scheme.outline : scheme.onSurface,
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Mais',
              onPressed: () => onChanged(value == null ? min : value + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

/// Options side by side; tap the selected one again to clear where that
/// makes sense (the caller decides).
class _Choice extends StatelessWidget {
  const _Choice({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  final List<String> options;
  final int? selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, label) in options.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: SelectableTile(
              selected: selected == i,
              onTap: () => onTap(i),
              builder: (fg) => Center(child: TileLabel(label, color: fg)),
            ),
          ),
        ],
      ],
    );
  }
}

/// The APGAR at one minute: when it is due, then its result.
class _ApgarTile extends StatelessWidget {
  const _ApgarTile({
    required this.minute,
    required this.result,
    required this.due,
    required this.now,
    required this.onTap,
  });

  final int minute;
  final ScoreResult? result;
  final DateTime due;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    final left = due.difference(now);
    final pending = result == null || !result.complete;
    final detail = !pending
        ? result.label
        : left > Duration.zero
        ? 'Às ${formatClock(due)} · faltam ${formatTimer(left)}'
        : 'Avaliar agora';
    // Due and not scored: stands out in amber.
    final overdue = pending && left <= Duration.zero;
    return SelectableTile(
      selected: !pending,
      color: overdue ? Palette.amber : null,
      onTap: onTap,
      builder: (fg) => Row(
        children: [
          Expanded(
            child: TileLabel(
              'APGAR ao $minute.º minuto',
              detail: detail,
              color: overdue ? Palette.black : fg,
            ),
          ),
          if (result != null)
            ResultPill(result, compact: true)
          else
            Icon(Icons.chevron_right, color: overdue ? Palette.black : fg),
        ],
      ),
    );
  }
}

/// Scores the newborn's APGAR at [minute], saved as it is answered.
class _ApgarSheet extends StatelessWidget {
  const _ApgarSheet({required this.minute});

  final int minute;

  @override
  Widget build(BuildContext context) {
    final patient = AppScope.of(context).patient;
    return ListenableBuilder(
      listenable: patient,
      builder: (context, _) {
        final birth = patient.pregnancy?.birth;
        if (birth == null) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final picks = birth.apgar[minute] ?? const <String, int>{};
        final result = apgarResult(picks);
        void pick(String item, int option) {
          final updated = {...picks};
          if (updated[item] == option) {
            updated.remove(item);
          } else {
            updated[item] = option;
          }
          patient.pregnancy = patient.pregnancy!.copyWith(
            birth: () =>
                birth.copyWith(apgar: {...birth.apgar, minute: updated}),
          );
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 1,
          builder: (context, controller) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stays put while the questions scroll.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APGAR ao $minute.º minuto',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Às ${formatClock(birth.bornAt.add(Duration(minutes: minute)))}'
                      ' · nascimento às ${formatClock(birth.bornAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    for (final item in pediatric.apgar.items)
                      ScoreItemSection(
                        item: item,
                        picks: {?picks[item.id]},
                        onTap: (i) => pick(item.id, i),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      ResultPill(result),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result.complete
                              ? result.label
                              : '${result.answered} de ${result.total}',
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
