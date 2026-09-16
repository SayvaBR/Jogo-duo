import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../game_rules.dart';

class TicPage extends StatefulWidget {
  const TicPage({super.key, required this.onFinish});
  final VoidCallback onFinish;
  @override State<TicPage> createState() => _TicPageState();
}
class _TicPageState extends State<TicPage> {
  List<int> board = List.filled(9, 0);
  int turn = 1, result = 0;
  void put(int index) {
    if (result != 0 || board[index] != 0) return;
    setState(() {
      board[index] = turn;
      result = ticOutcome(board);
      if (result == 0) turn = 3 - turn;
    });
    if (result != 0) widget.onFinish();
  }
  @override Widget build(BuildContext context) => GameFrame(title: 'Jogo da velha', subtitle: 'DOIS JOGADORES · CLÁSSICO', children: [
    StatusBanner(result == 3 ? 'EMPATE!' : result != 0 ? 'JOGADOR $result VENCEU!' : 'VEZ DO JOGADOR $turn · ${turn == 1 ? 'X' : 'O'}', tone: turn == 1 ? cyan : pink),
    AspectRatio(aspectRatio: 1, child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 9, crossAxisSpacing: 9),
      itemBuilder: (context, index) => Semantics(label: 'Casa ${index + 1}', button: true, child: InkWell(onTap: () => put(index), borderRadius: BorderRadius.circular(18), child: Container(alignment: Alignment.center,
        decoration: BoxDecoration(color: panel, border: Border.all(color: const Color(0xFF454B70), width: 2), borderRadius: BorderRadius.circular(18)), child: Text(board[index] == 0 ? '' : board[index] == 1 ? 'X' : 'O', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 56, color: board[index] == 1 ? cyan : pink))))))),
    RestartButton(() => setState(() { board = List.filled(9, 0); turn = 1; result = 0; })),
  ]);
}

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key, required this.onFinish});
  final VoidCallback onFinish;
  @override State<ConnectPage> createState() => _ConnectPageState();
}
class _ConnectPageState extends State<ConnectPage> {
  List<int> board = List.filled(42, 0);
  int turn = 1, result = 0;
  void drop(int col) {
    if (result != 0) return;
    final next = fourDrop(board, col, turn);
    if (next == null) return;
    setState(() { board = next; result = fourOutcome(next); if (result == 0) turn = 3 - turn; });
    if (result != 0) widget.onFinish();
  }
  @override Widget build(BuildContext context) => GameFrame(title: 'Ligue 4', subtitle: 'DOIS JOGADORES · ESTRATÉGIA', children: [
    StatusBanner(result == 3 ? 'EMPATE!' : result != 0 ? 'JOGADOR $result VENCEU!' : 'VEZ DO JOGADOR $turn · TOQUE EM UMA COLUNA', tone: turn == 1 ? cyan : pink),
    AspectRatio(aspectRatio: 7 / 7.15, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF5453D3), borderRadius: BorderRadius.circular(21)), child: Row(children: List.generate(7, (col) => Expanded(child: InkWell(onTap: () => drop(col), child: Column(children: [
      const SizedBox(height: 23, child: Icon(Icons.arrow_drop_down, color: Color(0xFFD6CEFF), size: 20)),
      for (var row = 0; row < 6; row++) Expanded(child: Padding(padding: const EdgeInsets.all(2), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: switch (board[row * 7 + col]) { 1 => cyan, 2 => pink, _ => const Color(0xFF1B2143) }, border: Border.all(color: const Color(0xFF323484), width: 2))))),
    ]))))))),
    const Padding(padding: EdgeInsets.only(top: 13), child: Text('Toque na coluna para soltar sua peça. Quatro em linha vencem!', textAlign: TextAlign.center)),
    RestartButton(() => setState(() { board = List.filled(42, 0); turn = 1; result = 0; })),
  ]);
}

class DotsPage extends StatefulWidget {
  const DotsPage({super.key, required this.onFinish});
  final VoidCallback onFinish;
  @override State<DotsPage> createState() => _DotsPageState();
}
class _DotsPageState extends State<DotsPage> {
  Set<String> edges = {};
  List<int> owners = List.filled(9, 0);
  String? preview, last;
  int turn = 1;
  bool finished = false;
  int get p1 => owners.where((n) => n == 1).length;
  int get p2 => owners.where((n) => n == 2).length;
  String? hit(Offset at, Size size) {
    final span = (size.width - 56) / 3;
    if (span <= 0) return null;
    String? best;
    var distance = span * .43;
    for (var r = 0; r < 4; r++) for (var c = 0; c < 3; c++) {
      final edge = 'h-$r-$c';
      if (edges.contains(edge)) continue;
      final delta = (at - Offset(28 + (c + .5) * span, 28 + r * span)).distance;
      if (delta < distance) { distance = delta; best = edge; }
    }
    for (var r = 0; r < 3; r++) for (var c = 0; c < 4; c++) {
      final edge = 'v-$r-$c';
      if (edges.contains(edge)) continue;
      final delta = (at - Offset(28 + c * span, 28 + (r + .5) * span)).distance;
      if (delta < distance) { distance = delta; best = edge; }
    }
    return best;
  }
  void pick(Offset at, Size size) => setState(() => preview = finished ? null : hit(at, size));
  void commit() {
    final edge = preview;
    if (edge == null || finished || edges.contains(edge)) return;
    final nextEdges = {...edges, edge};
    final result = closeSquares(nextEdges, owners, turn);
    setState(() {
      edges = nextEdges; owners = result.owners; last = edge; preview = null;
      finished = owners.every((owner) => owner != 0);
      if (!finished && result.closed == 0) turn = 3 - turn;
    });
    if (finished) widget.onFinish();
  }
  @override Widget build(BuildContext context) {
    final tone = turn == 1 ? cyan : pink;
    final status = finished ? (p1 == p2 ? 'EMPATE!' : 'JOGADOR ${p1 > p2 ? 1 : 2} VENCEU!') : 'VEZ DO JOGADOR $turn · ${turn == 1 ? 'AZUL' : 'ROSA'}';
    return GameFrame(title: 'Pontos e caixas', subtitle: 'DOIS JOGADORES · ESTRATÉGIA', children: [
      Row(children: [Expanded(child: _DotsScore('JOGADOR 1', p1, cyan, turn == 1 && !finished)), const SizedBox(width: 9), Expanded(child: _DotsScore('JOGADOR 2', p2, pink, turn == 2 && !finished))]),
      const SizedBox(height: 12), StatusBanner(status, tone: tone),
      const Text('ENCOSTE E ARRASTE PARA MIRAR · SOLTE PARA MARCAR', style: TextStyle(color: Color(0xFFC5CBE3), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: .5), textAlign: TextAlign.center),
      const SizedBox(height: 10),
      AspectRatio(aspectRatio: 1, child: LayoutBuilder(builder: (context, bounds) {
        final size = Size(bounds.maxWidth, bounds.maxWidth);
        return GestureDetector(behavior: HitTestBehavior.opaque,
          onTapDown: (details) => pick(details.localPosition, size),
          onTapUp: (_) => commit(),
          onTapCancel: () => setState(() => preview = null),
          onPanStart: (details) => pick(details.localPosition, size),
          onPanUpdate: (details) => pick(details.localPosition, size),
          onPanEnd: (_) => commit(),
          onPanCancel: () => setState(() => preview = null),
          child: CustomPaint(painter: _DotsPainter(edges, owners, preview, last, turn), child: const SizedBox.expand()),
        );
      })),
      const SizedBox(height: 13), const Text('Linha clara = prévia da jogada. Azul e rosa indicam quem marcou cada caixa. Fechou uma caixa? Jogue outra vez!', style: TextStyle(fontSize: 12, color: Color(0xFFAFBAD4), height: 1.5), textAlign: TextAlign.center),
      RestartButton(() => setState(() { edges = {}; owners = List.filled(9, 0); preview = null; last = null; turn = 1; finished = false; })),
    ]);
  }
}
class _DotsScore extends StatelessWidget {
  const _DotsScore(this.name, this.score, this.color, this.active);
  final String name; final int score; final Color color; final bool active;
  @override Widget build(BuildContext context) => AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: active ? color : const Color(0xFF454B67), width: active ? 3 : 1)), child: Row(children: [Icon(Icons.circle, color: color, size: 12), const SizedBox(width: 6), Expanded(child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))), Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22))]));
}
class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.edges, this.owners, this.preview, this.last, this.turn);
  final Set<String> edges; final List<int> owners; final String? preview, last; final int turn;
  @override void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(23)), Paint()..color = const Color(0xFF17213D));
    final s = (size.width - 56) / 3;
    final outer = Rect.fromLTWH(22, 22, size.width - 44, size.height - 44);
    canvas.drawRRect(RRect.fromRectAndRadius(outer, const Radius.circular(9)), Paint()..color = const Color(0xFF1C2D4D));
    for (var r = 0; r < 3; r++) for (var c = 0; c < 3; c++) {
      final owner = owners[r * 3 + c];
      if (owner == 0) continue;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(28 + c * s + 7, 28 + r * s + 7, s - 14, s - 14), const Radius.circular(11)), Paint()..color = (owner == 1 ? cyan : pink).withValues(alpha: .30));
      final text = TextPainter(text: TextSpan(text: owner == 1 ? '★' : '♥', style: TextStyle(color: owner == 1 ? cyan : pink, fontSize: s * .36, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
      text.paint(canvas, Offset(28 + (c + .5) * s - text.width / 2, 28 + (r + .5) * s - text.height / 2));
    }
    void line(String key, Offset a, Offset b) {
      final played = edges.contains(key), hovered = key == preview;
      final color = hovered ? (turn == 1 ? cyan : pink) : played ? (key == last ? gold : const Color(0xFFC4B7FF)) : const Color(0xFF3D4D6A);
      canvas.drawLine(a, b, Paint()..color = color..strokeWidth = hovered ? 13 : played ? 11 : 9..strokeCap = StrokeCap.round);
      if (hovered) canvas.drawLine(a, b, Paint()..color = Colors.white.withValues(alpha: .7)..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
    for (var r = 0; r < 4; r++) for (var c = 0; c < 3; c++) line('h-$r-$c', Offset(28 + c * s, 28 + r * s), Offset(28 + (c + 1) * s, 28 + r * s));
    for (var r = 0; r < 3; r++) for (var c = 0; c < 4; c++) line('v-$r-$c', Offset(28 + c * s, 28 + r * s), Offset(28 + c * s, 28 + (r + 1) * s));
    for (var r = 0; r < 4; r++) for (var c = 0; c < 4; c++) {
      final dot = Offset(28 + c * s, 28 + r * s);
      canvas.drawCircle(dot, 10, Paint()..color = const Color(0xFF10162B));
      canvas.drawCircle(dot, 7, Paint()..color = const Color(0xFFE7E2FF));
    }
  }
  @override bool shouldRepaint(_DotsPainter old) => old.edges != edges || old.preview != preview || old.last != last || old.turn != turn || old.owners != owners;
}

const _emoji = ['🍉', '🚀', '👾', '🎲', '⭐', '🐸', '⚡', '🎧'];
class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key, required this.onFinish}); final VoidCallback onFinish;
  @override State<MemoryPage> createState() => _MemoryPageState();
}
class _MemoryPageState extends State<MemoryPage> {
  late List<String> deck = _shuffle();
  List<int> open = [];
  Set<int> matched = {};
  int turn = 1, a = 0, b = 0, generation = 0;
  bool locked = false;
  List<String> _shuffle() => [..._emoji, ..._emoji]..shuffle(Random());
  void pick(int index) {
    if (locked || matched.contains(index) || open.contains(index) || matched.length == 16) return;
    if (open.isEmpty) { setState(() => open = [index]); return; }
    final previous = open.first;
    if (deck[previous] == deck[index]) {
      setState(() { matched.addAll([previous, index]); open = []; if (turn == 1) { a++; } else { b++; } });
      if (matched.length == 16) widget.onFinish();
    } else {
      final currentGeneration = generation;
      setState(() { open = [previous, index]; locked = true; });
      Future<void>.delayed(const Duration(milliseconds: 950), () {
        if (!mounted || currentGeneration != generation) return;
        setState(() { open = []; locked = false; turn = 3 - turn; });
      });
    }
  }
  void restart() => setState(() { generation++; deck = _shuffle(); open = []; matched = {}; a = 0; b = 0; turn = 1; locked = false; });
  @override Widget build(BuildContext context) => GameFrame(title: 'Memória dupla', subtitle: 'DOIS JOGADORES · CONCENTRAÇÃO', children: [
    StatusBanner(matched.length == 16 ? (a == b ? 'EMPATE!' : 'JOGADOR ${a > b ? 1 : 2} VENCEU!') : 'VEZ DO JOGADOR $turn · PARES $a × $b', tone: turn == 1 ? cyan : pink),
    AspectRatio(aspectRatio: 1, child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemBuilder: (context, i) => Semantics(label: 'Carta ${i + 1}', button: true, child: InkWell(onTap: () => pick(i), child: Container(alignment: Alignment.center, decoration: BoxDecoration(color: matched.contains(i) ? const Color(0xFF295344) : open.contains(i) ? const Color(0xFFF1E9FF) : const Color(0xFF352A55), borderRadius: BorderRadius.circular(13), border: Border.all(color: violet, width: 1.5)), child: Text(open.contains(i) || matched.contains(i) ? deck[i] : '✦', style: TextStyle(fontSize: 31, color: open.contains(i) ? bg : violet))))))),
    const Padding(padding: EdgeInsets.only(top: 14), child: Text('Encontre os pares. Quem acerta ganha um ponto e joga outra vez.', textAlign: TextAlign.center)),
    RestartButton(restart),
  ]);
}

class RpsPage extends StatefulWidget {
  const RpsPage({super.key, required this.onFinish}); final VoidCallback onFinish;
  @override State<RpsPage> createState() => _RpsPageState();
}
class _RpsPageState extends State<RpsPage> {
  String stage = 'first';
  int? one, two;
  int a = 0, b = 0;
  static const names = ['Pedra', 'Papel', 'Tesoura'];
  static const icons = ['✊', '✋', '✌️'];
  void choose(int index) {
    if (stage == 'first') { setState(() { one = index; stage = 'pass'; }); return; }
    if (stage != 'second' || one == null) return;
    setState(() { two = index; stage = 'result'; if (one != index) { if ((one! + 1) % 3 == index) { b++; } else { a++; } } });
    widget.onFinish();
  }
  @override Widget build(BuildContext context) {
    final result = stage == 'result' ? one == two ? 'EMPATE!' : 'JOGADOR ${(one! + 1) % 3 == two ? 2 : 1} VENCEU!' : '';
    return GameFrame(title: 'Pedra, papel, tesoura', subtitle: 'DOIS JOGADORES · SEGREDO', children: [
      StatusBanner('PLACAR · JOGADOR 1  $a  ×  $b  JOGADOR 2'),
      if (stage == 'pass') ...[
        const SizedBox(height: 35), const Icon(Icons.visibility_off, size: 64, color: violet),
        const SizedBox(height: 18), const Text('Escolha guardada!', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 15), const Text('Passe o celular ao jogador 2. A escolha anterior está escondida.', textAlign: TextAlign.center),
        const SizedBox(height: 30), FilledButton(onPressed: () => setState(() => stage = 'second'), child: const Text('Sou o jogador 2 →')),
      ] else if (stage == 'result') ...[
        const SizedBox(height: 34), Text('${icons[one!]}  ×  ${icons[two!]}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 53)),
        const SizedBox(height: 18), Text(result, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8), Text('${names[one!]} contra ${names[two!]}', textAlign: TextAlign.center),
        RestartButton(() => setState(() { one = null; two = null; stage = 'first'; }), label: 'Próxima rodada'),
      ] else ...[
        StatusBanner('JOGADOR ${stage == 'first' ? 1 : 2} · ESCOLHA SUA JOGADA', tone: stage == 'first' ? cyan : pink),
        const Text('O adversário não verá sua escolha até ambos jogarem.', textAlign: TextAlign.center),
        const SizedBox(height: 22), ...List.generate(3, (i) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: FilledButton.tonal(onPressed: () => choose(i), child: Padding(padding: const EdgeInsets.all(10), child: Text('${icons[i]}  ${names[i]}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))))),
      ],
      const SizedBox(height: 20), const Text('Pedra vence tesoura · Tesoura vence papel · Papel vence pedra', style: TextStyle(color: Color(0xFFAAB6D3)), textAlign: TextAlign.center),
    ]);
  }
}

class SudokuPage extends StatefulWidget {
  const SudokuPage({super.key, required this.onFinish}); final VoidCallback onFinish;
  @override State<SudokuPage> createState() => _SudokuPageState();
}
class _SudokuPageState extends State<SudokuPage> {
  late SudokuPuzzle puzzle = newSudoku();
  late List<int> board = List.of(puzzle.start);
  int selected = -1;
  bool solved = false;
  void write(int n) {
    if (selected < 0 || puzzle.start[selected] != 0 || solved) return;
    setState(() { board[selected] = n; solved = board.every((v) => v != 0) && List.generate(81, (i) => i).every((i) => board[i] == puzzle.solution[i]); });
    if (solved) widget.onFinish();
  }
  @override Widget build(BuildContext context) => GameFrame(title: 'Sudoku', subtitle: 'SOLO · RACIOCÍNIO', children: [
    StatusBanner(solved ? 'PARABÉNS! VOCÊ RESOLVEU O SUDOKU!' : 'PREENCHA OS NÚMEROS DE 1 A 9', tone: cyan),
    AspectRatio(aspectRatio: 1, child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 81,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
      itemBuilder: (context, i) {
        final conflicts = sudokuConflicts(board, i).isNotEmpty;
        final fixed = puzzle.start[i] != 0;
        final color = i == selected ? const Color(0xFF554793) : conflicts ? const Color(0xFF61304B) : fixed ? const Color(0xFF252B48) : const Color(0xFF1B2239);
        return InkWell(onTap: () => setState(() => selected = i), child: Container(alignment: Alignment.center,
          decoration: BoxDecoration(color: color, border: Border(left: BorderSide(color: violet, width: i % 9 % 3 == 0 ? 2 : .4), top: BorderSide(color: violet, width: i ~/ 9 % 3 == 0 ? 2 : .4), right: BorderSide(color: violet, width: i % 9 == 8 ? 2 : .4), bottom: BorderSide(color: violet, width: i ~/ 9 == 8 ? 2 : .4))),
          child: Text(board[i] == 0 ? '' : '${board[i]}', style: TextStyle(color: fixed ? Colors.white : cyan, fontSize: 17, fontWeight: FontWeight.w800))));
      })),
    const SizedBox(height: 15), Wrap(alignment: WrapAlignment.center, spacing: 7, runSpacing: 9, children: [for (var i = 1; i <= 9; i++) SizedBox(width: 55, height: 49, child: FilledButton.tonal(onPressed: () => write(i), style: FilledButton.styleFrom(padding: EdgeInsets.zero), child: Text('$i', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)))), SizedBox(width: 100, height: 49, child: OutlinedButton(onPressed: () => write(0), child: const Text('Apagar')))]),
    const SizedBox(height: 12), const Text('Escolha uma casa vazia, depois um número. Casas vermelhas indicam conflitos.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFAFBCD1), fontSize: 12)),
    RestartButton(() => setState(() { puzzle = newSudoku(); board = List.of(puzzle.start); selected = -1; solved = false; }), label: 'Novo desafio'),
  ]);
}
