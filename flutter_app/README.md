# Jogo Duo — Flutter Android

Este é o aplicativo **nativo em Flutter**, não uma WebView nem um pacote Capacitor. Os nove jogos do catálogo estão implementados em Dart. Flutter cuida dos controles, tabuleiros e navegação Android; Flame executa o loop de jogo e a renderização de Sinuca e Air Rocket. A Sinuca mantém, por enquanto, a simulação própria de colisões e regras da versão anterior, reescrita em Dart; **Forge2D ainda não está integrado**, para evitar reintroduzir outra física sem validação das regras.

## Executar

Requer Flutter SDK estável, Android SDK, JDK e um dispositivo/emulador Android:

```sh
cd flutter_app
flutter create --platforms=android --project-name=jogo_duo --org=br.sayva .
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run
flutter build apk --debug
```

O APK é gerado em `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`. O workflow `.github/workflows/flutter-android.yml` executa esses passos e publica o artefato `jogo-duo-flutter-android-apk`. O diretório nativo `android/` é gerado pelo Flutter, **não pelo Capacitor**. O antigo projeto React foi preservado na raiz apenas como referência da migração e rollback; não faz parte do APK Flutter.

## Jogos e regras

- Air Rocket: dois jogadores simultâneos, entrada multitoque, primeiro a sete gols.
- Ludo: 2–4, casas seguras, capturas, chegada exata, três seis; modo opcional de dados combinados; peões se movem casa a casa e o dado não voa sobre o tabuleiro.
- Sinuca: bola 8, colisões e atrito, seis caçapas, grupos lisas/listradas, faltas e bola na mão.
- Jogo da velha, Ligue 4, Pontos e caixas, Memória dupla, Pedra/papel/tesoura e Sudoku também foram portados. Pontos e caixas usa quase toda a largura da tela e sinaliza prévia da aresta, última jogada, turno e propriedade de cada caixa.

Os testes automatizados verificam regras puras e casos da Sinuca. **Um build e testes aprovados não substituem uma rodada de QA em dispositivo físico**, sobretudo em multitoque, responsividade e precisão da física. O APK debug serve apenas para testes; publicação na Play Store requer configurar assinatura de release e gerar AAB.
