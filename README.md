# 🎮 Jogo Duo

**Oito minijogos locais para Android — um só aparelho, sem internet ou cadastro.** Projeto original em React 19, TypeScript, Vite e Capacitor 7. As partidas e os controles são executados no próprio dispositivo; não existe backend nem serviço multiplayer remoto.

## Jogos implementados

| Jogo | Participantes | Recursos |
| --- | --- | --- |
| Air Rocket | 2 simultâneos | Dois ponteiros independentes, mesa dividida, colisões, gols, placar, pausa, reinício, vitória aos 7 |
| Ludo | 2–4 alternando | Quatro peças por jogador, saída com 6, casas seguras, captura, pista exclusiva, chegada exata e vitória |
| Jogo da velha | 2 alternando | Regras, empate, vitórias e rematch |
| Ligue 4 | 2 alternando | Gravidade das peças, todas as direções de vitória, empate e rematch |
| Pontos e caixas | 2 alternando | 3×3 caixas, pontos, rodada extra ao fechar caixa, vencedor |
| Memória dupla | 2 alternando | 8 pares, rodadas, pontuação, revele duas cartas e jogue novamente se acertar |
| Pedra, papel, tesoura | 2 alternando | Escolhas secretas, passagem segura do celular, placar e rematch |
| Sudoku | 1 | Puzzles offline por permutações de um problema de solução única, notas, conflitos, 3 dicas, correção, novos desafios |

**Escopo intencional:** multiplayer local significa jogar no *mesmo telefone*. Não há Wi-Fi, Bluetooth, login, anúncios, permissões de rede solicitadas pelo app ou servidores. O Sudoku é o modo solo. As oito opções na home são jogáveis, não telas de demonstração. Os resultados concluídos são armazenados localmente no navegador/WebView.

## Rodar e testar

Requisitos: Node.js 22+, npm, Android SDK com Android Studio e JDK 21 para o APK.

```bash
npm install
npm test
npm run dev
npm run build
```

Para Android pela primeira vez:

```bash
npm run android:init
cd android
./gradlew assembleDebug
```

Nas compilações seguintes: `npm run android:sync` e `cd android && ./gradlew assembleDebug`. O APK debug aparece em `android/app/build/outputs/apk/debug/app-debug.apk`. O diretório `android/` é gerado pelo Capacitor e ignorado no Git; a CI recria-o para cada execução. **APK debug não é pacote assinado de lançamento para Google Play.** Lançamento requer revisão no dispositivo, ícones definitivos, política de privacidade adequada, geração de AAB assinado e ficha da loja.

### GitHub Actions

`.github/workflows/android.yml` roda testes, checagem TypeScript, compilação web e compilação Android, publica um artefato `jogo-duo-debug-apk` se todos os passos passarem. Vá até **Actions → Test and build Android debug APK → execução → Artifacts**. Não há APK disponível até que uma execução conclua com sucesso.

## Arquitetura e manutenção

`src/engine.ts` concentra regras puras testáveis de Ludo, jogo da velha, Ligue 4 e Sudoku; `src/engine.test.ts` cobre legalidade de movimentos, vitórias, capturas e puzzles. Componentes individuais ficam em `src/BoardGames.tsx`, `src/Ludo.tsx`, `src/Sudoku.tsx`, `src/PartyGames.tsx` e `src/AirHockey.tsx`. `src/App.tsx` mantém catálogo, navegação e contagem local de partidas; `src/styles.css` contém o design responsivo e padding para as áreas seguras. O Air Rocket usa um canvas com Pointer Events, inclusive `pointerId` independentes para dois toques simultâneos, sem rede.

### Regras configuradas de Ludo

Modo de dois jogadores usa cores opostas; também são oferecidos três e quatro jogadores. Cada peça percorre a pista de 52 casas, sai com seis, entra em cinco casas de pista final individual e termina com passo exato 56. Casas iniciais e casas estrelas são seguras. Captura em casa comum devolve a peça adversária à base e concede nova jogada. Três seis consecutivos perdem a vez. É uma variante explícita de regras (o Ludo tem variantes regionais).

## Referências de pesquisa, licenças e autoria

Foram consultados como **referências**, sem copiar código nem assets: [airhockey de Lazy Squirrel Labs](https://github.com/lazysquirrellabs/airhockey) (código MIT; assets CC BY 4.0); [avirati/ludo](https://github.com/avirati/ludo) (MIT); [robatron/sudoku.js](https://github.com/robatron/sudoku.js) (MIT); e discussões de jogos no mesmo aparelho em [r/AndroidGaming](https://www.reddit.com/r/AndroidGaming/comments/ost7ow/) e [r/localmultiplayergames](https://www.reddit.com/r/localmultiplayergames/comments/1u5eiwk/). A solução aqui usa implementação própria e não incorpora esses repositórios. O nome **Air Rocket** no app é usado para o minijogo original de disco e rebatedores inspirado no gênero Air Hockey, não para afirmar afiliação a um título de terceiro.

Copyright © 2026 SayvaBR. Código original disponibilizado sob a licença MIT no arquivo `LICENSE`.
