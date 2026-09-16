import 'dart:math' as math;

const poolW = 420.0, poolH = 720.0, ballRadius = 10.0;
const leftRail = 38.0, rightRail = 382.0, topRail = 40.0, bottomRail = 680.0;

double hypot(double x, double y) => math.sqrt(x * x + y * y);
int opponent(int current) => 1 - current;
String? groupOf(int id) => id >= 1 && id <= 7 ? 'lisas' : id >= 9 && id <= 15 ? 'listradas' : null;

class Ball {
  Ball(this.id, this.x, this.y);
  final int id;
  double x, y, vx = 0, vy = 0;
  bool pocketed = false;
  double get speed => hypot(vx, vy);
}
class Pocket {
  const Pocket(this.x, this.y, this.r);
  final double x, y, r;
}
const pockets = <Pocket>[
  Pocket(leftRail, topRail, 22), Pocket(rightRail, topRail, 22),
  Pocket(leftRail, 360, 20), Pocket(rightRail, 360, 20),
  Pocket(leftRail, bottomRail, 22), Pocket(rightRail, bottomRail, 22),
];

class Shot {
  Shot(this.ownAtStart);
  final int ownAtStart;
  int? firstHit;
  final List<int> potted = [];
  bool scratch = false;
}

class PoolMatch {
  PoolMatch() {
    balls.add(Ball(0, 210, 548));
    const order = [1, 9, 2, 3, 8, 10, 11, 4, 12, 5, 6, 13, 7, 14, 15];
    var index = 0;
    for (var row = 0; row < 5; row++) {
      for (var i = 0; i <= row; i++) {
        balls.add(Ball(order[index++], 210 + (i - row / 2) * 20.5, 225 + row * 17.85));
      }
    }
  }
  final List<Ball> balls = [];
  int current = 0;
  final List<String?> groups = [null, null];
  String phase = 'aim';
  bool ballInHand = false;
  int? winner;
  Shot? shot, lastShot;
  int shots = 0;
  String message = 'Jogador 1: arraste para mirar, ajuste a força e dê a tacada.';
  Ball get cue => balls.first;
  int remaining(String group) => balls.where((ball) => !ball.pocketed && groupOf(ball.id) == group).length;

  bool freeCueSpot(double x, double y) {
    if (x < leftRail + ballRadius || x > rightRail - ballRadius || y < topRail + ballRadius || y > bottomRail - ballRadius) return false;
    if (pockets.any((p) => hypot(x - p.x, y - p.y) < p.r + 2)) return false;
    return balls.every((ball) => ball.id == 0 || ball.pocketed || hypot(x - ball.x, y - ball.y) >= ballRadius * 2 + 1);
  }
  bool placeCue(double x, double y) {
    if (phase != 'aim' || !ballInHand || !x.isFinite || !y.isFinite || !freeCueSpot(x, y)) return false;
    cue.x = x; cue.y = y; cue.pocketed = false; cue.vx = cue.vy = 0;
    return true;
  }
  void respotCue() {
    cue.pocketed = false; cue.vx = cue.vy = 0;
    for (var y = 548.0; y <= 645; y += 24) {
      for (var offset = 0.0; offset <= 130; offset += 24) {
        for (final sign in [1, -1]) {
          final x = 210 + offset * sign;
          if (freeCueSpot(x, y)) { cue.x = x; cue.y = y; return; }
        }
      }
    }
    for (var y = 70.0; y < 650; y += 21) for (var x = 67.0; x < 355; x += 21) {
      if (freeCueSpot(x, y)) { cue.x = x; cue.y = y; return; }
    }
  }
  bool shoot(double angle, double power) {
    if (phase != 'aim' || winner != null || !angle.isFinite || !power.isFinite || power < 10 || power > 100 || cue.pocketed) return false;
    final speed = 210 + power / 100 * 650;
    cue.vx = math.cos(angle) * speed; cue.vy = math.sin(angle) * speed;
    shot = Shot(groups[current] == null ? -1 : remaining(groups[current]!));
    phase = 'moving'; ballInHand = false; shots++;
    message = 'Bolas em movimento...';
    return true;
  }
  void pocket(Ball ball) {
    if (ball.pocketed) return;
    ball.pocketed = true; ball.vx = ball.vy = 0;
    shot?.potted.add(ball.id);
    if (ball.id == 0 && shot != null) shot!.scratch = true;
  }
  void _simulate(double dt) {
    for (final ball in balls) {
      if (ball.pocketed) continue;
      ball.x += ball.vx * dt; ball.y += ball.vy * dt;
      final speed = ball.speed;
      if (speed <= 6) { ball.vx = ball.vy = 0; }
      else {
        final next = math.max(0.0, speed - 172 * dt);
        ball.vx = ball.vx / speed * next; ball.vy = ball.vy / speed * next;
      }
      if (pockets.any((p) => hypot(ball.x - p.x, ball.y - p.y) < p.r)) { pocket(ball); continue; }
      if (ball.x < leftRail + ballRadius) { ball.x = leftRail + ballRadius; ball.vx = ball.vx.abs() * .84; }
      if (ball.x > rightRail - ballRadius) { ball.x = rightRail - ballRadius; ball.vx = -ball.vx.abs() * .84; }
      if (ball.y < topRail + ballRadius) { ball.y = topRail + ballRadius; ball.vy = ball.vy.abs() * .84; }
      if (ball.y > bottomRail - ballRadius) { ball.y = bottomRail - ballRadius; ball.vy = -ball.vy.abs() * .84; }
    }
    for (var i = 0; i < balls.length; i++) {
      final a = balls[i]; if (a.pocketed) continue;
      for (var j = i + 1; j < balls.length; j++) {
        final b = balls[j]; if (b.pocketed) continue;
        var dx = b.x - a.x, dy = b.y - a.y;
        var d = hypot(dx, dy);
        if (d >= 2 * ballRadius) continue;
        if (d < .00001) { dx = 2 * ballRadius; dy = 0; d = 2 * ballRadius; }
        final nx = dx / d, ny = dy / d, overlap = 2 * ballRadius - d;
        a.x -= nx * overlap * .5; a.y -= ny * overlap * .5;
        b.x += nx * overlap * .5; b.y += ny * overlap * .5;
        final relative = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
        if (relative < 0) {
          final active = shot;
          if (active != null && active.firstHit == null) {
            if (a.id == 0 && b.id != 0) active.firstHit = b.id;
            if (b.id == 0 && a.id != 0) active.firstHit = a.id;
          }
          final impulse = -(1 + .96) * relative / 2;
          a.vx -= impulse * nx; a.vy -= impulse * ny;
          b.vx += impulse * nx; b.vy += impulse * ny;
        }
      }
    }
  }
  /// True when this shot stops and the rules have been applied.
  bool step(double elapsed) {
    if (phase != 'moving') return false;
    final clamped = elapsed.isFinite ? elapsed.clamp(0.0, .05) : 0.0;
    final steps = math.max(1, (clamped / (1 / 120)).ceil());
    for (var i = 0; i < steps; i++) _simulate(clamped / steps);
    if (balls.every((ball) => ball.pocketed || ball.speed < 6)) {
      finishShot(); return true;
    }
    return false;
  }
  void finishShot() {
    final played = shot;
    if (phase != 'moving' || played == null) return;
    lastShot = played; shot = null;
    for (final ball in balls) { ball.vx = 0; ball.vy = 0; }
    final player = current, other = opponent(player), group = groups[player];
    final valid = played.firstHit != null && (group == null ? played.firstHit != 8 :
      played.ownAtStart == 0 ? played.firstHit == 8 : groupOf(played.firstHit!) == group);
    final foul = played.scratch || !valid;
    final black = played.potted.contains(8);
    if (black) {
      final legal = group != null && played.ownAtStart == 0 && played.firstHit == 8 && !foul;
      winner = legal ? player : other; phase = 'done'; ballInHand = false;
      message = legal ? 'Jogador ${player + 1} encaçapou a 8 e venceu!' : 'Bola 8 fora de hora ou falta: jogador ${other + 1} venceu!';
      return;
    }
    if (!foul && group == null) {
      final colored = played.potted.where((id) => groupOf(id) != null);
      if (colored.isNotEmpty) {
        final chosen = groupOf(colored.first)!;
        groups[player] = chosen; groups[other] = chosen == 'lisas' ? 'listradas' : 'lisas';
      }
    }
    final own = groups[player];
    final extraTurn = !foul && played.potted.any((id) => groupOf(id) != null && groupOf(id) == own);
    if (foul) {
      current = other; ballInHand = true; respotCue();
      message = played.scratch ? 'Branca na caçapa! Jogador ${other + 1} reposiciona a branca.' : 'Falta: bola errada ou nenhuma atingida. Jogador ${other + 1} reposiciona a branca.';
    } else if (extraTurn) {
      message = 'Boa! Jogador ${player + 1} encaçapou sua bola e continua.';
    } else {
      current = other; message = 'Vez do jogador ${other + 1}. Mire e dê a tacada.';
    }
    phase = 'aim';
  }
}
