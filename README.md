# 🎮 Jogo Duo — Flutter Android

**Nove minijogos offline para Android, feitos para jogar no mesmo celular.** A versão principal agora é **Flutter + Flame em Dart**, sem React, WebView ou Capacitor dentro do novo APK. Flutter implementa interfaces e tabuleiros; Flame implementa o loop de física/renderização de Sinuca e Air Rocket. A física da Sinuca foi portada do motor próprio anterior; Forge2D não foi adicionado ainda, pois trocar a física exige validação específica.

## Jogos

| Jogo | Jogadores | Principais recursos |
| --- | --- | --- |
| Air Rocket | 2 simultâneos | Multitoque, física do disco, gols, placar e pausa |
| Ludo | 2–4 alternados | Casas seguras, capturas, 6 extras, dados combinados opcionais, peões casa a casa |
| Sinuca | 2 alternados | Bola 8, mira e força, colisões, caçapas, falta, bola na mão e vitória |
| Jogo da velha | 2 | Regras, empate, vitória e revanche |
| Ligue 4 | 2 | Gravidade, vitória horizontal, vertical e diagonal |
| Pontos e caixas | 2 | Tabuleiro maior, prévia de linha ao tocar, última jogada e cores por jogador |
| Memória dupla | 2 | Oito pares, turnos, pontuação e vitória |
| Pedra, papel, tesoura | 2 | Escolha secreta, passagem do aparelho e placar |
| Sudoku | 1 | Puzzle offline, validação de conflitos e novos desafios |

O aplicativo não possui cadastro, multiplayer remoto, anúncios, pagamentos ou dependência de servidor. O resultado das partidas concluídas fica no armazenamento local do Android.

## Desenvolver e gerar APK

```bash
cd flutter_app
flutter create --platforms=android --project-name=jogo_duo --org=br.sayva .
rm -f test/widget_test.dart # remove teste de demonstração criado pela CLI
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run
flutter build apk --debug
```

O APK estará em `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`. O workflow **Flutter Android · tests and APK** (`.github/workflows/flutter-android.yml`) também executa testes e gera o artefato `jogo-duo-flutter-android-apk` automaticamente. Requer Flutter SDK estável, Java e Android SDK. O projeto nativo `flutter_app/android/` é reproduzido pela própria CLI Flutter em cada build e não usa Capacitor.

## Versão anterior / segurança da migração

Os arquivos `src/`, `package.json`, `index.html` e afins na raiz contêm a versão React/Capacitor **preservada apenas para consulta e rollback**; não são compilados nem incluídos no APK Flutter. O workflow antigo `.github/workflows/android.yml` foi restringido à execução manual. Desenvolvimento novo acontece em `flutter_app/`.

**Aviso de qualidade:** testes de Dart, análise estática e build Android garantem apenas esses critérios técnicos. Multitoque real, física e usabilidade devem ser conferidos num celular. O APK debug não é publicação na Play Store; release necessita chave de assinatura, pacote AAB, identidade visual e QA final.

Copyright © 2026 SayvaBR. Consulte `LICENSE`.
