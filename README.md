# EPHScores

![EPHScores](docs/design/banner.png)

## O que é?

EPHScores ajuda profissionais de emergência pré-hospitalar a avaliar vítimas
de forma rápida e simples, no terreno.

- **Evolução do doente:** cada avaliação é registada com hora e duração;
  as respostas ficam como referência para a seguinte, e a página
  *Evolução* mostra a tendência de cada escala e permite copiar um resumo
  em texto
- **Sinais vitais:** os campos do verbete nacional (AVDS, FR, SpO₂, O₂, FC,
  PA, temperatura, dor por escala numérica ou de faces, e glicemia),
  registados uma vez e usados por todas as
  escalas que deles precisam; a NEWS2 fica calculada sem mais toques, com o
  índice de choque ao lado
- **Vias Verdes:** hora de início dos sintomas e critérios das Vias Verdes
  AVC, Coronária, Sépsis e Trauma, assinalados automaticamente a partir dos
  sinais vitais, das escalas e do mapa de queimaduras
- **Escalas gerais:** Cincinnati, Glasgow (ECG), MGAP, NEWS2, ProACS, RACE e RTS
- **Escalas pediátricas:** APGAR, FLACC, Triângulo de Avaliação Pediátrica (TAP) e PTS
- **Avaliação do queimado:** regra dos nove para adulto e criança, com grau por região
- **Triagem START:** algoritmo passo a passo e contagem de vítimas por
  prioridade, separada do doente
- **Contactos úteis:** linhas de apoio com chamada direta

### Feita para o terreno

- **100 % offline.** A versão de produção não pede permissão de Internet; nada
  sai do dispositivo.
- **Botões grandes**, pensados para usar com luvas.
- **Nada se perde:** as respostas e as avaliações são guardadas a cada toque
  e sobrevivem ao fecho da aplicação.
- **Sem dados pessoais:** não há campos de identificação (apenas a idade),
  e só o último doente é mantido. "Novo doente" apaga o anterior.
- **Modo escuro** automático, para turnos noturnos.

> A aplicação é um auxiliar de cálculo. Não substitui a avaliação clínica nem
> os protocolos em vigor.

## Construída com

[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)

Interface em Material 3, com a paleta original (azul-marinho e cores de
semáforo).

## Onde instalar

- **Android:** [Google Play](https://play.google.com/store/apps/details?id=com.davidaraujo.ephscores)
- **iPhone / iPad:** abrir <https://ephscores-7e4eb.web.app> no Safari,
  tocar em *Partilhar* e depois em *Adicionar ao ecrã principal*. A aplicação web (PWA) fica guardada no
  dispositivo e funciona sem rede a partir da primeira abertura.

## Código-fonte

A aplicação é open source ([licença](LICENSE)). O projeto Flutter está em
[`ephscores/`](ephscores), com as instruções de desenvolvimento no respetivo
README.
