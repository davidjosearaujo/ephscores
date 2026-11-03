import 'model.dart';

const _yesNo = [ScoreOption('Normal', 0), ScoreOption('Alterado', 1)];

final cincinnati = ScoreDefinition(
  id: 'cincinnati',
  name: 'Cincinnati',
  fullName: 'Escala de AVC de Cincinnati',
  description: 'Rastreio pré-hospitalar de AVC.',
  items: const [
    ScoreItem(
      id: 'face',
      label: 'Paresia facial',
      hint: 'Pedir para sorrir ou mostrar os dentes.',
      options: _yesNo,
    ),
    ScoreItem(
      id: 'arm',
      label: 'Queda do membro superior',
      hint: 'Braços estendidos, olhos fechados, 10 segundos.',
      options: _yesNo,
    ),
    ScoreItem(
      id: 'speech',
      label: 'Alteração da fala',
      hint: 'Repetir uma frase simples.',
      options: _yesNo,
    ),
  ],
  evaluate: additive(const [
    Band(0, Severity.ok, 'Sem alterações'),
    Band(1, Severity.danger, 'Suspeita de AVC'),
  ], display: (sum) => '$sum/3'),
);

final gcs = ScoreDefinition(
  id: 'gcs',
  name: 'ECG',
  fullName: 'Escala de Coma de Glasgow',
  description: 'Nível de consciência. Usada também pela MGAP e RTS.',
  items: const [
    ScoreItem(
      id: 'eyes',
      label: 'Abertura ocular',
      options: [
        ScoreOption('Espontânea', 4),
        ScoreOption('À voz', 3),
        ScoreOption('À dor', 2),
        ScoreOption('Sem resposta', 1),
      ],
    ),
    ScoreItem(
      id: 'verbal',
      label: 'Resposta verbal',
      options: [
        ScoreOption('Orientada', 5),
        ScoreOption('Confusa', 4),
        ScoreOption('Palavras inapropriadas', 3),
        ScoreOption('Sons incompreensíveis', 2),
        ScoreOption('Sem resposta', 1),
      ],
    ),
    ScoreItem(
      id: 'motor',
      label: 'Resposta motora',
      options: [
        ScoreOption('Obedece a ordens', 6),
        ScoreOption('Localiza a dor', 5),
        ScoreOption('Fuga à dor', 4, detail: 'Flexão normal'),
        ScoreOption('Flexão anormal', 3, detail: 'Descorticação'),
        ScoreOption('Extensão', 2, detail: 'Descerebração'),
        ScoreOption('Sem resposta', 1),
      ],
    ),
  ],
  evaluate: (score, answers, lookup) {
    final base = additive(const [
      Band(3, Severity.danger, 'Grave'),
      Band(9, Severity.warning, 'Moderado'),
      Band(13, Severity.ok, 'Ligeiro'),
    ])(score, answers, lookup);
    String part(String letter, String id) {
      final i = answers.choice(id);
      final item = score.items.firstWhere((it) => it.id == id);
      return '$letter${i == null ? '–' : item.options[i].points}';
    }

    return ScoreResult(
      value: base.value,
      display: base.display,
      severity: base.severity,
      label: base.label,
      answered: base.answered,
      total: base.total,
      breakdown: base.answered == 0
          ? null
          : '${part('O', 'eyes')} ${part('V', 'verbal')} ${part('M', 'motor')}',
    );
  },
);

final mgap = ScoreDefinition(
  id: 'mgap',
  name: 'MGAP',
  fullName: 'Mechanism, GCS, Age, Pressure',
  description: 'Prognóstico no trauma. Inclui a ECG.',
  dependsOn: const ['gcs'],
  items: const [
    ScoreItem(
      id: 'mechanism',
      label: 'Mecanismo de lesão',
      options: [ScoreOption('Fechado', 4), ScoreOption('Penetrante', 0)],
    ),
    ScoreItem(
      id: 'age',
      label: 'Idade',
      options: [ScoreOption('< 60 anos', 5), ScoreOption('≥ 60 anos', 0)],
    ),
    ScoreItem(
      id: 'sbp',
      label: 'Pressão arterial sistólica',
      options: [
        ScoreOption('> 120 mmHg', 5),
        ScoreOption('60 – 120 mmHg', 3),
        ScoreOption('< 60 mmHg', 0),
      ],
    ),
  ],
  evaluate: (score, answers, lookup) => withGcs(
    score,
    answers,
    lookup(gcs.id),
    gcsPoints: (g) => g,
    bands: const [
      Band(0, Severity.danger, 'Risco alto'),
      Band(18, Severity.warning, 'Risco intermédio'),
      Band(23, Severity.ok, 'Risco baixo'),
    ],
  ),
);

/// Converts a GCS total into the coded value used by the triage RTS.
int gcsToRts(int gcs) => switch (gcs) {
  >= 13 => 4,
  >= 9 => 3,
  >= 6 => 2,
  >= 4 => 1,
  _ => 0,
};

final rts = ScoreDefinition(
  id: 'rts',
  name: 'RTS',
  fullName: 'Revised Trauma Score (triagem)',
  description: 'Gravidade no trauma, de 0 a 12. Inclui a ECG.',
  dependsOn: const ['gcs'],
  items: const [
    ScoreItem(
      id: 'rr',
      label: 'Frequência respiratória',
      options: [
        ScoreOption('10 – 29 cpm', 4),
        ScoreOption('> 29 cpm', 3),
        ScoreOption('6 – 9 cpm', 2),
        ScoreOption('1 – 5 cpm', 1),
        ScoreOption('0 cpm', 0),
      ],
    ),
    ScoreItem(
      id: 'sbp',
      label: 'Pressão arterial sistólica',
      options: [
        ScoreOption('> 89 mmHg', 4),
        ScoreOption('76 – 89 mmHg', 3),
        ScoreOption('50 – 75 mmHg', 2),
        ScoreOption('1 – 49 mmHg', 1),
        ScoreOption('Sem pulso', 0),
      ],
    ),
  ],
  evaluate: (score, answers, lookup) => withGcs(
    score,
    answers,
    lookup(gcs.id),
    gcsPoints: gcsToRts,
    bands: const [
      Band(0, Severity.danger, 'Grave'),
      Band(11, Severity.warning, 'Alterado'),
      Band(12, Severity.ok, 'Normal'),
    ],
  ),
);

/// Shared evaluation for scores that add a GCS-derived component.
ScoreResult withGcs(
  ScoreDefinition score,
  Answers answers,
  ScoreResult gcsResult, {
  required int Function(int gcs) gcsPoints,
  required List<Band> bands,
}) {
  final s = sumPoints(score, answers);
  final gcsDone = gcsResult.complete;
  final answered = s.answered + (gcsDone ? 1 : 0);
  final total = s.total + 1;
  final sum = s.sum + (gcsDone ? gcsPoints(gcsResult.value!) : 0);
  final band = answered >= total ? bandFor(sum, bands) : null;
  return ScoreResult(
    value: answered == 0 ? null : sum,
    display: answered == 0 ? '–' : '$sum',
    severity: band?.severity ?? Severity.incomplete,
    label: band?.label ?? '',
    answered: answered,
    total: total,
  );
}

final news2 = ScoreDefinition(
  id: 'news2',
  name: 'NEWS2',
  fullName: 'National Early Warning Score 2',
  description: 'Deteção precoce de deterioração clínica.',
  items: [
    const ScoreItem(
      id: 'rr',
      label: 'Frequência respiratória',
      options: [
        ScoreOption('≤ 8', 3),
        ScoreOption('9 – 11', 1),
        ScoreOption('12 – 20', 0),
        ScoreOption('21 – 24', 2),
        ScoreOption('≥ 25', 3),
      ],
    ),
    const ScoreItem(
      id: 'scale',
      label: 'Escala de SpO₂',
      hint:
          'Escala 2 apenas em insuficiência respiratória hipercápnica '
          'conhecida (ex.: DPOC), com alvo de 88–92%.',
      optional: true,
      options: [ScoreOption('Escala 1', 0), ScoreOption('Escala 2', 0)],
    ),
    ScoreItem(
      id: 'spo2',
      label: 'SpO₂ (%)',
      visibleWhen: (a) => a.choice('scale') != 1,
      options: const [
        ScoreOption('≤ 91', 3),
        ScoreOption('92 – 93', 2),
        ScoreOption('94 – 95', 1),
        ScoreOption('≥ 96', 0),
      ],
    ),
    ScoreItem(
      id: 'spo2_2',
      label: 'SpO₂ (%) — escala 2',
      visibleWhen: (a) => a.choice('scale') == 1,
      options: const [
        ScoreOption('≤ 83', 3),
        ScoreOption('84 – 85', 2),
        ScoreOption('86 – 87', 1),
        ScoreOption('88 – 92', 0, detail: 'ou ≥ 93 em ar ambiente'),
        ScoreOption('93 – 94', 1, detail: 'com O₂'),
        ScoreOption('95 – 96', 2, detail: 'com O₂'),
        ScoreOption('≥ 97', 3, detail: 'com O₂'),
      ],
    ),
    const ScoreItem(
      id: 'o2',
      label: 'Ar ou oxigénio',
      options: [
        ScoreOption('Ar ambiente', 0),
        ScoreOption('Oxigénio suplementar', 2),
      ],
    ),
    const ScoreItem(
      id: 'sbp',
      label: 'Pressão arterial sistólica (mmHg)',
      options: [
        ScoreOption('≤ 90', 3),
        ScoreOption('91 – 100', 2),
        ScoreOption('101 – 110', 1),
        ScoreOption('111 – 219', 0),
        ScoreOption('≥ 220', 3),
      ],
    ),
    const ScoreItem(
      id: 'hr',
      label: 'Frequência cardíaca (bpm)',
      options: [
        ScoreOption('≤ 40', 3),
        ScoreOption('41 – 50', 1),
        ScoreOption('51 – 90', 0),
        ScoreOption('91 – 110', 1),
        ScoreOption('111 – 130', 2),
        ScoreOption('≥ 131', 3),
      ],
    ),
    const ScoreItem(
      id: 'avds',
      label: 'Consciência',
      options: [
        ScoreOption('Alerta', 0),
        ScoreOption('Confusão recente, V, D ou S', 3),
      ],
    ),
    const ScoreItem(
      id: 'temp',
      label: 'Temperatura (°C)',
      options: [
        ScoreOption('≤ 35,0', 3),
        ScoreOption('35,1 – 36,0', 1),
        ScoreOption('36,1 – 38,0', 0),
        ScoreOption('38,1 – 39,0', 1),
        ScoreOption('≥ 39,1', 2),
      ],
    ),
  ],
  evaluate: (score, answers, lookup) {
    final base = additive(const [
      Band(0, Severity.ok, 'Risco baixo'),
      Band(5, Severity.warning, 'Risco médio'),
      Band(7, Severity.danger, 'Risco alto'),
    ])(score, answers, lookup);
    // A single parameter scoring 3 raises a low aggregate to low-medium.
    final redFlag = score
        .visibleItems(answers)
        .any(
          (item) => answers.of(item.id).any((i) => item.options[i].points == 3),
        );
    if (base.complete && base.severity == Severity.ok && redFlag) {
      return ScoreResult(
        value: base.value,
        display: base.display,
        severity: Severity.warning,
        label: 'Risco baixo-médio (parâmetro com 3)',
        answered: base.answered,
        total: base.total,
      );
    }
    return base;
  },
);

final proacs = ScoreDefinition(
  id: 'proacs',
  name: 'ProACS',
  fullName: 'Score de risco ProACS',
  description: 'Risco de mortalidade na síndrome coronária aguda.',
  items: const [
    ScoreItem(
      id: 'age',
      label: 'Idade',
      options: [ScoreOption('< 72 anos', 0), ScoreOption('≥ 72 anos', 1)],
    ),
    ScoreItem(
      id: 'sbp',
      label: 'Pressão arterial sistólica',
      options: [ScoreOption('≥ 116 mmHg', 0), ScoreOption('< 116 mmHg', 1)],
    ),
    ScoreItem(
      id: 'killip',
      label: 'Classe de Killip',
      options: [
        ScoreOption('I', 0),
        ScoreOption('II ou III', 1),
        ScoreOption('IV', 3),
      ],
    ),
    ScoreItem(
      id: 'st',
      label: 'Elevação de ST',
      options: [ScoreOption('Não', 0), ScoreOption('Sim', 1)],
    ),
  ],
  evaluate: additive(const [
    Band(0, Severity.ok, 'Risco baixo'),
    Band(1, Severity.warning, 'Risco intermédio'),
    Band(3, Severity.danger, 'Risco alto'),
  ]),
);

bool _leftDeficit(Answers a) => a.choice('side') == 0;
bool _rightDeficit(Answers a) => a.choice('side') == 1;

final race = ScoreDefinition(
  id: 'race',
  name: 'RACE',
  fullName: 'Rapid Arterial oCclusion Evaluation',
  description: 'Suspeita de oclusão de grande vaso no AVC.',
  items: [
    const ScoreItem(
      id: 'side',
      label: 'Lado do défice',
      options: [ScoreOption('Esquerdo', 0), ScoreOption('Direito', 0)],
    ),
    const ScoreItem(
      id: 'face',
      label: 'Paresia facial',
      options: [
        ScoreOption('Ausente', 0),
        ScoreOption('Ligeira', 1),
        ScoreOption('Moderada a grave', 2),
      ],
    ),
    const ScoreItem(
      id: 'arm',
      label: 'Paresia do membro superior',
      options: [
        ScoreOption('Ausente ou ligeira', 0, detail: 'Mantém > 10 s'),
        ScoreOption('Moderada', 1, detail: 'Mantém < 10 s'),
        ScoreOption('Grave', 2, detail: 'Não levanta'),
      ],
    ),
    const ScoreItem(
      id: 'leg',
      label: 'Paresia do membro inferior',
      options: [
        ScoreOption('Ausente ou ligeira', 0, detail: 'Mantém > 5 s'),
        ScoreOption('Moderada', 1, detail: 'Mantém < 5 s'),
        ScoreOption('Grave', 2, detail: 'Não levanta'),
      ],
    ),
    const ScoreItem(
      id: 'gaze',
      label: 'Desvio oculocefálico',
      options: [ScoreOption('Ausente', 0), ScoreOption('Presente', 1)],
    ),
    ScoreItem(
      id: 'agnosia',
      label: 'Agnosia',
      hint: 'Défice esquerdo: reconhece o braço parético e o défice?',
      visibleWhen: _leftDeficit,
      options: const [
        ScoreOption('Reconhece braço e défice', 0),
        ScoreOption('Não reconhece braço ou défice', 1),
        ScoreOption('Não reconhece nenhum', 2),
      ],
    ),
    ScoreItem(
      id: 'aphasia',
      label: 'Afasia',
      hint: 'Défice direito: "feche os olhos" e "aperte a mão".',
      visibleWhen: _rightDeficit,
      options: const [
        ScoreOption('Cumpre as 2 ordens', 0),
        ScoreOption('Cumpre 1 ordem', 1),
        ScoreOption('Não cumpre ordens', 2),
      ],
    ),
  ],
  evaluate: additive(const [
    Band(0, Severity.ok, 'Sem défice'),
    Band(1, Severity.warning, 'Baixa probabilidade de oclusão'),
    Band(5, Severity.danger, 'Suspeita de oclusão de grande vaso'),
  ]),
);

final adultScores = [cincinnati, gcs, mgap, news2, proacs, race, rts];
