import '../vitals/vitals.dart';
import 'model.dart';

final apgar = ScoreDefinition(
  id: 'apgar',
  name: 'APGAR',
  fullName: 'Índice de APGAR',
  description: 'Avaliação do recém-nascido ao 1.º e 5.º minuto.',
  items: const [
    ScoreItem(
      id: 'color',
      label: 'Cor',
      options: [
        ScoreOption('Completamente rosado', 2),
        ScoreOption('Extremidades cianosadas', 1),
        ScoreOption('Pálido ou cianosado', 0),
      ],
    ),
    ScoreItem(
      id: 'hr',
      label: 'Frequência cardíaca',
      options: [
        ScoreOption('> 100 bpm', 2),
        ScoreOption('< 100 bpm', 1),
        ScoreOption('Ausente', 0),
      ],
    ),
    ScoreItem(
      id: 'reflex',
      label: 'Irritabilidade reflexa',
      options: [
        ScoreOption('Chora, espirra ou tosse', 2),
        ScoreOption('Responde a estímulos', 1, detail: 'Careta'),
        ScoreOption('Sem resposta', 0),
      ],
    ),
    ScoreItem(
      id: 'tone',
      label: 'Tónus muscular',
      options: [
        ScoreOption('Ativo, fletido', 2),
        ScoreOption('Alguma flexão', 1),
        ScoreOption('Flácido', 0),
      ],
    ),
    ScoreItem(
      id: 'breathing',
      label: 'Respiração',
      options: [
        ScoreOption('Choro vigoroso', 2),
        ScoreOption('Lenta, irregular ou fraca', 1),
        ScoreOption('Ausente', 0),
      ],
    ),
  ],
  evaluate: additive(const [
    Band(0, Severity.danger, 'Depressão grave'),
    Band(4, Severity.warning, 'Depressão moderada'),
    Band(7, Severity.ok, 'Normal'),
  ]),
);

final pts = ScoreDefinition(
  id: 'pts',
  name: 'PTS',
  fullName: 'Pediatric Trauma Score',
  description: 'Gravidade no trauma pediátrico, de −6 a 12.',
  items: const [
    ScoreItem(
      id: 'weight',
      label: 'Peso',
      options: [
        ScoreOption('> 20 kg', 2),
        ScoreOption('10 – 20 kg', 1),
        ScoreOption('< 10 kg', -1),
      ],
    ),
    ScoreItem(
      id: 'airway',
      label: 'Via aérea',
      options: [
        ScoreOption('Normal', 2),
        ScoreOption(
          'Estabilizável',
          1,
          detail: 'Com adjuvantes ou posicionamento',
        ),
        ScoreOption(
          'Não estabilizável',
          -1,
          detail: 'Requer via aérea avançada',
        ),
      ],
    ),
    ScoreItem(
      id: 'sbp',
      label: 'Pressão arterial sistólica',
      vital: VitalBinding([Vital.sbp], _ptsSbp),
      options: [
        ScoreOption('> 90 mmHg', 2, detail: 'ou pulso radial palpável'),
        ScoreOption('50 – 90 mmHg', 1, detail: 'ou pulso femoral palpável'),
        ScoreOption('< 50 mmHg', -1, detail: 'ou sem pulso palpável'),
      ],
    ),
    ScoreItem(
      id: 'cns',
      label: 'Nível de consciência',
      options: [
        ScoreOption('Acordado', 2),
        ScoreOption(
          'Lentificado',
          1,
          detail: 'ou perda de consciência transitória',
        ),
        ScoreOption('Inconsciente', -1),
      ],
    ),
    ScoreItem(
      id: 'skeletal',
      label: 'Lesões esqueléticas',
      options: [
        ScoreOption('Ausentes', 2),
        ScoreOption('Fratura fechada', 1),
        ScoreOption('Fraturas abertas ou múltiplas', -1),
      ],
    ),
    ScoreItem(
      id: 'wounds',
      label: 'Feridas',
      options: [
        ScoreOption('Ausentes', 2),
        ScoreOption('Superficiais', 1),
        ScoreOption('Profundas ou penetrantes', -1),
      ],
    ),
  ],
  evaluate: additive(const [
    Band(-6, Severity.danger, 'Risco muito elevado'),
    Band(1, Severity.warning, 'Risco elevado'),
    Band(9, Severity.ok, 'Risco baixo'),
  ]),
);

const _normal = ScoreOption('Sem alterações', 0, exclusive: true);

final pat = ScoreDefinition(
  id: 'pat',
  name: 'TAP',
  fullName: 'Triângulo de Avaliação Pediátrica',
  description: 'Impressão geral em segundos, sem tocar na criança.',
  items: const [
    ScoreItem(
      id: 'appearance',
      label: 'Aparência',
      multi: true,
      options: [
        _normal,
        ScoreOption('Tónus anormal', 1),
        ScoreOption('Não interage', 1),
        ScoreOption('Difícil de consolar', 1),
        ScoreOption('Olhar anormal', 1),
        ScoreOption('Choro ou discurso anormal', 1),
      ],
    ),
    ScoreItem(
      id: 'breathing',
      label: 'Trabalho respiratório',
      multi: true,
      options: [
        _normal,
        ScoreOption('Sons anormais', 1),
        ScoreOption('Posição anormal ou tripé', 1),
        ScoreOption('Tiragem', 1),
        ScoreOption('Adejo nasal', 1),
        ScoreOption('Apneia ou gasping', 1),
      ],
    ),
    ScoreItem(
      id: 'circulation',
      label: 'Circulação cutânea',
      multi: true,
      options: [
        _normal,
        ScoreOption('Palidez', 1),
        ScoreOption('Pele marmoreada', 1),
        ScoreOption('Cianose', 1),
      ],
    ),
  ],
  evaluate: (score, answers, _) {
    bool abnormal(String id) => answers.of(id).any((i) => i != 0);
    final a = abnormal('appearance'),
        b = abnormal('breathing'),
        c = abnormal('circulation');
    final answered = score.items.where((it) => answers.has(it.id)).length;
    final count = [a, b, c].where((x) => x).length;
    final complete = answered == score.items.length;
    final (severity, label) = switch ((a, b, c)) {
      (false, false, false) => (Severity.ok, 'Estável'),
      (true, false, false) => (
        Severity.warning,
        'Disfunção do SNC ou metabólica',
      ),
      (false, true, false) => (Severity.warning, 'Dificuldade respiratória'),
      (false, false, true) => (Severity.warning, 'Choque compensado'),
      (true, true, false) => (Severity.danger, 'Insuficiência respiratória'),
      (true, false, true) => (Severity.danger, 'Choque descompensado'),
      (false, true, true) => (
        Severity.danger,
        'Compromisso respiratório e circulatório',
      ),
      (true, true, true) => (
        Severity.danger,
        'Insuficiência cardiorrespiratória',
      ),
    };
    return ScoreResult(
      value: answered == 0 ? null : count,
      display: answered == 0 ? '–' : '$count/3',
      severity: complete ? severity : Severity.incomplete,
      label: complete ? label : '',
      answered: answered,
      total: score.items.length,
    );
  },
);

/// Observational pain scale, in the Portuguese version of DGS guidance
/// 014/2010 (Batalha et al., 2009). © The Regents of the University of
/// Michigan.
final flacc = ScoreDefinition(
  id: 'flacc',
  name: 'FLACC',
  fullName: 'Face, Legs, Activity, Cry, Consolability',
  description:
      'Dor em crianças com menos de 4 anos ou sem capacidade para a '
      'verbalizar, de 0 a 10. A partir dos 6 anos usar a escala numérica '
      '(Dor, nos sinais vitais).',
  items: const [
    ScoreItem(
      id: 'face',
      label: 'Face',
      options: [
        ScoreOption('Nenhuma expressão particular ou sorriso', 0),
        ScoreOption(
          'Caretas ou sobrancelhas franzidas de vez em quando',
          1,
          detail: 'Introversão, desinteresse',
        ),
        ScoreOption('Tremor frequente do queixo, mandíbulas cerradas', 2),
      ],
    ),
    ScoreItem(
      id: 'legs',
      label: 'Pernas',
      options: [
        ScoreOption('Posição normal ou relaxadas', 0),
        ScoreOption('Inquietas, agitadas, tensas', 1),
        ScoreOption('Aos pontapés ou esticadas', 2),
      ],
    ),
    ScoreItem(
      id: 'activity',
      label: 'Atividade',
      options: [
        ScoreOption(
          'Deitado calmamente',
          0,
          detail: 'Posição normal, mexe-se facilmente',
        ),
        ScoreOption(
          'Contorcendo-se',
          1,
          detail: 'Virando-se para trás e para a frente, tenso',
        ),
        ScoreOption('Curvado, rígido ou com movimentos bruscos', 2),
      ],
    ),
    ScoreItem(
      id: 'cry',
      label: 'Choro',
      options: [
        ScoreOption('Ausência de choro', 0, detail: 'Acordado ou adormecido'),
        ScoreOption('Gemidos ou choramingos', 1, detail: 'Queixas ocasionais'),
        ScoreOption(
          'Choro persistente, gritos ou soluços',
          2,
          detail: 'Queixas frequentes',
        ),
      ],
    ),
    ScoreItem(
      id: 'consolability',
      label: 'Consolabilidade',
      options: [
        ScoreOption('Satisfeito, relaxado', 0),
        ScoreOption(
          'Tranquilizado por toques, abraços ou conversas ocasionais',
          1,
          detail: 'Pode ser distraído',
        ),
        ScoreOption('Difícil de consolar ou confortar', 2),
      ],
    ),
  ],
  evaluate: additive(const [
    Band(0, Severity.ok, 'Sem dor'),
    Band(1, Severity.ok, 'Dor ligeira'),
    Band(4, Severity.warning, 'Dor moderada'),
    Band(7, Severity.danger, 'Dor intensa'),
  ], display: (sum) => '$sum/10'),
);

final pediatricScores = [apgar, flacc, pat, pts];

int? _ptsSbp(VitalSigns v, Answers _) => switch (v[Vital.sbp]) {
  null => null,
  > 90 => 0,
  >= 50 => 1,
  _ => 2,
};
