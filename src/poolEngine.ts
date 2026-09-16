// Jogo Duo · Sinuca 8 bolas. Pure, offline-friendly simulation with no dependencies.
// All coordinates are in portrait table units; callers advance using fixed timesteps.
export const POOL_W = 420;
export const POOL_H = 720;
export const POOL_R = 10;
export const POOL_BOUNDS = { left: 38, right: 382, top: 40, bottom: 680 } as const;
export type PoolGroup = 'lisas' | 'listradas';
export type PoolPlayer = 0 | 1;
export type PoolPhase = 'aim' | 'moving' | 'done';
export interface PoolBall { id: number; x: number; y: number; vx: number; vy: number; pocketed: boolean }
export interface PoolShot { firstHit: number | null; potted: number[]; scratch: boolean; ownAtStart: number }
export interface PoolMatch {
  balls: PoolBall[];
  current: PoolPlayer;
  groups: [PoolGroup | null, PoolGroup | null];
  phase: PoolPhase;
  ballInHand: boolean;
  winner: PoolPlayer | null;
  shot: PoolShot | null;
  lastShot: PoolShot | null;
  shots: number;
  message: string;
}
const OTHER = (player: PoolPlayer): PoolPlayer => player === 0 ? 1 : 0;
const rowOrder = [1, 9, 2, 3, 8, 10, 11, 4, 12, 5, 6, 13, 7, 14, 15];
const pockets = [
  { x: 38, y: 40, r: 22 }, { x: 382, y: 40, r: 22 },
  { x: 38, y: 360, r: 20 }, { x: 382, y: 360, r: 20 },
  { x: 38, y: 680, r: 22 }, { x: 382, y: 680, r: 22 }
];
export const POOL_POCKETS: ReadonlyArray<Readonly<{ x: number; y: number; r: number }>> = pockets;
export function ballGroup(id: number): PoolGroup | null {
  if (id >= 1 && id <= 7) return 'lisas';
  if (id >= 9 && id <= 15) return 'listradas';
  return null;
}
export function remainingPoolBalls(game: PoolMatch, group: PoolGroup): number {
  return game.balls.filter(ball => !ball.pocketed && ballGroup(ball.id) === group).length;
}
export function newPoolMatch(): PoolMatch {
  const balls: PoolBall[] = [{ id: 0, x: 210, y: 548, vx: 0, vy: 0, pocketed: false }];
  let offset = 0;
  for (let row = 0; row < 5; row++) {
    for (let index = 0; index <= row; index++) {
      balls.push({ id: rowOrder[offset++], x: 210 + (index - row / 2) * 20.5,
        y: 225 + row * 17.85, vx: 0, vy: 0, pocketed: false });
    }
  }
  return { balls, current: 0, groups: [null, null], phase: 'aim', ballInHand: false,
    winner: null, shot: null, lastShot: null, shots: 0,
    message: 'Jogador 1: mire arrastando na mesa, escolha a força e dê a tacada!' };
}
function freeCueSpot(game: PoolMatch, x: number, y: number): boolean {
  const bounds = POOL_BOUNDS;
  if (x < bounds.left + POOL_R || x > bounds.right - POOL_R ||
      y < bounds.top + POOL_R || y > bounds.bottom - POOL_R) return false;
  if (pockets.some(pocket => Math.hypot(x - pocket.x, y - pocket.y) < pocket.r + 2)) return false;
  return game.balls.every(ball => ball.id === 0 || ball.pocketed ||
    Math.hypot(x - ball.x, y - ball.y) >= POOL_R * 2 + 1);
}
function respotCue(game: PoolMatch): void {
  const cue = game.balls.find(ball => ball.id === 0)!;
  cue.pocketed = false; cue.vx = 0; cue.vy = 0;
  for (let y = 548; y <= 645; y += 24) {
    for (let offset = 0; offset <= 130; offset += 24) {
      for (const sign of [1, -1]) {
        const x = 210 + offset * sign;
        if (freeCueSpot(game, x, y)) { cue.x = x; cue.y = y; return; }
      }
    }
  }
  // Extremely crowded layout: search the whole cloth rather than overlap another ball.
  for (let y = 70; y < 650; y += 21) {
    for (let x = 67; x < 355; x += 21) {
      if (freeCueSpot(game, x, y)) { cue.x = x; cue.y = y; return; }
    }
  }
}
export function placeCueBall(game: PoolMatch, x: number, y: number): boolean {
  if (game.phase !== 'aim' || !game.ballInHand || !Number.isFinite(x) || !Number.isFinite(y) ||
      !freeCueSpot(game, x, y)) return false;
  const cue = game.balls.find(ball => ball.id === 0)!;
  cue.x = x; cue.y = y; cue.pocketed = false; cue.vx = 0; cue.vy = 0;
  return true;
}
export function shootPool(game: PoolMatch, angle: number, power: number): boolean {
  if (game.phase !== 'aim' || game.winner !== null || !Number.isFinite(angle) ||
      !Number.isFinite(power) || power < 10 || power > 100) return false;
  const cue = game.balls.find(ball => ball.id === 0)!;
  if (cue.pocketed) return false;
  const speed = 210 + (power / 100) * 650;
  cue.vx = Math.cos(angle) * speed;
  cue.vy = Math.sin(angle) * speed;
  game.shot = { firstHit: null, potted: [], scratch: false,
    ownAtStart: game.groups[game.current] ? remainingPoolBalls(game, game.groups[game.current]!) : -1 };
  game.phase = 'moving'; game.ballInHand = false; game.shots++;
  game.message = 'Bolas em movimento...';
  return true;
}
function pocketBall(game: PoolMatch, ball: PoolBall): void {
  if (ball.pocketed) return;
  ball.pocketed = true; ball.vx = 0; ball.vy = 0;
  if (game.shot) {
    game.shot.potted.push(ball.id);
    if (ball.id === 0) game.shot.scratch = true;
  }
}
function simulateStep(game: PoolMatch, dt: number): void {
  for (const ball of game.balls) {
    if (ball.pocketed) continue;
    ball.x += ball.vx * dt;
    ball.y += ball.vy * dt;
    const speed = Math.hypot(ball.vx, ball.vy);
    if (speed <= 6) { ball.vx = 0; ball.vy = 0; }
    else {
      const next = Math.max(0, speed - 172 * dt);
      ball.vx = ball.vx / speed * next;
      ball.vy = ball.vy / speed * next;
    }
    if (pockets.some(pocket => Math.hypot(ball.x - pocket.x, ball.y - pocket.y) < pocket.r)) {
      pocketBall(game, ball); continue;
    }
    const { left, right, top, bottom } = POOL_BOUNDS;
    if (ball.x < left + POOL_R) { ball.x = left + POOL_R; ball.vx = Math.abs(ball.vx) * .84; }
    if (ball.x > right - POOL_R) { ball.x = right - POOL_R; ball.vx = -Math.abs(ball.vx) * .84; }
    if (ball.y < top + POOL_R) { ball.y = top + POOL_R; ball.vy = Math.abs(ball.vy) * .84; }
    if (ball.y > bottom - POOL_R) { ball.y = bottom - POOL_R; ball.vy = -Math.abs(ball.vy) * .84; }
  }
  for (let i = 0; i < game.balls.length; i++) {
    const a = game.balls[i]; if (a.pocketed) continue;
    for (let j = i + 1; j < game.balls.length; j++) {
      const b = game.balls[j]; if (b.pocketed) continue;
      let dx = b.x - a.x, dy = b.y - a.y;
      let distance = Math.hypot(dx, dy);
      if (distance >= POOL_R * 2) continue;
      if (distance < .00001) { dx = POOL_R * 2; dy = 0; distance = POOL_R * 2; }
      const nx = dx / distance, ny = dy / distance;
      const overlap = POOL_R * 2 - distance;
      a.x -= nx * overlap * .5; a.y -= ny * overlap * .5;
      b.x += nx * overlap * .5; b.y += ny * overlap * .5;
      const approaching = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
      if (approaching < 0) {
        if (game.shot && game.shot.firstHit === null) {
          if (a.id === 0 && b.id !== 0) game.shot.firstHit = b.id;
          else if (b.id === 0 && a.id !== 0) game.shot.firstHit = a.id;
        }
        const impulse = -(1 + .96) * approaching / 2;
        a.vx -= impulse * nx; a.vy -= impulse * ny;
        b.vx += impulse * nx; b.vy += impulse * ny;
      }
    }
  }
}
export function finishPoolShot(game: PoolMatch): void {
  if (game.phase !== 'moving' || !game.shot) return;
  const shot = game.shot;
  game.lastShot = { ...shot, potted: [...shot.potted] }; game.shot = null;
  game.balls.forEach(ball => { ball.vx = 0; ball.vy = 0; });
  const player = game.current, opponent = OTHER(player);
  const group = game.groups[player];
  const validFirst = shot.firstHit !== null &&
    (group === null ? shot.firstHit !== 8 :
      shot.ownAtStart === 0 ? shot.firstHit === 8 : ballGroup(shot.firstHit) === group);
  const foul = shot.scratch || !validFirst;
  const black = shot.potted.includes(8);
  if (black) {
    const legalBlack = group !== null && shot.ownAtStart === 0 && shot.firstHit === 8 && !foul;
    game.winner = legalBlack ? player : opponent;
    game.phase = 'done'; game.ballInHand = false;
    game.message = legalBlack ? `Jogador ${player + 1} encaçapou a 8 e venceu!` :
      `Bola 8 fora de hora ou com falta: jogador ${opponent + 1} venceu!`;
    return;
  }
  if (!foul && group === null) {
    const firstColored = shot.potted.find(id => ballGroup(id) !== null);
    if (firstColored !== undefined) {
      const chosen = ballGroup(firstColored)!;
      game.groups[player] = chosen;
      game.groups[opponent] = chosen === 'lisas' ? 'listradas' : 'lisas';
    }
  }
  const own = game.groups[player];
  const keptTurn = !foul && shot.potted.some(id => ballGroup(id) !== null && ballGroup(id) === own);
  if (foul) {
    game.current = opponent; game.ballInHand = true;
    respotCue(game);
    game.message = shot.scratch ? `Branca na caçapa! Jogador ${opponent + 1} reposiciona a branca.` :
      `Falta: primeira bola incorreta ou nenhuma bola atingida. Jogador ${opponent + 1} reposiciona a branca.`;
  } else if (keptTurn) {
    game.message = `Boa! Jogador ${player + 1} encaçapou sua bola e continua.`;
  } else {
    game.current = opponent;
    game.message = `Vez do jogador ${opponent + 1}. Mire e dê a tacada.`;
  }
  game.phase = 'aim';
}
/** Returns true only when a shot has just finished. */
export function stepPool(game: PoolMatch, elapsedSeconds: number): boolean {
  if (game.phase !== 'moving') return false;
  const elapsed = Math.max(0, Math.min(Number.isFinite(elapsedSeconds) ? elapsedSeconds : 0, .05));
  const steps = Math.max(1, Math.ceil(elapsed / (1 / 120)));
  for (let n = 0; n < steps; n++) simulateStep(game, elapsed / steps);
  const settled = game.balls.every(ball => ball.pocketed || Math.hypot(ball.vx, ball.vy) < 6);
  if (settled) { finishPoolShot(game); return true; }
  return false;
}
