# Jogo Duo — Android nativo com Flutter + Flame

Esta é a implementação do Jogo Duo para Android feita com Flutter (telas, controles e tabuleiros) + Flame (game loop dos jogos com física Air Rocket e Sinuca). Não carrega HTML nem utiliza React, Capacitor ou WebView.

## Jogável

Nove jogos no mesmo celular, completamente offline: Air Rocket, Sinuca bola 8, Ludo de 2 a 4 pessoas com opção de dados combinados, Jogo da Velha, Ligue 4, Pontos e Caixas ampliado para 4×4 caixas com linha candidata e última jogada destacadas, Memória Dupla, Pedra/Papel/Tesoura com escolhas secretas e Sudoku com notas e três dicas.

## Desenvolvimento

Requer Flutter estável e Android SDK. Na pasta `flutter_app`:

```bash
flutter create --platforms=android --org com.sayvabr --project-name jogo_duo .
flutter pub get
flutter test test/game_logic_test.dart
flutter build apk --debug
```

O APK fica em `build/app/outputs/flutter-apk/app-debug.apk`. O workflow `Flutter Android - Jogo Duo` repete esses passos e publica o artefato `jogo-duo-flutter-debug-apk` a cada alteração Flutter na branch main. O aplicativo React anterior continua isolado na raiz até a substituição ser validada no aparelho. O package ID Flutter `com.sayvabr.jogo_duo` é diferente do legado, permitindo testes lado a lado.

**Limites:** física de colisão feita em Dart dentro do game loop Flame, sem Forge2D por enquanto; a seleção automática de dificuldade e efeitos sonoros não foram migrados. Não declarar pronto para loja antes de testes no hardware, revisão de acessibilidade, assinatura de release e verificação das regras das partidas completas.
