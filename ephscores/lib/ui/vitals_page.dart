import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../format.dart';
import '../scores/model.dart';
import '../scores/pediatric.dart';
import '../scores/score_store.dart';
import '../theme.dart';
import '../vitals/vitals.dart';
import 'pain_faces.dart';
import 'score_page.dart';
import 'widgets.dart';

/// Names of the scores filled from each vital ("NEWS2 · RTS"). Fixed, so
/// worked out once rather than on every rebuild.
final _usedBy = {
  for (final vital in Vital.values)
    vital: {
      for (final s in allScores.values)
        for (final item in s.items)
          if (item.vital?.vitals.contains(vital) ?? false) s.name,
    }.join(' · '),
};

String usedBy(Vital vital) => _usedBy[vital]!;

/// The vital signs, in the order of the national form. Each value is typed
/// once and fills every score that uses it.
class VitalsPage extends StatelessWidget {
  const VitalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).scores;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final v = store.vitals;
        Widget field(Vital vital, {String? hint, Widget? below}) => _VitalField(
          // Keyed so the text survives rebuilds, and resets with "Limpar".
          key: ValueKey(vital),
          vital: vital,
          value: v[vital],
          hint: hint,
          below: below,
          onChanged: (value) => store.setVital(vital, value),
        );
        final age = v[Vital.age];
        // Children: the normal range for the age, flagged when outside it.
        Widget? child(Vital vital) {
          final range = age == null ? null : childNormal(vital, age);
          if (range == null) return null;
          final value = v[vital];
          final flag = value == null ? null : childFlag(vital, value, age!);
          if (flag != null) return _Flag(severity: flag.$1, text: flag.$2);
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              'Normal ${childAgeLabel(age!)}: ${range.$1}–${range.$2} '
              '${vital.unit}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        final glucose = v[Vital.glucose];
        final flag = glucose == null ? null : glucoseFlag(glucose);
        final shock = v.shockResult;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sinais vitais'),
            actions: [
              IconButton(
                tooltip: 'Limpar sinais vitais',
                icon: const Icon(Icons.restart_alt),
                onPressed: v.isEmpty
                    ? null
                    : () async {
                        if (await confirm(
                          context,
                          title: 'Limpar sinais vitais?',
                          message:
                              'Apaga os valores registados. As avaliações já '
                              'registadas não são alteradas.',
                        )) {
                          store.clearVitals();
                        }
                      },
              ),
            ],
          ),
          body: ListView(
            padding: listPadding,
            children: [
              Text(
                'Registados uma vez, preenchem as escalas que os usam.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              field(
                Vital.age,
                hint:
                    'Menos de 16 anos: a NEWS2 não é preenchida e FR, FC e '
                    'PAS são comparadas com o normal para a idade.',
              ),
              _AvdsField(
                level: v[Vital.avds]?.toInt(),
                newConfusion: v.newConfusion,
                onLevel: (i) => store.setVital(Vital.avds, i),
                onConfusion: (c) => store.newConfusion = c,
              ),
              field(Vital.rr, below: child(Vital.rr)),
              field(Vital.spo2),
              field(Vital.o2, hint: '0 = ar ambiente.'),
              field(Vital.hr, below: child(Vital.hr)),
              field(Vital.sbp, below: child(Vital.sbp)),
              field(Vital.dbp),
              field(Vital.temp),
              field(
                Vital.pain,
                hint:
                    'Escala numérica a partir dos 6 anos, ou de faces a '
                    'partir dos 3. Abaixo dos 4 anos ou sem verbalizar: FLACC.',
                below: FocusTraversalGroup(
                  descendantsAreTraversable: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      PainFaces(
                        selected: v.painFaces ? v[Vital.pain]?.toInt() : null,
                        onTap: store.setPainFaces,
                      ),
                      _FlaccLink(store.resultFor(flacc.id)),
                    ],
                  ),
                ),
              ),
              field(
                Vital.glucose,
                below: flag == null
                    ? null
                    : _Flag(severity: flag.$1, text: flag.$2),
              ),
              if (shock != null) _ShockIndexCard(shock),
            ],
          ),
        );
      },
    );
  }
}

class _VitalField extends StatefulWidget {
  const _VitalField({
    super.key,
    required this.vital,
    required this.value,
    required this.onChanged,
    this.hint,
    this.below,
  });

  final Vital vital;
  final num? value;
  final ValueChanged<num?> onChanged;
  final String? hint;
  final Widget? below;

  @override
  State<_VitalField> createState() => _VitalFieldState();
}

class _VitalFieldState extends State<_VitalField> {
  late final _controller = TextEditingController(text: _text(widget.value));
  final _focus = FocusNode();

  static String _text(num? v) => v == null ? '' : formatNumber(v.toDouble());

  @override
  void initState() {
    super.initState();
    // On leaving the field: show the range error, or tidy a valid value
    // ("38.6" becomes "38,6").
    _focus.addListener(() {
      final v = widget.vital.parse(_controller.text);
      if (!_focus.hasFocus && v != null) _controller.text = _text(v);
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(_VitalField old) {
    super.didUpdateWidget(old);
    // Cleared or changed elsewhere ("Limpar"): show the stored value.
    if (widget.value != widget.vital.parse(_controller.text)) {
      _controller.text = _text(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vital = widget.vital;
    final text = _controller.text;
    final invalid =
        !_focus.hasFocus && text.trim().isNotEmpty && vital.parse(text) == null;
    final range =
        '${formatNumber(vital.min.toDouble())} a '
        '${formatNumber(vital.max.toDouble())}';
    final used = usedBy(vital);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ItemHeader(
          title: vital.label,
          subtitle: [
            ?widget.hint,
            if (used.isNotEmpty) 'Preenche: $used',
          ].join('\n'),
        ),
        TextField(
          controller: _controller,
          focusNode: _focus,
          keyboardType: TextInputType.numberWithOptions(
            decimal: vital.decimals,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(vital.decimals ? r'[0-9.,]' : r'[0-9]'),
            ),
          ],
          textInputAction: vital == Vital.values.last
              ? TextInputAction.done
              : TextInputAction.next,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            suffixText: vital.unit,
            hintText: range,
            errorText: invalid ? 'Valor de $range ${vital.unit}'.trim() : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.tile,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
          onChanged: (t) {
            widget.onChanged(vital.parse(t));
            setState(() {});
          },
        ),
        ?widget.below,
      ],
    );
  }
}

class _AvdsField extends StatelessWidget {
  const _AvdsField({
    required this.level,
    required this.newConfusion,
    required this.onLevel,
    required this.onConfusion,
  });

  final int? level;
  final bool newConfusion;
  final ValueChanged<int?> onLevel;
  final ValueChanged<bool> onConfusion;

  @override
  Widget build(BuildContext context) {
    // The keyboard's "next" goes from one number field to the next, so
    // the tiles stay out of the focus order.
    return FocusTraversalGroup(
      descendantsAreTraversable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ItemHeader(
            title: Vital.avds.label,
            subtitle: 'Preenche: ${usedBy(Vital.avds)} · Vias Verdes',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (i, (letter, name)) in avdsLevels.indexed)
                    SizedBox(
                      width: width,
                      child: SelectableTile(
                        selected: level == i,
                        onTap: () => onLevel(level == i ? null : i),
                        builder: (fg) => Row(
                          children: [
                            Text(
                              letter,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: fg,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(fontSize: 15, color: fg),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (level == 0) ...[
            const SizedBox(height: 8),
            SelectableTile(
              selected: newConfusion,
              onTap: () => onConfusion(!newConfusion),
              builder: (fg) => Row(
                children: [
                  Expanded(
                    child: TileLabel(
                      'Confusão recente',
                      detail: 'Na NEWS2 pontua como V, D ou S',
                      color: fg,
                    ),
                  ),
                  if (newConfusion) Icon(Icons.check, color: fg, size: 20),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens FLACC, the observational pain scale, from the pain field.
class _FlaccLink extends StatelessWidget {
  const _FlaccLink(this.result);

  final ScoreResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          title: const Text(
            'FLACC',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            result.complete
                ? result.label
                : 'Dor observada: < 4 anos ou sem verbalizar',
          ),
          trailing: ResultPill(result),
          onTap: () => pushPage(context, ScorePage(score: flacc)),
        ),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.severity, required this.text});

  final Severity severity;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Palette.severity(severity, scheme),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Palette.onSeverity(severity, scheme),
          ),
        ),
      ),
    );
  }
}

class _ShockIndexCard extends StatelessWidget {
  const _ShockIndexCard(this.result);

  final ScoreResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ResultCard(
        title: 'Índice de choque (FC/PAS)',
        subtitle: '${result.label} · adulto',
        result: result,
      ),
    );
  }
}
