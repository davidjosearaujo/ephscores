# EPHScores: desenvolvimento

Projeto Flutter da aplicação. Os comandos abaixo correm a partir desta pasta.

```sh
flutter pub get
flutter test          # testes das escalas, START, queimados e interface
flutter run
```

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `lib/scores/` | Definição de cada escala como dados + cálculo (sem dependências de UI) |
| `lib/patient/` | Doente, avaliações registadas e resumo em texto |
| `lib/start/`, `lib/burn/` | Algoritmo START e regra dos nove |
| `lib/ui/` | Ecrãs; um único ecrã genérico desenha qualquer escala |
| `web/`, `scripts/` | PWA: manifesto, service worker e script de build |
| `test/` | Testes unitários e de interface |
| [`../docs/design/`](../docs/design) | Identidade visual: logótipo, cores, regras, conceitos e material antigo |
| [`../docs/reference/`](../docs/reference) | Material de referência clínica |

Para acrescentar uma escala basta criar um `ScoreDefinition` em
`lib/scores/adult.dart` ou `pediatric.dart` e juntá-lo à lista.

## Logótipo e ícones

Há uma única fonte: `assets/brand/logo.svg` (um emblema hexagonal
azul-marinho com a estrela da vida, cujos três braços superiores são verde,
amarelo e vermelho, as cores das escalas). A aplicação desenha o logótipo
a partir desse ficheiro, e todos os ícones (Android, iPhone/PWA, favicon,
loja) são gerados dele:

```sh
cd scripts/icons && npm install && npm run generate && npm run docs
cd ../.. && dart run flutter_launcher_icons
```

O logótipo, as cores, a tipografia e as regras de utilização estão descritos
em [`docs/design/identidade.md`](../docs/design/identidade.md), com a
pré-visualização de cada ícone. As cores do SVG são procuradas por valor
(`Palette` em `lib/theme.dart`); um teste garante que continuam iguais.

## Compilar tudo (APK + web)

```sh
scripts/build_all.sh                # analisa, testa e gera o APK e a web (PWA)
scripts/build_all.sh all            # também gera o app bundle (.aab)
scripts/build_all.sh --skip-tests --split apk   # só o APK, um por arquitetura
scripts/build_all.sh --deploy       # APK + web e publica a web (iPhone) no Firebase
```

Com `--deploy`, a versão web é publicada no Firebase Hosting depois de
compilada, e uma só chamada lança as duas versões (Android e iPhone). Precisa
do Firebase CLI (`npm install -g firebase-tools` e `firebase login`).

Os ficheiros Android ficam em `dist/` (com a versão no nome) e a web em
`build/web`. Precisa do Flutter no `PATH` e, para o Android, do Android SDK
(`flutter doctor` indica o que falta). No Windows, usar o Git Bash ou o WSL.
Sem `android/key.properties`, o Android é assinado com a chave de debug:
serve para testar, mas não atualiza a versão da Google Play.

## Publicar a versão web (PWA)

```sh
scripts/build_all.sh web --deploy      # testa, compila e publica
# ou, passo a passo:
scripts/build_web.sh                   # build em build/web, com cache offline (sw.js)
firebase deploy --only hosting
```

O `firebase.json` e o `.firebaserc` já estão configurados; basta ter o
Firebase CLI e fazer `firebase login`.

A build inclui o motor gráfico e as fontes, sem depender de CDNs. Cada build
gera uma nova versão da cache, e os utilizadores recebem a atualização na
abertura seguinte.

## Publicar no Google Play

Criar `android/key.properties` (fora do git) com `storeFile`,
`storePassword`, `keyAlias` e `keyPassword`, e depois:

```sh
flutter build appbundle
```

Sem esse ficheiro, a versão de produção é assinada com a chave de debug.
