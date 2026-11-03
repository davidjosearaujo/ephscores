# EPHScores

![Banner](UI/Images/App_banner.png)

## O que é?

EPHScores ajuda profissionais de emergência pré-hospitalar a avaliar vítimas
de forma rápida e simples, no terreno.

- **Escalas gerais:** Cincinnati, Glasgow (ECG), MGAP, NEWS2, ProACS, RACE e RTS
- **Escalas pediátricas:** APGAR, Triângulo de Avaliação Pediátrica (TAP) e PTS
- **Avaliação do queimado:** regra dos nove para adulto e criança, com grau por região
- **Triagem START:** algoritmo passo a passo e contagem de vítimas por prioridade
- **Contactos úteis:** linhas de apoio com chamada direta

### Feita para o terreno

- **100 % offline.** A versão de produção não pede permissão de Internet; nada
  sai do dispositivo.
- **Botões grandes**, pensados para usar com luvas.
- **Nada se perde:** as respostas são guardadas a cada toque e sobrevivem ao
  fecho da aplicação. "Novo doente" limpa tudo de uma vez.
- **Modo escuro** automático, para turnos noturnos.

> A aplicação é um auxiliar de cálculo. Não substitui a avaliação clínica nem
> os protocolos em vigor.

## Construída com

[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)

Interface em Material 3, com a paleta original (azul-marinho e cores de
semáforo).

[![Google Play](https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.davidaraujo.ephscores)

## Desenvolvimento

O projeto Flutter está em [`ephscores/`](ephscores).

```sh
cd ephscores
flutter pub get
flutter test          # testes das escalas, START, queimados e interface
flutter run
```

### Estrutura

| Pasta | Conteúdo |
|---|---|
| `lib/scores/` | Definição de cada escala como dados + cálculo (sem dependências de UI) |
| `lib/start/`, `lib/burn/` | Algoritmo START e regra dos nove |
| `lib/ui/` | Ecrãs; um único ecrã genérico desenha qualquer escala |
| `test/` | Testes unitários e de interface |

Para acrescentar uma escala basta criar um `ScoreDefinition` em
`lib/scores/adult.dart` ou `pediatric.dart` e juntá-lo à lista.

### Publicar

Criar `ephscores/android/key.properties` (fora do git) com `storeFile`,
`storePassword`, `keyAlias` e `keyPassword`, e depois:

```sh
flutter build appbundle
```

Sem esse ficheiro, a versão de produção é assinada com a chave de debug.
