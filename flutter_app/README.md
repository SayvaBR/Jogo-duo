# Jogo Duo — Android com Flutter + Flame

Esta é a nova implementação do Jogo Duo para Android. Flutter implementa a interface e os tabuleiros; Flame executa o ciclo de atualização dos jogos com física Air Rocket e Sinuca. Não usa WebView, React ou Capacitor nesta versão.

## Jogos

Nove jogos locais/offline: Air Rocket, Sinuca bola 8, Ludo (2–4 jogadores, dados combinados opcionais), Jogo da Velha, Ligue 4, Pontos e Caixas (16 caixas, tabuleiro maior, prévia da linha, último lance destacado), Memória Dupla, Pedra/Papel/Tesoura com escolhas secretas e Sudoku com notas e dicas.

## Gerar o APK Android

Requisitos: Flutter estável, Android SDK e JDK. Entre na pasta `flutter_app`:

```bash
flutter create --platforms=android --org com.sayvabr --project-name jogo_duo --no-pub .
python3 tool/normalize_sources.py
flutter pub get
flutter test test/game_logic_test.dart
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build apk --debug
```

**Importante:** `tool/normalize_sources.py` é uma normalização temporária e idempotente da primeira migração dos arquivos Dart. Execute-a uma vez em um checkout novo antes de compilar; o workflow executa a mesma etapa automaticamente. O próximo trabalho de manutenção é incorporar essas correções diretamente nos arquivos Dart e eliminar esse bootstrap.

APK: `build/app/outputs/flutter-apk/app-debug.apk`. A execução `Flutter Android - Jogo Duo` publica o artefato `jogo-duo-flutter-debug-apk`; o build e os testes foram validados no GitHub Actions. O antigo aplicativo React permanece na raiz e não é usado por este APK. A identificação Android Flutter é `com.sayvabr.jogo_duo`, separada da versão anterior para instalar as duas lado a lado.

**Escopo atual:** física de colisão escrita em Dart no loop Flame (sem Forge2D), APK de depuração para teste. Não é versão de publicação na Play Store: ainda precisa ser avaliada em dispositivo físico, ter os fluxos completos das partidas verificados e receber assinatura de lançamento, testes de acessibilidade e acabamento visual.
