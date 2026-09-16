import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'pool_engine.dart';

const ballColors = <Color>[
  Colors.white, Color(0xFFE8BF43), Color(0xFF397FE5), Color(0xFFEC5864),
  Color(0xFF995AC6), Color(0xFFE79A36), Color(0xFF36B287), Color(0xFF903B52),
  Color(0xFF151821), Color(0xFFE8BF43), Color(0xFF397FE5), Color(0xFFEC5864),
  Color(0xFF995AC6), Color(0xFFE79A36), Color(0xFF36B287), Color(0xFF903B52),
];

void _disc(Canvas canvas, Offset at, double radius, Color color) =>
  canvas.drawCircle(at, radius, Paint()..color = color);

void _ball(Canvas canvas, Ball ball) {
  if (ball.pocketed) return;
  final pos = Offset(ball.x, ball.y);
  _disc(canvas, pos + const Offset(2, 3), ballRadius + 1, const Color(0x77041116));
  _disc(canvas, pos, ballRadius, ballColors[ball.id]);
  canvas.drawCircle(pos, ballRadius - .6, Paint()..color = const Color(0xAA0D1730)..style = PaintingStyle.stroke..strokeWidth = 1.2);
  if (ball.id >= 9) {
    canvas.save(); canvas.clipPath(Path()..addOval(Rect.fromCircle(center: pos, radius: ballRadius - 1)));
    canvas.drawRect(Rect.fromLTWH(ball.x - ballRadius, ball.y - 5.1, ballRadius * 2, 10.2), Paint()..color = const Color(0xFFF8F6EF));
    canvas.restore();
  }
  if (ball.id != 0) {
    _disc(canvas, pos, 5.5, const Color(0xFFFFFEF7));
    final label = TextPainter(text: TextSpan(text: '${ball.id}', style: const TextStyle(color: Color(0xFF1D2030), fontWeight: FontWeight.w900, fontSize: 7.1)), textDirection: TextDirection.ltr)..layout();
    label.paint(canvas, pos - Offset(label.width / 2, label.height / 2));
  }
  _disc(canvas, pos + const Offset(-3, -3), 2, const Color(0x99FFFFFF));
}

class PoolFlameGame extends FlameGame {
  PoolMatch match = PoolMatch();
  double angle = -math.pi / 2, power = 56;
  bool placing = false;
  VoidCallback? onSettled;
  @override void update(double dt) {
    super.update(dt);
    if (match.phase == 'moving' && match.step(dt)) onSettled?.call();
  }
  @override void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    canvas.save(); canvas.scale(size.x / poolW, size.y / poolH);
    _paintTable(canvas);
    canvas.restore();
  }
  void _paintTable(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, poolW, poolH), const Radius.circular(32)), Paint()..color = const Color(0xFF8B5C40));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(13, 13, poolW - 26, poolH - 26), const Radius.circular(24)), Paint()..color = const Color(0xFF251C29));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(19, 19, poolW - 38, poolH - 38), const Radius.circular(21)), Paint()..color = const Color(0xFFB68457));
    final cloth = const Rect.fromLTRB(leftRail, topRail, rightRail, bottomRail);
    canvas.drawRect(cloth, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF197C61), Color(0xFF0A4A3E)]).createShader(cloth));
    final marker = Paint()..color = const Color(0x448ACDAA)..strokeWidth = 1;
    canvas.drawLine(const Offset(leftRail + 2, 360), const Offset(rightRail - 2, 360), marker);
    for (final pocket in pockets) {
      _disc(canvas, Offset(pocket.x, pocket.y), pocket.r + 3, const Color(0xFF704936));
      _disc(canvas, Offset(pocket.x, pocket.y), pocket.r, const Color(0xFF12131B));
      _disc(canvas, Offset(pocket.x + 1, pocket.y + 1), pocket.r - 5, const Color(0xFF090E14));
    }
    final cue = match.cue;
    if (match.phase == 'aim' && !cue.pocketed && !placing) {
      final dir = Offset(math.cos(angle), math.sin(angle)), start = Offset(cue.x, cue.y);
      var distance = 950.0;
      if (dir.dx > .0001) distance = math.min(distance, (rightRail - ballRadius - cue.x) / dir.dx);
      if (dir.dx < -.0001) distance = math.min(distance, (leftRail + ballRadius - cue.x) / dir.dx);
      if (dir.dy > .0001) distance = math.min(distance, (bottomRail - ballRadius - cue.y) / dir.dy);
      if (dir.dy < -.0001) distance = math.min(distance, (topRail + ballRadius - cue.y) / dir.dy);
      for (final ball in match.balls) {
        if (ball.pocketed || ball.id == 0) continue;
        final bx = ball.x - cue.x, by = ball.y - cue.y;
        final ahead = bx * dir.dx + by * dir.dy;
        final sideways = bx * bx + by * by - ahead * ahead;
        if (ahead <= 0 || sideways > 4 * ballRadius * ballRadius) continue;
        distance = math.min(distance, math.max(0, ahead - math.sqrt(math.max(0, 4 * ballRadius * ballRadius - sideways))));
      }
      distance = math.max(0, distance);
      final guide = Paint()..color = const Color(0xD5FFFFFF)..strokeWidth = 1.8;
      for (var d = 12.0; d < distance; d += 17) canvas.drawLine(start + dir * d, start + dir * math.min(d + 8, distance), guide);
      canvas.drawCircle(start + dir * distance, ballRadius, Paint()..color = const Color(0x77FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1.4);
      final gap = 25 + power * .23;
      final a = start - dir * gap, b = start - dir * (gap + 143);
      canvas.drawLine(a + const Offset(2, 3), b + const Offset(2, 3), Paint()..color = const Color(0xBB171A25)..strokeWidth = 12..strokeCap = StrokeCap.round);
      canvas.drawLine(a, b, Paint()..color = const Color(0xFFC58E5D)..strokeWidth = 7..strokeCap = StrokeCap.round);
      canvas.drawLine(a, a - dir * 11, Paint()..color = const Color(0xFF76E1E8)..strokeWidth = 7..strokeCap = StrokeCap.round);
    }
    for (final ball in match.balls) _ball(canvas, ball);
    if (placing) {
      canvas.drawCircle(Offset(cue.x, cue.y), 21, Paint()..color = mint..style = PaintingStyle.stroke..strokeWidth = 2.5);
    }
    if (match.phase == 'done') {
      canvas.drawRect(const Rect.fromLTRB(leftRail, 310, rightRail, 410), Paint()..color = const Color(0xDD09182A));
      final text = TextPainter(text: TextSpan(text: 'JOGADOR ${match.winner! + 1} VENCEU!', style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 23)), textDirection: TextDirection.ltr)..layout();
      text.paint(canvas, Offset(210 - text.width / 2, 360 - text.height / 2));
    }
  }
}

class PoolPage extends StatefulWidget {
  const PoolPage({super.key, required this.onFinish});
  final VoidCallback onFinish;
  @override State<PoolPage> createState() => _PoolPageState();
}
class _PoolPageState extends State<PoolPage> {
  late final PoolFlameGame game = PoolFlameGame()..onSettled = _settled;
  double power = 56;
  bool placing = false, announced = false;
  void _settled() {
    if (!mounted) return;
    setState(() { placing = game.match.ballInHand; game.placing = placing; });
    if (game.match.winner != null && !announced) { announced = true; widget.onFinish(); }
  }
  void _aim(Offset local, Size size) {
    if (game.match.phase != 'aim') return;
    final at = Offset(local.dx / size.width * poolW, local.dy / size.height * poolH);
    if (placing) { game.match.placeCue(at.dx, at.dy); return; }
    final cue = game.match.cue;
    if ((at - Offset(cue.x, cue.y)).distance <= 11) return;
    setState(() => game.angle = math.atan2(at.dy - cue.y, at.dx - cue.x));
  }
  void _shoot() {
    if (placing || game.match.phase != 'aim') return;
    if (game.match.shoot(game.angle, power)) setState(() {});
  }
  void _restart() => setState(() {
    game.match = PoolMatch(); game.angle = -math.pi / 2;
    game.power = power = 56; game.placing = placing = false; announced = false;
  });
  Widget _player(int player) {
    final match = game.match, group = match.groups[player];
    final tone = player == 0 ? cyan : pink;
    return Expanded(child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: match.current == player && match.phase != 'done' ? tone : const Color(0xFF3E4562), width: match.current == player ? 2 : 1)), child: Column(children: [Text('JOGADOR ${player + 1}', style: TextStyle(color: tone, fontWeight: FontWeight.w900, fontSize: 11)), const SizedBox(height: 5), Text(group == null ? '7 bolas' : '${match.remaining(group)} restantes', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text(group == null ? 'MESA ABERTA' : group.toUpperCase(), style: const TextStyle(color: Color(0xFFAFB8D1), fontSize: 10))])));
  }
  @override Widget build(BuildContext context) {
    final match = game.match, busy = match.phase == 'moving';
    return GameFrame(title: 'Sinuca', subtitle: 'BOLA 8 · 2 JOGADORES · OFFLINE', children: [
      Row(children: [_player(0), const SizedBox(width: 9), _player(1)]),
      const SizedBox(height: 13), StatusBanner(match.winner != null ? 'JOGADOR ${match.winner! + 1} VENCEU!' : busy ? 'BOLAS EM MOVIMENTO...' : 'VEZ DO JOGADOR ${match.current + 1}', tone: match.current == 0 ? cyan : pink),
      AspectRatio(aspectRatio: poolW / poolH, child: LayoutBuilder(builder: (context, bounds) {
        final size = Size(bounds.maxWidth, bounds.maxHeight);
        return GestureDetector(behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _aim(details.localPosition, size),
          onPanStart: (details) => _aim(details.localPosition, size),
          onPanUpdate: (details) => _aim(details.localPosition, size),
          child: GameWidget(game: game));
      })),
      const SizedBox(height: 14), Text(match.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFFCAD2E4), height: 1.45)),
      if (placing) Padding(padding: const EdgeInsets.only(top: 12), child: FilledButton.icon(onPressed: () => setState(() { placing = false; game.placing = false; }), icon: const Icon(Icons.check), label: const Text('Confirmar posição da branca'))),
      if (!placing) ...[
        Row(children: [IconButton(onPressed: busy || match.winner != null ? null : () => setState(() => game.angle -= math.pi / 180), icon: const Icon(Icons.rotate_left), tooltip: 'Mira um grau à esquerda'), const Expanded(child: Text('AJUSTE FINO DA MIRA', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))), IconButton(onPressed: busy || match.winner != null ? null : () => setState(() => game.angle += math.pi / 180), icon: const Icon(Icons.rotate_right), tooltip: 'Mira um grau à direita')]),
        Row(children: [const Icon(Icons.speed, color: violet), const SizedBox(width: 7), const Text('FORÇA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)), Expanded(child: Slider(min: 10, max: 100, divisions: 90, value: power, label: '${power.round()}%', onChanged: busy || match.winner != null ? null : (value) => setState(() => game.power = power = value))), Text('${power.round()}%', style: const TextStyle(fontWeight: FontWeight.w900))]),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy || match.winner != null ? null : _shoot, icon: const Icon(Icons.adjust), label: const Text('DAR TACADA'))),
      ],
      RestartButton(_restart),
      const Padding(padding: EdgeInsets.only(top: 10), child: Text('Toque e arraste na mesa para mirar. Encaçape seu grupo e, por último, a bola 8. Faltas concedem bola na mão.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9EA9C5), fontSize: 11, height: 1.4))),
    ]);
  }
}
