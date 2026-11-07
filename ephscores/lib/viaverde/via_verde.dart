/// Via Verde (green pathway) criteria for the adult patient, as used in
/// Portuguese pre-hospital care. Each pathway is data: groups of criteria,
/// some met automatically from the vital signs, scores and burn map, the
/// rest ticked by hand, and a rule that turns them into a status.
library;

import '../burn/burn.dart';
import '../format.dart';
import '../scores/model.dart';
import '../scores/score_store.dart';
import '../vitals/vitals.dart';

/// When the symptoms began or, when that is unknown, when the patient was
/// last seen well (the reference INEM uses for the stroke pathway).
class Onset {
  const Onset(this.at, {this.lastSeenWell = false});

  factory Onset.fromJson(Map<String, dynamic> json) => Onset(
    DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
    lastSeenWell: json['seen'] == true,
  );

  final DateTime at;
  final bool lastSeenWell;

  String get label =>
      lastSeenWell ? 'Visto bem pela última vez' : 'Início dos sintomas';

  Map<String, Object> toJson() => {
    'at': at.millisecondsSinceEpoch,
    if (lastSeenWell) 'seen': true,
  };
}

/// What the criteria are checked against.
class ClinicalState {
  const ClinicalState({
    required this.scores,
    required this.burns,
    required this.now,
    this.onset,
    this.checks = const {},
  });

  final ScoreSheet scores;
  final BurnSheet burns;
  final Onset? onset;
  final DateTime now;

  /// Criteria ticked by hand, as "pathway.criterion" ids.
  final Set<String> checks;

  VitalSigns get vitals => scores.vitals;

  Duration? get sinceOnset => onset == null ? null : now.difference(onset!.at);

  /// The picked option label of a score item, or null.
  String? option(String scoreId, String itemId) {
    final score = allScores[scoreId]!;
    final i = scores.answersFor(scoreId).choice(itemId);
    if (i == null) return null;
    return score.items.firstWhere((it) => it.id == itemId).options[i].label;
  }

  int? points(String scoreId, String itemId) {
    final score = allScores[scoreId]!;
    final i = scores.answersFor(scoreId).choice(itemId);
    if (i == null) return null;
    return score.items.firstWhere((it) => it.id == itemId).options[i].points;
  }
}

/// Returns why the recorded data meet a criterion ("FC 112 bpm"), or null
/// when they don't.
typedef AutoCheck = String? Function(ClinicalState s);

class Criterion {
  const Criterion(
    this.id,
    this.label, {
    this.detail,
    this.auto,
    this.manual = true,
  });

  final String id;
  final String label;
  final String? detail;
  final AutoCheck? auto;

  /// Can be ticked by hand. Time windows can only come from the onset.
  final bool manual;
}

class CriteriaGroup {
  const CriteriaGroup(this.title, this.criteria, {this.all = false});

  final String title;
  final List<Criterion> criteria;

  /// Every criterion is needed, rather than any one of them.
  final bool all;
}

/// Which criteria are met, and why.
class CriteriaCheck {
  CriteriaCheck(this.pathway, ClinicalState s)
    : reasons = {
        for (final g in pathway.groups)
          for (final c in g.criteria) c.id: ?_reason(pathway, c, s),
      };

  static String? _reason(ViaVerde p, Criterion c, ClinicalState s) =>
      c.auto?.call(s) ??
      (c.manual && s.checks.contains('${p.id}.${c.id}') ? '' : null);

  final ViaVerde pathway;

  /// Met criteria by id: the automatic reason, or '' if ticked by hand.
  final Map<String, String> reasons;

  bool met(String criterionId) => reasons.containsKey(criterionId);

  bool isAuto(String criterionId) => reasons[criterionId]?.isNotEmpty ?? false;

  bool groupMet(CriteriaGroup g) => g.all
      ? g.criteria.every((c) => met(c.id))
      : g.criteria.any((c) => met(c.id));

  /// Labels of the met criteria, with their reasons, for the summary.
  List<String> get metLabels => [
    for (final g in pathway.groups)
      for (final c in g.criteria)
        if (met(c.id))
          reasons[c.id]!.isEmpty ? c.label : '${c.label} (${reasons[c.id]})',
  ];

  /// The pathway's status; worked out once, as it is read several times.
  late final ScoreResult result = pathway.evaluate(this);
}

class ViaVerde {
  const ViaVerde({
    required this.id,
    required this.name,
    required this.scope,
    required this.groups,
    required this.actions,
    required this.source,
    required this.evaluate,
  });

  final String id;

  /// "AVC", shown as "Via Verde AVC".
  final String name;

  /// Who it applies to ("Adulto, ≥ 18 anos").
  final String scope;
  final List<CriteriaGroup> groups;

  /// What to do and collect, from the INEM manuals.
  final List<String> actions;
  final String source;
  final ScoreResult Function(CriteriaCheck c) evaluate;

  String get fullName => 'Via Verde $name';

  CriteriaCheck check(ClinicalState s) => CriteriaCheck(this, s);
}

ScoreResult _status(
  Severity severity,
  String display,
  String label, {
  bool complete = true,
}) => ScoreResult(
  value: null,
  display: display,
  severity: severity,
  label: label,
  answered: complete ? 1 : 0,
  total: 1,
);

final _none = _status(
  Severity.incomplete,
  '–',
  'Sem critérios',
  complete: false,
);

// Automatic checks.

String? _vital(ClinicalState s, Vital vital, bool Function(num v) test) {
  final v = s.vitals[vital];
  return v != null && test(v)
      ? '${vital.short} ${s.vitals.format(vital)}'
      : null;
}

AutoCheck _within(Duration window) => (s) {
  final d = s.sinceOnset;
  return d != null && d <= window && !d.isNegative
      ? 'há ${formatDuration(d)}'
      : null;
};

String? _altered(String scoreId, String itemId, ClinicalState s, String name) =>
    s.option(scoreId, itemId) == 'Alterado' ? name : null;

String? _raceAtLeast1(String itemId, ClinicalState s) =>
    (s.points('race', itemId) ?? 0) >= 1 ? 'RACE' : null;

/// Met when the score [id] is complete and its total passes [test]:
/// "RTS 10".
AutoCheck _scoreWhere(String id, bool Function(int total) test) => (s) {
  final r = s.scores.resultFor(id);
  return r.complete && test(r.value!)
      ? '${allScores[id]!.name} ${r.value}'
      : null;
};

String? _alteredConsciousness(ClinicalState s) {
  final avds = s.vitals[Vital.avds];
  if (avds == null) return null;
  if (avds > 0) return 'AVDS ${avdsLevels[avds.toInt()].$1}';
  return s.vitals.newConfusion ? 'confusão recente' : null;
}

final viaVerdeAvc = ViaVerde(
  id: 'avc',
  name: 'AVC',
  scope: 'Adulto, ≥ 18 anos',
  source: 'INEM, Manual TAS Emergências Médicas (2024); DGS, Norma 015/2017',
  groups: [
    CriteriaGroup('Sinais de AVC de início súbito', [
      Criterion(
        'paresis',
        'Hemiparesia / hemiplegia',
        auto: (s) =>
            _altered('cincinnati', 'arm', s, 'Cincinnati') ??
            _raceAtLeast1('arm', s) ??
            _raceAtLeast1('leg', s),
      ),
      Criterion(
        'speech',
        'Disartria / afasia',
        auto: (s) =>
            _altered('cincinnati', 'speech', s, 'Cincinnati') ??
            _raceAtLeast1('aphasia', s),
      ),
      Criterion(
        'face',
        'Assimetria facial',
        auto: (s) =>
            _altered('cincinnati', 'face', s, 'Cincinnati') ??
            _raceAtLeast1('face', s),
      ),
    ]),
    CriteriaGroup(all: true, 'Critérios de inclusão', [
      Criterion(
        'age',
        'Idade ≥ 18 anos',
        auto: (s) => _vital(s, Vital.age, (v) => v >= 18),
      ),
      Criterion(
        'onset',
        'Início dos sintomas há 24 h ou menos',
        detail: 'Pela hora registada no topo da página',
        auto: _within(const Duration(hours: 24)),
        manual: false,
      ),
    ]),
  ],
  actions: const [
    'Contactar precocemente o CODU para validar a inclusão na Via Verde AVC.',
    'Avaliar Cincinnati e RACE (RACE ≥ 5: suspeita de oclusão de grande vaso).',
    'Avaliar a glicemia capilar.',
    'Posicionar com elevação do tronco a 30º.',
    'Recolher: hora de início, circunstâncias, dependência nas atividades de '
        'vida diária, AVC anteriores, anticoagulantes orais.',
  ],
  evaluate: (c) {
    final s = c.pathway.groups;
    final signs = c.groupMet(s[0]);
    if (!signs) return _none;
    if (c.groupMet(s[1])) {
      return _status(
        Severity.danger,
        '✓',
        'Critérios cumpridos: contactar CODU',
      );
    }
    return _status(Severity.warning, '!', 'Sinais de AVC: verificar inclusão');
  },
);

final viaVerdeCoronaria = ViaVerde(
  id: 'coronaria',
  name: 'Coronária',
  scope: 'Adulto',
  source: 'INEM, Manual TAS Emergências Médicas (2024); DGS, Norma 003/2025',
  groups: [
    CriteriaGroup('Suspeita de síndrome coronária aguda', [
      Criterion(
        'pain',
        'Dor torácica sugestiva de origem cardíaca',
        detail: 'Pressão, aperto, peso ou ardor; não alivia com o repouso',
      ),
      Criterion(
        'atypical',
        'Sintomas atípicos',
        detail: 'Dispneia, sudorese, náuseas; idosos, mulheres, diabéticos',
      ),
    ]),
    CriteriaGroup('Eletrocardiograma', [
      Criterion(
        'st',
        'Elevação de ST no ECG de 12 derivações',
        detail: 'Validado pelo médico do CODU',
        auto: (s) => s.option('proacs', 'st') == 'Sim' ? 'ProACS' : null,
      ),
    ]),
    CriteriaGroup('Tempo', [
      Criterion(
        'onset',
        'Início dos sintomas há 12 h ou menos',
        detail: 'Pela hora registada no topo da página',
        auto: _within(const Duration(hours: 12)),
        manual: false,
      ),
    ]),
  ],
  actions: const [
    'Pedir apoio diferenciado precocemente: ECG de 12 derivações e envio ao CODU.',
    'Caracterizar a dor e registar a hora de início dos sintomas.',
    'Evitar qualquer esforço; transportar em posição de Fowler (45º).',
    'Oxigénio apenas de acordo com o protocolo (avaliar a SpO₂).',
  ],
  evaluate: (c) {
    final g = c.pathway.groups;
    final suspicion = c.groupMet(g[0]), st = c.groupMet(g[1]);
    if (!suspicion && !st) return _none;
    if (!st) {
      return _status(
        Severity.warning,
        '!',
        'Suspeita de SCA: ECG e contactar CODU',
      );
    }
    if (c.groupMet(g[2])) {
      return _status(
        Severity.danger,
        '✓',
        'Critérios cumpridos: contactar CODU',
      );
    }
    return _status(
      Severity.danger,
      '!',
      'Elevação de ST: confirmar início e contactar CODU',
    );
  },
);

/// The four fields of the national form: suspicion needs one in each.
final viaVerdeSepsis = ViaVerde(
  id: 'sepsis',
  name: 'Sépsis',
  scope: 'Adulto',
  source: 'INEM, Verbete Nacional de Socorro; DGS, Norma 010/2016',
  groups: [
    CriteriaGroup('Temperatura', [
      Criterion(
        'cold',
        '< 35 ºC',
        auto: (s) => _vital(s, Vital.temp, (v) => v < 35),
      ),
      Criterion(
        'fever',
        '≥ 38 ºC',
        auto: (s) => _vital(s, Vital.temp, (v) => v >= 38),
      ),
    ]),
    CriteriaGroup('Suspeita de infeção', [
      const Criterion('headache', 'Cefaleia'),
      Criterion(
        'consciousness',
        'Alteração de consciência',
        auto: _alteredConsciousness,
      ),
      const Criterion('dyspnoea', 'Dispneia / tosse'),
      const Criterion('abdominal', 'Dor abdominal'),
      const Criterion('jaundice', 'Icterícia'),
      const Criterion('urinary', 'Disúria / polaquiúria'),
      const Criterion('lumbar', 'Dor lombar'),
      const Criterion('skin', 'Sinais inflamatórios cutâneos'),
      const Criterion('clinician', 'Critério do clínico responsável'),
    ]),
    CriteriaGroup('Inflamação', [
      Criterion('avds', 'AVDS alterado', auto: _alteredConsciousness),
      Criterion(
        'hr',
        'FC > 90 bpm',
        auto: (s) => _vital(s, Vital.hr, (v) => v > 90),
      ),
      Criterion(
        'rr',
        'FR > 22 cpm',
        auto: (s) => _vital(s, Vital.rr, (v) => v > 22),
      ),
    ]),
    CriteriaGroup('Gravidade', [
      const Criterion('lactate', 'Lactato > 2 mmol/L'),
      Criterion(
        'sbp',
        'PAS < 90 mmHg',
        auto: (s) => _vital(s, Vital.sbp, (v) => v < 90),
      ),
      const Criterion('pao2', 'PaO₂ < 60 mmHg'),
      Criterion(
        'spo2',
        'SpO₂ < 90%',
        auto: (s) => _vital(s, Vital.spo2, (v) => v < 90),
      ),
    ]),
  ],
  actions: const [
    'Perante caso suspeito ou provável VV Sépsis, contactar o CODU.',
    'Registar pelo menos 2 avaliações completas de sinais vitais: antes e '
        'depois das medidas.',
    'Recolher: progressão dos sintomas, história de infeção, medicação habitual.',
  ],
  evaluate: (c) {
    final n = c.pathway.groups.where(c.groupMet).length;
    if (n == 0) return _none;
    if (n == 4) {
      return _status(
        Severity.danger,
        '4/4',
        'Suspeita de sépsis: contactar CODU',
      );
    }
    return _status(
      Severity.incomplete,
      '$n/4',
      '$n de 4 campos',
      complete: false,
    );
  },
);

final viaVerdeTrauma = ViaVerde(
  id: 'trauma',
  name: 'Trauma',
  scope: 'Adulto',
  source: 'DGS, Norma 012/2022 (Anexo II); INEM, Verbete Nacional de Socorro',
  groups: [
    // Vital signs and scores alone don't make a trauma: a septic patient
    // with PAS < 90 must not light up this pathway.
    const CriteriaGroup('Contexto', [
      Criterion(
        'trauma',
        'Vítima de trauma',
        detail: 'Ou assinalar uma lesão ou mecanismo abaixo',
      ),
    ]),
    CriteriaGroup('Repercussões fisiológicas', [
      Criterion(
        'rr',
        'FR < 10 ou > 29 cpm',
        auto: (s) => _vital(s, Vital.rr, (v) => v < 10 || v > 29),
      ),
      Criterion(
        'spo2',
        'SpO₂ < 90% com O₂ suplementar',
        auto: (s) => (s.vitals[Vital.o2] ?? 0) > 0
            ? _vital(s, Vital.spo2, (v) => v < 90)
            : null,
      ),
      Criterion(
        'sbp',
        'PAS < 90 mmHg',
        auto: (s) => _vital(s, Vital.sbp, (v) => v < 90),
      ),
      Criterion(
        'gcs',
        'ECG < 14 ou queda ≥ 2 pontos desde o acidente',
        auto: (s) {
          final r = s.scores.resultFor('gcs');
          return r.complete && r.value! < 14 ? 'ECG ${r.value}' : null;
        },
      ),
    ]),
    CriteriaGroup('Anatomia da lesão', [
      const Criterion('skull', 'Fratura do crânio com afundamento'),
      const Criterion('spine', 'Traumatismo vertebro-medular'),
      const Criterion('flail', 'Retalho costal móvel'),
      const Criterion(
        'longbones',
        'Fratura de 2 ou mais ossos longos',
        detail: 'Úmero, fémur, tíbia',
      ),
      const Criterion('pelvis', 'Fratura instável da bacia'),
      const Criterion(
        'amputation',
        'Amputação proximal ao punho e/ou ao tornozelo',
      ),
      const Criterion(
        'replant',
        'Amputação com potencial para reimplantação',
        detail: 'Segmento viável',
      ),
      Criterion(
        'burns',
        'Queimaduras major',
        detail:
            '2.º grau > 20% ou 3.º grau > 5%; face, pescoço, tórax '
            'circunferencial, mãos e pés',
        auto: (s) {
          final second = s.burns.percentWhere((d) => d == BurnDegree.second);
          final third = s.burns.percentWhere((d) => d == BurnDegree.third);
          if (second > 20) return '2.º grau ${formatPercent(second)}';
          if (third > 5) return '3.º grau ${formatPercent(third)}';
          return null;
        },
      ),
      const Criterion('inhalation', 'Queimaduras com inalação'),
    ]),
    CriteriaGroup('Mecanismo da lesão', [
      const Criterion(
        'penetrating',
        'Trauma penetrante',
        detail:
            'Cabeça, pescoço, tórax, abdómen, períneo, proximal ao '
            'cotovelo e/ou joelho',
      ),
      const Criterion('ejection', 'Projeção da vítima'),
      const Criterion(
        'entrapment',
        'Encarceramento físico ou mecânico > 30 min',
      ),
      const Criterion('fall', 'Queda superior a 6 metros'),
      const Criterion('mci', 'Evento multivítimas (5 ou mais)'),
      const Criterion('hanging', 'Enforcamento, submersão ou afogamento'),
    ]),
    CriteriaGroup('Escalas (referenciação a centro de trauma)', [
      Criterion(
        'rts',
        'RTS ≤ 10',
        detail: 'Calculada nas escalas gerais',
        manual: false,
        auto: _scoreWhere('rts', (v) => v <= 10),
      ),
      Criterion(
        'mgap',
        'MGAP < 18',
        detail: 'Calculada nas escalas gerais',
        manual: false,
        auto: _scoreWhere('mgap', (v) => v < 18),
      ),
    ]),
  ],
  actions: const [
    'Contactar o CODU: ativação de SAV (VMER/SHEM) e referenciação ao '
        'centro de trauma.',
    'Completar a avaliação inicial ABCDE nos primeiros 20 minutos.',
  ],
  evaluate: (c) {
    final [context, physiology, anatomy, mechanism, scales] = c.pathway.groups;
    final trauma =
        c.groupMet(context) || c.groupMet(anatomy) || c.groupMet(mechanism);
    final criteria = [physiology, anatomy, mechanism, scales].any(c.groupMet);
    if (!trauma) {
      return criteria
          ? _status(
              Severity.incomplete,
              '–',
              'Assinalar se é vítima de trauma',
              complete: false,
            )
          : _none;
    }
    if (!criteria) return _none;
    return _status(Severity.danger, '✓', 'Critérios cumpridos: contactar CODU');
  },
);

final viasVerdes = [
  viaVerdeAvc,
  viaVerdeCoronaria,
  viaVerdeSepsis,
  viaVerdeTrauma,
];
