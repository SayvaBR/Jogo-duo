import { describe, expect, it } from 'vitest';
import { ballGroup, finishPoolShot, newPoolMatch, placeCueBall, remainingPoolBalls, shootPool, stepPool } from './poolEngine';
import type { PoolMatch, PoolShot } from './poolEngine';

function resolving(game: PoolMatch, patch: Partial<PoolShot>): void {
  game.phase = 'moving';
  game.shot = { firstHit: 1, potted: [], scratch: false, ownAtStart: -1, ...patch };
  for (const ball of game.balls) { ball.vx = 0; ball.vy = 0; }
  finishPoolShot(game);
}

describe('Sinuca local', () => {
  it('inicia com branca, 15 bolas únicas, bola 8 no centro e sem sobreposições', () => {
    const game = newPoolMatch();
    expect(game.balls).toHaveLength(16);
    expect(new Set(game.balls.map(ball => ball.id)).size).toBe(16);
    expect(game.balls.find(ball => ball.id === 8)?.y).toBeCloseTo(260.7);
    for (let i = 0; i < game.balls.length; i++) for (let j = i + 1; j < game.balls.length; j++)
      expect(Math.hypot(game.balls[i].x - game.balls[j].x, game.balls[i].y - game.balls[j].y)).toBeGreaterThanOrEqual(19.99);
    expect(game.current).toBe(0);
  });
  it('classifica lisas e listradas e permite tacada apenas na vez de mirar', () => {
    expect(ballGroup(0)).toBeNull(); expect(ballGroup(8)).toBeNull();
    expect(ballGroup(7)).toBe('lisas'); expect(ballGroup(9)).toBe('listradas');
    const game = newPoolMatch();
    expect(shootPool(game, -Math.PI / 2, 65)).toBe(true);
    expect(game.phase).toBe('moving');
    expect(shootPool(game, 0, 65)).toBe(false);
    expect(shootPool(newPoolMatch(), 0, 101)).toBe(false);
  });
  it('respeita colisões e registra a primeira bola tocada pela branca', () => {
    const game = newPoolMatch();
    const one = game.balls.find(ball => ball.id === 1)!;
    game.balls.forEach(ball => { if (ball.id !== 0 && ball.id !== 1) ball.pocketed = true; });
    one.x = 210; one.y = 455;
    expect(shootPool(game, -Math.PI / 2, 40)).toBe(true);
    for (let step = 0; step < 1000 && game.phase === 'moving'; step++) stepPool(game, 1 / 120);
    expect(game.phase).toBe('aim');
    expect(game.lastShot?.firstHit).toBe(1);
    expect(one.y).toBeLessThan(455);
  });
  it('atribui grupo após primeira bola legal encaçapada e dá nova tacada', () => {
    const game = newPoolMatch();
    game.balls.find(ball => ball.id === 1)!.pocketed = true;
    resolving(game, { potted: [1] });
    expect(game.groups).toEqual(['lisas', 'listradas']);
    expect(game.current).toBe(0);
    expect(remainingPoolBalls(game, 'lisas')).toBe(6);
  });
  it('troca turno quando não encaçapa e concede branca livre na falta', () => {
    const game = newPoolMatch();
    resolving(game, { firstHit: 1 });
    expect(game.current).toBe(1);
    expect(game.ballInHand).toBe(false);
    resolving(game, { firstHit: null, scratch: true, potted: [0] });
    expect(game.current).toBe(0);
    expect(game.ballInHand).toBe(true);
    expect(game.balls.find(ball => ball.id === 0)!.pocketed).toBe(false);
    expect(placeCueBall(game, 210, 545)).toBe(true);
    expect(placeCueBall(game, 210, 225)).toBe(false);
    expect(placeCueBall(game, -1, 200)).toBe(false);
  });
  it('impede a bola 8 antecipada e valida vitória somente após limpar o grupo', () => {
    const early = newPoolMatch();
    resolving(early, { firstHit: 8, potted: [8] });
    expect(early.winner).toBe(1); expect(early.phase).toBe('done');
    const legal = newPoolMatch();
    legal.groups = ['lisas', 'listradas'];
    legal.balls.filter(ball => ballGroup(ball.id) === 'lisas').forEach(ball => { ball.pocketed = true; });
    expect(remainingPoolBalls(legal, 'lisas')).toBe(0);
    resolving(legal, { firstHit: 8, potted: [8], ownAtStart: 0 });
    expect(legal.winner).toBe(0);
    expect(legal.phase).toBe('done');
    expect(shootPool(legal, 0, 50)).toBe(false);
  });
  it('branca encaçapada com bola 8 concede a vitória ao oponente', () => {
    const game = newPoolMatch();
    game.groups = ['lisas', 'listradas'];
    game.balls.filter(ball => ballGroup(ball.id) === 'lisas').forEach(ball => { ball.pocketed = true; });
    resolving(game, { firstHit: 8, scratch: true, potted: [8, 0], ownAtStart: 0 });
    expect(game.winner).toBe(1);
  });
});
