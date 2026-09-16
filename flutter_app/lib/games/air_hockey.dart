import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../main.dart';

const courtW = 360.0, courtH = 600.0, puckR = 11.0, paddleR = 25.0;

class AirFlameGame extends FlameGame {
  AirFlameGame() { reset(); }
  double puckX = 180, puckY = 300, vx = 120, vy = 310;
  final paddles = <Offset>[const Offset(180, 520), const Offset(180, 80)];
  final scores = <int>[0, 0];
  int? winner;
  bool playing = true;
  void Function()? scored;
  void reset() {
    puckX = 180; puckY = 300;
    vx = math.Random().nextBool() ? 120 : -120;
    vy = math.Random().nextBool() ? 310 : -310;
    paddles[0] = const Offset(180, 520); paddles[1] = const Offset(180, 80);
    scores[0] = scores[1] = 0; winner = null; playing = true;
  }
  void move(int player, Offset at) {
    if (!playing || winner != null) return;
    paddles[player] = Offset(at.dx.clamp(paddleR, courtW - paddleR).toDouble(),
      player == 0 ? at.dy.clamp(326.0, courtH - paddleR).toDouble() : at.dy.clamp(paddleR, 274.0).toDouble());
  }
  void _serve(int player) {
    puckX = 180; puckY = 300;
    vx = (math.Random().nextDouble() - .5) * 240;
    vy = player == 0 ? 300 : -300;
    paddles[0] = const Offset(180, 520); paddles[1] = const Offset(180, 80);
  }
  @override void update(double elapsed) {
    super.update(elapsed);
    if (!playing || winner != null) return;
    final dt = elapsed.clamp(0.0, .032);
    puckX += vx * dt; puckY += vy * dt;
    if (puckX < puckR) { puckX = puckR; vx = vx.abs(); }
    if (puckX > courtW - puckR) { puckX = courtW - puckR; vx = -vx.abs(); }
    for (var i = 0; i < 2; i++) {
      final pad = paddles[i];
      final dx = puckX - pad.dx, dy = puckY - pad.dy, distance = math.sqrt(dx * dx + dy * dy);
      if (distance >= puckR + paddleR || distance <= .000001) continue;
      final nx = dx / distance, ny = dy / distance;
      final approach = vx * nx + vy * ny;
      puckX = pad.dx + nx * (puckR + paddleR + .7);
      puckY = pad.dy + ny * (puckR + paddleR + .7);
      if (approach < 0) { vx -= 2 * approach * nx; vy -= 2 * approach * ny; }
      vx += nx * 155; vy += ny * 155;
      final speed = math.sqrt(vx * vx + vy * vy);
      final target = speed.clamp(350.0, 900.0);
      if (speed > .00001) { vx = vx / speed * target; vy = vy / speed * target; }
    }
    if (puckY < -puckR || puckY > courtH + puckR) {
      if (puckX > 115 && puckX < 245) {
        final player = puckY < 0 ? 0 : 1;
        scores[player]++;
        winner = scores[player] >= 7 ? player : null;
        playing = winner == null;
        scored?.call();
        if (winner == null) _serve(player);
      } else { puckY = puckY < 0 ? puckR : courtH - puckR; vy *= -1; }
    } else if (puckY < puckR && (puckX <= 115 || puckX >= 245)) { puckY = puckR; vy = vy.abs(); }
    else if (puckY > courtH - puckR && (puckX <= 115 || puckX >= 245)) { puckY = courtH - puckR; vy = -vy.abs(); }
  }
  @override void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    canvas.save(); canvas.scale(size.x / courtW, size.y / courtH);
    canvas.drawRect(const Rect.fromLTWH(0, 0, courtW, courtH), Paint()..color = const Color(0xFF111B34));
    final grid = Paint()..color = const Color(0x334DA4C5)..strokeWidth = 1;
    for (var x = 30.0; x < courtW; x += 30) canvas.drawLine(Offset(x, 0), Offset(x, courtH), grid);
    for (var y = 30.0; y < courtH; y += 30) canvas.drawLine(Offset(0, y), Offset(courtW, y), grid);
    canvas.drawRect(const Rect.fromLTWH(0, 0, courtW, courtH), Paint()..color = const Color(0x19FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawLine(const Offset(0, 300), const Offset(courtW, 300), Paint()..color = const Color(0xFF7D93CF)..strokeWidth = 3);
    canvas.drawCircle(const Offset(180, 300), 55, Paint()..color = const Color(0xFF7D93CF)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawLine(const Offset(115, 4), const Offset(245, 4), Paint()..color = pink..strokeWidth = 8);
    canvas.drawLine(const Offset(115, 596), const Offset(245, 596), Paint()..color = cyan..strokeWidth = 8);
    for (var i = 0; i < 2; i++) {
      final pad = paddles[i], color = i == 0 ? cyan : pink;
      canvas.drawCircle(pad, paddleR + 3, Paint()..color = const Color(0x66000000));
      canvas.drawCircle(pad, paddleR, Paint()..color = color);
      canvas.drawCircle(pad, 10, Paint()..color = const Color(0xFFECEBFF));
    }
    canvas.drawCircle(Offset(puckX, puckY), puckR + 3, Paint()..color = const Color(0x77090A1F));
    canvas.drawCircle(Offset(puckX, puckY), puckR, Paint()..color = Colors.white);
    if (!playing) {
      canvas.drawRect(const Rect.fromLTWH(0, 0, courtW, courtH), Paint()..color = const Color(0xBB0D1021));
      final text = TextPainter(text: TextSpan(text: winner == null ? 'PAUSADO' : '${winner == 0 ? 'AZUL' : 'ROSA'} VENCEU!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30)), textDirection: TextDirection.ltr)..layout();
      text.paint(canvas, Offset(180 - text.width / 2, 300 - text.height / 2));
    }
    canvas.restore();
  }
}

class AirHockeyPage extends StatefulWidget {
  const AirHockeyPage({super.key, required this.onFinish});
  final VoidCallback onFinish;
  @override State<AirHockeyPage> createState() => _AirHockeyPageState();
}
class _AirHockeyPageState extends State<AirHockeyPage> {
  late final AirFlameGame game = AirFlameGame()..scored = _scored;
  final Map<int, int> pointers = {};
  bool reported = false;
  void _scored() {
    if (!mounted) return;
    setState(() {});
    if (game.winner != null && !reported) { reported = true; widget.onFinish(); }
  }
  void _move(int pointer, Offset local, Size size) {
    final player = pointers[pointer];
    if (player == null) return;
    game.move(player, Offset(local.dx / size.width * courtW, local.dy / size.height * courtH));
  }
  void _restart() => setState(() { game.reset(); pointers.clear(); reported = false; });
  @override Widget build(BuildContext context) => GameFrame(title: 'Air Rocket', subtitle: '2 PESSOAS · MULTITOQUE · TEMPO REAL', children: [
    StatusBanner('ROSA ${game.scores[1]}     ·     PRIMEIRO A 7     ·     AZUL ${game.scores[0]}', tone: cyan),
    Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: AspectRatio(aspectRatio: courtW / courtH,
      child: LayoutBuilder(builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return GestureDetector(onVerticalDragUpdate: (_) {}, onHorizontalDragUpdate: (_) {},
          child: Listener(behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              final player = event.localPosition.dy < size.height / 2 ? 1 : 0;
              if (pointers.containsValue(player)) return;
              pointers[event.pointer] = player;
              _move(event.pointer, event.localPosition, size);
            },
            onPointerMove: (event) => _move(event.pointer, event.localPosition, size),
            onPointerUp: (event) => pointers.remove(event.pointer),
            onPointerCancel: (event) => pointers.remove(event.pointer),
            child: GameWidget(game: game)));
      })))),
    const SizedBox(height: 14), Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _restart, icon: const Icon(Icons.refresh), label: const Text('Reiniciar'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: game.winner == null ? () => setState(() => game.playing = !game.playing) : null, icon: Icon(game.playing ? Icons.pause : Icons.play_arrow), label: Text(game.playing ? 'Pausar' : 'Continuar')))]),
    const SizedBox(height: 12), const Text('Cada pessoa arrasta um rebatedor na sua metade da tela. Dois dedos podem jogar ao mesmo tempo. Primeiro a 7 gols vence.', style: TextStyle(color: Color(0xFFB0BAD1), fontSize: 12, height: 1.5), textAlign: TextAlign.center),
  ]);
}
