import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';

const ludoColors = [pink, violet, mint, gold];
const ludoNames = ['CORAL', 'ROXO', 'VERDE', 'AMARELO'];
const starts = [0, 13, 26, 39];
const safeTiles = {0, 8, 13, 21, 26, 34, 39, 47};
const track = <(int, int)>[
  (6,13),(6,12),(6,11),(6,10),(6,9),(5,8),(4,8),(3,8),(2,8),(1,8),(0,8),(0,7),(0,6),
  (1,6),(2,6),(3,6),(4,6),(5,6),(6,5),(6,4),(6,3),(6,2),(6,1),(6,0),(7,0),(8,0),
  (8,1),(8,2),(8,3),(8,4),(8,5),(9,6),(10,6),(11,6),(12,6),(13,6),(14,6),(14,7),(14,8),
  (13,8),(12,8),(11,8),(10,8),(9,8),(8,9),(8,10),(8,11),(8,12),(8,13),(8,14),(7,14),(6,14),
];
const lanes = <List<(int, int)>>[
  [(7,13),(7,12),(7,11),(7,10),(7,9)],
  [(1,7),(2,7),(3,7),(4,7),(5,7)],
  [(7,1),(7,2),(7,3),(7,4),(7,5)],
  [(13,7),(12,7),(11,7),(10,7),(9,7)],
];
const yards = <List<(int, int)>>[
  [(1,10),(4,10),(1,13),(4,13)],
  [(1,1),(4,1),(1,4),(4,4)],
  [(10,1),(13,1),(10,4),(13,4)],
  [(10,10),(13,10),(10,13),(13,13)],
];
(int, int) pawnCell(int player, int progress, int token) {
  if (progress == -1) return yards[player][token];
  if (progress == 56) return (7,7);
  if (progress >= 51) return lanes[player][progress - 51];
  return track[(starts[player] + progress) % 52];
}

class LudoMatch {
  LudoMatch(int count) : players = count == 2 ? [0, 2] : count == 3 ? [0, 1, 2] : [0, 1, 2, 3];
  final List<int> players;
  final tokens = List.generate(4, (_) => List.filled(4, -1));
  int current = 0, sixes = 0;
  int? die, banked, winner;
  String phase = 'roll';
  bool combined = false, extraAfterCombo = false, captureBonus = false;
  String message = 'Toque em LANÇAR DADO para começar.';
  List<int> get options {
    if (phase != 'move' || die == null) return [];
    return [for (var i = 0; i < 4; i++) if (tokens[current][i] != 56 &&
      (tokens[current][i] == -1 ? die == 6 : tokens[current][i] + die! <= 56)) i];
  }
  bool get canBank => phase == 'move' && die == 6 && !combined && banked == null &&
    tokens[current].where((p) => p >= 0 && p < 56).length >= 2;
  void clearCombo() { banked = null; combined = false; extraAfterCombo = false; captureBonus = false; }
  void next([String? note]) {
    current = players[(players.indexOf(current) + 1) % players.length];
    die = null; sixes = 0; phase = 'roll'; clearCombo();
    message = note ?? 'Vez do próximo jogador.';
  }
  void roll(int value) {
    if (phase != 'roll' || value < 1 || value > 6) return;
    if (combined && banked != null) {
      if (value == 6 && sixes == 2) { next('Três seis seguidos: perdeu a vez e os dados guardados.'); return; }
      die = banked; banked = value; phase = 'move';
      sixes = value == 6 ? sixes + 1 : 0; extraAfterCombo = value == 6;
      message = 'Dados: 6 e $value. Escolha a ordem e depois a peça.';
      if (options.isEmpty) { swapDice(); if (options.isEmpty) _finishCombo('Sem jogadas possíveis para os dois dados.'); }
      return;
    }
    if (value == 6 && sixes == 2) { next('Três seis seguidos: perdeu a vez!'); return; }
    die = value; sixes = value == 6 ? sixes + 1 : 0; phase = 'move';
    message = 'Saiu $value. Escolha uma peça.';
    if (options.isEmpty) {
      if (value == 6) { die = null; phase = 'roll'; message = 'Saiu 6: lance novamente.'; }
      else next('Saiu $value; sem jogadas possíveis. Próxima vez.');
    }
  }
  void saveSix() {
    if (!canBank) return;
    die = null; banked = 6; combined = true; phase = 'roll';
    message = '6 guardado! Lance de novo, depois distribua os valores.';
  }
  void swapDice() {
    if (!combined || phase != 'move' || die == null || banked == null) return;
    final temp = die; die = banked; banked = temp;
    message = 'Dado $die selecionado. Escolha a peça.';
  }
  void _finishCombo(String note) {
    if (extraAfterCombo || captureBonus) {
      die = null; phase = 'roll'; message = '$note ${extraAfterCombo ? 'Segundo 6: nova jogada.' : 'Captura: nova jogada.'}'; clearCombo();
    } else { next('$note Próximo jogador.'); }
  }
  bool move(int token) {
    if (!options.contains(token) || die == null) return false;
    final used = die!;
    final previous = tokens[current][token];
    final progress = previous == -1 ? 0 : previous + used;
    tokens[current][token] = progress;
    var captured = false;
    if (progress <= 50) {
      final landed = (starts[current] + progress) % 52;
      if (!safeTiles.contains(landed)) for (final enemy in players) {
        if (enemy == current) continue;
        for (var i = 0; i < 4; i++) {
          final position = tokens[enemy][i];
          if (position >= 0 && position <= 50 && (starts[enemy] + position) % 52 == landed) {
            tokens[enemy][i] = -1; captured = true;
          }
        }
      }
    }
    if (tokens[current].every((p) => p == 56)) {
      winner = current; die = null; phase = 'done'; clearCombo(); message = '${ludoNames[current]} venceu!'; return true;
    }
    if (combined) {
      captureBonus = captureBonus || captured;
      if (banked != null) {
        die = banked; banked = null; phase = 'move';
        message = 'Primeiro movimento concluído! Use agora o dado $die.';
        if (options.isEmpty) _finishCombo('Não há jogada possível para o dado $die.');
      } else { _finishCombo(captured ? 'Você capturou uma peça!' : 'Os dois dados foram utilizados.'); }
    } else if (used == 6 || captured) {
      die = null; phase = 'roll'; message = captured ? 'Capturou! Lance novamente.' : 'Seis! Lance novamente.';
    } else { next(progress == 56 ? 'Peça chegou ao centro! Próximo jogador.' : 'Peça movida. Próximo jogador.'); }
    return true;
  }
}

class _LudoPainter extends CustomPainter {
  const _LudoPainter(this.match, this.visual, this.moving);
  final LudoMatch match; final List<List<int>> visual; final bool moving;
  @override void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)), Paint()..color = Colors.white);
    for (var r = 0; r < 15; r++) for (var c = 0; c < 15; c++) {
      var color = Colors.white;
      final trackIndex = track.indexOf((c,r));
      final lane = lanes.indexWhere((path) => path.contains((c,r)));
      final start = starts.indexOf(trackIndex);
      if (trackIndex >= 0) color = start >= 0 ? ludoColors[start] : safeTiles.contains(trackIndex) ? const Color(0xFFE9DEFF) : const Color(0xFFF5F4FF);
      else if (lane >= 0) color = ludoColors[lane];
      else if (c >= 6 && c <= 8 && r >= 6 && r <= 8) color = const Color(0xFF27223F);
      else if (c < 6 && r > 8) color = const Color(0xFFFFE1E8);
      else if (c < 6 && r < 6) color = const Color(0xFFEAE2FF);
      else if (c > 8 && r < 6) color = const Color(0xFFD5F9E7);
      else if (c > 8 && r > 8) color = const Color(0xFFFFF0CA);
      final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
      canvas.drawRect(rect, Paint()..color = color);
      canvas.drawRect(rect, Paint()..color = const Color(0xFF363853).withValues(alpha: .25)..style = PaintingStyle.stroke..strokeWidth = .7);
      if (safeTiles.contains(trackIndex)) {
        final star = TextPainter(text: const TextSpan(text: '★', style: TextStyle(color: Color(0xFF72609F), fontSize: 11)), textDirection: TextDirection.ltr)..layout();
        star.paint(canvas, rect.center - Offset(star.width / 2, star.height / 2));
      }
    }
    final available = moving ? <int>[] : match.options;
    if (match.phase == 'move') for (final index in available) {
      final current = match.tokens[match.current][index];
      final target = current == -1 ? 0 : current + match.die!;
      final spot = pawnCell(match.current, target, index);
      canvas.drawCircle(Offset((spot.$1 + .5) * cell, (spot.$2 + .5) * cell), cell * .43, Paint()..color = ludoColors[match.current]..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    final clusters = <(int,int), int>{};
    for (final player in match.players) for (var i = 0; i < 4; i++) {
      final position = visual[player][i];
      final spot = pawnCell(player, position, i);
      final key = (spot.$1, spot.$2);
      final slot = clusters[key] ?? 0;
      clusters[key] = slot + 1;
      final dx = slot % 2 == 0 ? -.17 : .17;
      final dy = slot < 2 ? -.17 : .17;
      final center = Offset((spot.$1 + .5 + dx) * cell, (spot.$2 + .5 + dy) * cell);
      final radius = cell * .34;
      canvas.drawCircle(center + const Offset(0, 2), radius + 1, Paint()..color = const Color(0x77060A13));
      canvas.drawCircle(center, radius, Paint()..color = ludoColors[player]);
      canvas.drawCircle(center, radius, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.4);
      final label = TextPainter(text: TextSpan(text: '${i + 1}', style: TextStyle(color: const Color(0xFF1A1A32), fontWeight: FontWeight.w900, fontSize: cell * .29)), textDirection: TextDirection.ltr)..layout();
      label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
    }
  }
  @override bool shouldRepaint(_LudoPainter old) => true;
}

class LudoPage extends StatefulWidget {
  const LudoPage({super.key, required this.onFinish}); final VoidCallback onFinish;
  @override State<LudoPage> createState() => _LudoPageState();
}
class _LudoPageState extends State<LudoPage> {
  int count = 2;
  late LudoMatch match = LudoMatch(2);
  late List<List<int>> visual = match.tokens.map((row) => List<int>.of(row)).toList();
  bool combinedDice = true, moving = false;
  Timer? movement;
  final rng = math.Random();
  @override void dispose() { movement?.cancel(); super.dispose(); }
  void restart([int? n]) {
    movement?.cancel();
    setState(() { count = n ?? count; match = LudoMatch(count); visual = match.tokens.map((row) => List<int>.of(row)).toList(); moving = false; });
  }
  void roll() {
    if (moving || match.phase != 'roll') return;
    setState(() => match.roll(rng.nextInt(6) + 1));
  }
  void move(int index) {
    if (moving || !match.options.contains(index)) return;
    final owner = match.current;
    final previous = match.tokens[owner][index];
    final finish = previous == -1 ? 0 : previous + match.die!;
    var progress = previous;
    setState(() => moving = true);
    movement?.cancel();
    movement = Timer.periodic(const Duration(milliseconds: 140), (timer) {
      if (!mounted) { timer.cancel(); return; }
      progress++;
      setState(() => visual[owner][index] = progress);
      if (progress >= finish) {
        timer.cancel();
        movement = null;
        setState(() { match.move(index); visual = match.tokens.map((row) => List<int>.of(row)).toList(); moving = false; });
        if (match.winner != null) widget.onFinish();
      }
    });
  }
  @override Widget build(BuildContext context) {
    final available = moving ? <int>[] : match.options;
    final tone = ludoColors[match.current];
    return GameFrame(title: 'Ludo', subtitle: '2 A 4 JOGADORES · TABULEIRO', children: [
      Wrap(alignment: WrapAlignment.center, spacing: 8, children: [for (final n in [2, 3, 4]) ChoiceChip(label: Text('$n jogadores'), selected: count == n, onSelected: moving ? null : (_) => restart(n))]),
      SwitchListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), title: const Text('Dados combinados', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), subtitle: const Text('Guarde o 6, jogue outra vez e escolha como mover.'), value: combinedDice, onChanged: moving || match.combined ? null : (value) => setState(() => combinedDice = value)),
      Wrap(spacing: 8, runSpacing: 8, children: [for (final player in match.players) Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: player == match.current ? ludoColors[player] : const Color(0xFF4B5269), width: player == match.current ? 2 : 1)), child: Text('${ludoNames[player]}  ${match.tokens[player].where((p) => p == 56).length}/4', style: TextStyle(color: ludoColors[player], fontWeight: FontWeight.w900, fontSize: 10)))]),
      const SizedBox(height: 12), StatusBanner(match.winner != null ? '${ludoNames[match.winner!]} VENCEU!' : moving ? 'PEÃO ANDANDO CASA POR CASA...' : 'VEZ DE ${ludoNames[match.current]}', tone: tone),
      AspectRatio(aspectRatio: 1, child: ClipRRect(borderRadius: BorderRadius.circular(13), child: CustomPaint(painter: _LudoPainter(match, visual, moving), child: const SizedBox.expand()))),
      if (match.combined && match.banked != null && match.die != null && match.phase == 'move') Padding(padding: const EdgeInsets.only(top: 12), child: Row(children: [Expanded(child: FilledButton(onPressed: null, child: Text('DADO ${match.die} ✓'))), const SizedBox(width: 8), Expanded(child: FilledButton.tonal(onPressed: moving ? null : () => setState(match.swapDice), child: Text('USAR ${match.banked}')))])),
      if (available.isNotEmpty) ...[const SizedBox(height: 13), Text('QUAL PEÇA ANDA ${match.die} ${match.die == 1 ? 'CASA' : 'CASAS'}?', style: const TextStyle(color: violet, fontWeight: FontWeight.w900, fontSize: 12), textAlign: TextAlign.center), const SizedBox(height: 9), Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [for (final index in available) FilledButton.tonal(onPressed: () => move(index), child: Text('PEÇA ${index + 1}'))])],
      if (combinedDice && !moving && match.canBank) Padding(padding: const EdgeInsets.only(top: 12), child: SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: () => setState(match.saveSix), child: const Text('🎲 GUARDAR 6 E LANÇAR DE NOVO')))),
      const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: moving || match.phase != 'roll' ? null : roll, icon: const Icon(Icons.casino), label: Text(match.phase == 'roll' ? match.banked != null ? 'LANÇAR SEGUNDO DADO' : 'LANÇAR DADO' : match.die == null ? 'AGUARDE' : 'SAIU ${match.die}'))),
      const SizedBox(height: 10), Text(match.message, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFFC6CBE4)), textAlign: TextAlign.center),
      RestartButton(() => restart()),
      const Padding(padding: EdgeInsets.only(top: 11), child: Text('Tire 6 para sair da base. Casas com ★ são seguras. Três seis seguidos encerram a vez.', style: TextStyle(fontSize: 11, color: Color(0xFF9AA5C2)), textAlign: TextAlign.center)),
    ]);
  }
}
