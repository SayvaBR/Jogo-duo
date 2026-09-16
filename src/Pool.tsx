import { useEffect, useRef, useState } from 'react';
import type { PointerEvent } from 'react';
import { Crosshair, RotateCcw, Target, Trophy, Zap } from 'lucide-react';
import { GameShell } from './App';
import { POOL_BOUNDS, POOL_H, POOL_POCKETS, POOL_R, POOL_W, newPoolMatch, placeCueBall, remainingPoolBalls, shootPool, stepPool } from './poolEngine';
import type { PoolMatch, PoolPlayer, PoolGroup } from './poolEngine';

type View = {
  current: PoolPlayer; groups: [PoolGroup | null, PoolGroup | null];
  phase: PoolMatch['phase']; winner: PoolPlayer | null; ballInHand: boolean;
  message: string; shots: number; remaining: [number, number];
};
const BALL_COLORS: Record<number, string> = {
  1: '#e8bf43', 2: '#397fe5', 3: '#ec5864', 4: '#995ac6',
  5: '#e79a36', 6: '#36b287', 7: '#903b52', 8: '#1b2030',
  9: '#e8bf43', 10: '#397fe5', 11: '#ec5864', 12: '#995ac6',
  13: '#e79a36', 14: '#36b287', 15: '#903b52'
};
const viewOf = (game: PoolMatch): View => ({
  current: game.current, groups: [...game.groups], phase: game.phase,
  winner: game.winner, ballInHand: game.ballInHand, message: game.message, shots: game.shots,
  remaining: [
    game.groups[0] ? remainingPoolBalls(game, game.groups[0]) : 7,
    game.groups[1] ? remainingPoolBalls(game, game.groups[1]) : 7
  ]
});
function circle(ctx: CanvasRenderingContext2D, x: number, y: number, radius: number, fill: string) {
  ctx.beginPath(); ctx.arc(x, y, radius, 0, Math.PI * 2);
  ctx.fillStyle = fill; ctx.fill();
}
function drawBall(ctx: CanvasRenderingContext2D, ball: PoolMatch['balls'][number]) {
  if (ball.pocketed) return;
  const { x, y, id } = ball;
  ctx.save();
  ctx.shadowColor = '#07170e99'; ctx.shadowBlur = 5; ctx.shadowOffsetY = 3;
  circle(ctx, x, y, POOL_R, id === 0 ? '#f8fafc' : BALL_COLORS[id]);
  ctx.restore();
  ctx.lineWidth = 1.2; ctx.strokeStyle = id === 0 ? '#d2d8e6' : '#161a2588';
  ctx.beginPath(); ctx.arc(x, y, POOL_R - .4, 0, Math.PI * 2); ctx.stroke();
  if (id >= 9) {
    ctx.save(); ctx.beginPath(); ctx.arc(x, y, POOL_R - 1, 0, Math.PI * 2); ctx.clip();
    ctx.fillStyle = '#f9f9fa'; ctx.fillRect(x - POOL_R, y - 5.4, POOL_R * 2, 10.8);
    ctx.restore();
  }
  if (id !== 0) {
    circle(ctx, x, y, 5.3, '#fffefa');
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillStyle = '#1c2030'; ctx.font = 'bold 7.4px system-ui';
    ctx.fillText(String(id), x, y + .35);
  }
  circle(ctx, x - 3.3, y - 3.7, 2.15, '#ffffff77');
}
function drawTable(ctx: CanvasRenderingContext2D, game: PoolMatch, angle: number, power: number, placing: boolean) {
  const { left, right, top, bottom } = POOL_BOUNDS;
  ctx.clearRect(0, 0, POOL_W, POOL_H);
  const wood = ctx.createLinearGradient(0, 0, POOL_W, POOL_H);
  wood.addColorStop(0, '#8a5940'); wood.addColorStop(.5, '#422b31'); wood.addColorStop(1, '#a36b43');
  ctx.fillStyle = '#111426'; ctx.fillRect(0, 0, POOL_W, POOL_H);
  ctx.fillStyle = wood; ctx.beginPath(); ctx.roundRect(2, 2, POOL_W - 4, POOL_H - 4, 30); ctx.fill();
  ctx.fillStyle = '#241d26'; ctx.beginPath(); ctx.roundRect(13, 13, POOL_W - 26, POOL_H - 26, 24); ctx.fill();
  ctx.strokeStyle = '#ca9b62'; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.roundRect(9, 9, POOL_W - 18, POOL_H - 18, 25); ctx.stroke();
  const felt = ctx.createLinearGradient(left, top, right, bottom);
  felt.addColorStop(0, '#1b8065'); felt.addColorStop(.5, '#12664f'); felt.addColorStop(1, '#0a493e');
  ctx.fillStyle = felt; ctx.fillRect(left, top, right - left, bottom - top);
  ctx.strokeStyle = '#88ceb245'; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(left + 3, 360); ctx.lineTo(right - 3, 360); ctx.stroke();
  circle(ctx, 210, 548, 3, '#b2ddba70');
  circle(ctx, 210, 225, 3, '#b2ddba70');
  for (const x of [120, 210, 300]) {
    for (const y of [23, 697]) {
      ctx.save(); ctx.translate(x, y); ctx.rotate(Math.PI / 4);
      ctx.fillStyle = '#f5d9a1'; ctx.fillRect(-3, -3, 6, 6); ctx.restore();
    }
  }
  for (const y of [148, 260, 460, 572]) for (const x of [21, 399]) {
    ctx.save(); ctx.translate(x, y); ctx.rotate(Math.PI / 4);
    ctx.fillStyle = '#f5d9a1'; ctx.fillRect(-3, -3, 6, 6); ctx.restore();
  }
  for (const pocket of POOL_POCKETS) {
    circle(ctx, pocket.x, pocket.y, pocket.r + 3, '#6d4736');
    circle(ctx, pocket.x, pocket.y, pocket.r, '#101319');
    circle(ctx, pocket.x + 1, pocket.y + 1, pocket.r - 5, '#080e13');
  }
  const cue = game.balls.find(ball => ball.id === 0)!;
  if (game.phase === 'aim' && !cue.pocketed && !placing) {
    const dx = Math.cos(angle), dy = Math.sin(angle);
    let distance = 1000;
    if (dx > .0001) distance = Math.min(distance, (right - POOL_R - cue.x) / dx);
    else if (dx < -.0001) distance = Math.min(distance, (left + POOL_R - cue.x) / dx);
    if (dy > .0001) distance = Math.min(distance, (bottom - POOL_R - cue.y) / dy);
    else if (dy < -.0001) distance = Math.min(distance, (top + POOL_R - cue.y) / dy);
    for (const ball of game.balls) {
      if (ball.pocketed || ball.id === 0) continue;
      const bx = ball.x - cue.x, by = ball.y - cue.y;
      const along = bx * dx + by * dy;
      if (along <= 0) continue;
      const side = bx * bx + by * by - along * along;
      if (side > 4 * POOL_R * POOL_R) continue;
      distance = Math.min(distance, Math.max(0, along - Math.sqrt(Math.max(0, 4 * POOL_R * POOL_R - side))));
    }
    distance = Math.max(0, distance);
    ctx.save(); ctx.setLineDash([6, 9]); ctx.strokeStyle = '#f9fafbc4'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(cue.x + dx * 12, cue.y + dy * 12);
    ctx.lineTo(cue.x + dx * distance, cue.y + dy * distance); ctx.stroke(); ctx.restore();
    ctx.strokeStyle = '#ffffff77'; ctx.lineWidth = 1.4;
    ctx.beginPath(); ctx.arc(cue.x + dx * distance, cue.y + dy * distance, POOL_R, 0, Math.PI * 2); ctx.stroke();
    const gap = 25 + power * .23;
    const ax = cue.x - dx * gap, ay = cue.y - dy * gap;
    const bx = cue.x - dx * (gap + 143), by = cue.y - dy * (gap + 143);
    ctx.save(); ctx.lineCap = 'round'; ctx.strokeStyle = '#151929aa'; ctx.lineWidth = 12;
    ctx.beginPath(); ctx.moveTo(ax + 2, ay + 3); ctx.lineTo(bx + 2, by + 3); ctx.stroke();
    const cueWood = ctx.createLinearGradient(ax, ay, bx, by);
    cueWood.addColorStop(0, '#f6e2ad'); cueWood.addColorStop(.66, '#cb9161'); cueWood.addColorStop(1, '#764532');
    ctx.strokeStyle = cueWood; ctx.lineWidth = 7;
    ctx.beginPath(); ctx.moveTo(ax, ay); ctx.lineTo(bx, by); ctx.stroke();
    ctx.strokeStyle = '#68d7e6'; ctx.lineWidth = 7;
    ctx.beginPath(); ctx.moveTo(ax, ay); ctx.lineTo(cue.x - dx * (gap + 8), cue.y - dy * (gap + 8)); ctx.stroke();
    ctx.restore();
  }
  for (const ball of game.balls) drawBall(ctx, ball);
  if (game.phase === 'aim' && game.ballInHand && placing) {
    ctx.strokeStyle = '#adf5ce'; ctx.lineWidth = 2.5;
    ctx.beginPath(); ctx.arc(cue.x, cue.y, POOL_R + 10, 0, Math.PI * 2); ctx.stroke();
    ctx.textAlign = 'center'; ctx.font = 'bold 11px system-ui'; ctx.fillStyle = '#d6ffeb';
    ctx.fillText('POSICIONE A BRANCA', 210, 665);
  }
  if (game.phase === 'done') {
    ctx.fillStyle = '#071622a8'; ctx.fillRect(left, 310, right - left, 100);
    ctx.fillStyle = '#fff7d2'; ctx.textAlign = 'center';
    ctx.font = '900 26px system-ui'; ctx.fillText(`JOGADOR ${game.winner! + 1} VENCEU!`, 210, 366);
  }
}
export default function Pool({ onBack, onFinish }: { onBack: () => void; onFinish: () => void }) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const match = useRef<PoolMatch>(newPoolMatch());
  const [view, setView] = useState<View>(() => viewOf(match.current));
  const [power, setPower] = useState(56);
  const powerRef = useRef(56);
  powerRef.current = power;
  const [angle, setAngle] = useState(-Math.PI / 2);
  const aim = useRef(-Math.PI / 2);
  const [placing, setPlacing] = useState(false);
  const placingRef = useRef(false);
  const activePointer = useRef<number | null>(null);
  const finishCallback = useRef(onFinish);
  finishCallback.current = onFinish;
  const sync = () => setView(viewOf(match.current));
  useEffect(() => {
    const element = canvas.current;
    if (!element) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    element.width = POOL_W * dpr; element.height = POOL_H * dpr;
    const ctx = element.getContext('2d');
    if (!ctx) return;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    let frame = 0, previous = 0;
    const loop = (now: number) => {
      const dt = previous ? Math.min((now - previous) / 1000, .034) : 0;
      previous = now;
      if (match.current.phase === 'moving' && stepPool(match.current, dt)) {
        if (match.current.ballInHand) { placingRef.current = true; setPlacing(true); }
        sync();
        if (match.current.winner !== null) finishCallback.current();
      }
      drawTable(ctx, match.current, aim.current, powerRef.current, placingRef.current);
      frame = requestAnimationFrame(loop);
    };
    frame = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(frame);
  }, []);
  const point = (event: PointerEvent<HTMLCanvasElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    return { x: (event.clientX - rect.left) / rect.width * POOL_W,
      y: (event.clientY - rect.top) / rect.height * POOL_H };
  };
  const interact = (event: PointerEvent<HTMLCanvasElement>) => {
    if (match.current.phase !== 'aim') return;
    const { x, y } = point(event);
    if (placingRef.current) { placeCueBall(match.current, x, y); return; }
    const cue = match.current.balls.find(ball => ball.id === 0)!;
    if (Math.hypot(x - cue.x, y - cue.y) < 11) return;
    const next = Math.atan2(y - cue.y, x - cue.x);
    aim.current = next; setAngle(next);
  };
  const pointerDown = (event: PointerEvent<HTMLCanvasElement>) => {
    if (match.current.phase !== 'aim' || activePointer.current !== null) return;
    event.preventDefault(); activePointer.current = event.pointerId;
    event.currentTarget.setPointerCapture(event.pointerId); interact(event);
  };
  const pointerMove = (event: PointerEvent<HTMLCanvasElement>) => {
    if (activePointer.current === event.pointerId) { event.preventDefault(); interact(event); }
  };
  const release = (event: PointerEvent<HTMLCanvasElement>) => {
    if (activePointer.current !== event.pointerId) return;
    activePointer.current = null;
    if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId);
  };
  const rotate = (degrees: number) => {
    const next = aim.current + degrees * Math.PI / 180;
    aim.current = next; setAngle(next);
  };
  const shoot = () => {
    if (placingRef.current) return;
    if (shootPool(match.current, aim.current, powerRef.current)) sync();
  };
  const restart = () => {
    match.current = newPoolMatch(); activePointer.current = null;
    aim.current = -Math.PI / 2; setAngle(aim.current);
    placingRef.current = false; setPlacing(false); setPower(56); powerRef.current = 56;
    sync();
  };
  const shownGroup = (group: PoolGroup | null) => group === 'lisas' ? 'LISAS · 1–7' : group === 'listradas' ? 'LISTRADAS · 9–15' : 'MESA ABERTA';
  return <GameShell title="Sinuca" eyebrow="BOLA 8 · 2 JOGADORES · OFFLINE" onBack={onBack}>
    <div className="pool-score" aria-label="Jogadores e bolas restantes">{([0, 1] as const).map(player =>
      <div key={player} className={'pool-player ' + (view.current === player && view.winner === null ? 'active ' : '') + `player-${player}`}>
        <span className="pool-player-heading"><span className="pool-player-dot"/> JOGADOR {player + 1}</span>
        <strong>{view.groups[player] ? `${view.remaining[player]} restantes` : '7 bolas'}</strong>
        <small>{shownGroup(view.groups[player])}</small>
      </div>
    )}</div>
    <div className="pool-status" role="status" aria-live="polite">
      <span>{view.winner !== null ? <Trophy size={19}/> : <Target size={19}/>}</span>
      <div><strong>{view.winner !== null ? `JOGADOR ${view.winner + 1} VENCEU!` : view.phase === 'moving' ? 'BOLAS EM MOVIMENTO' : `VEZ DO JOGADOR ${view.current + 1}`}</strong>
        <p>{view.message}</p></div>
    </div>
    <div className="pool-controls">
      {view.ballInHand && view.phase === 'aim' && <div className="pool-ball-hand">
        <span>{placing ? 'Arraste na mesa para colocar a bola branca sem encostar nas outras.' : 'Branca posicionada. Pode mirar ou ajustar a posição.'}</span>
        <button type="button" onClick={() => { placingRef.current = !placing; setPlacing(placingRef.current); }}>
          {placing ? 'CONFIRMAR POSIÇÃO' : 'MOVER BRANCA'}</button>
      </div>}
      <div className="pool-aim-row">
        <div className="pool-power"><label htmlFor="pool-power">FORÇA <b>{power}%</b></label>
          <input id="pool-power" type="range" min="10" max="100" step="1" value={power}
            onChange={event => setPower(Number(event.target.value))} disabled={view.phase !== 'aim' || placing}
            aria-label="Força da tacada"/></div>
        <button type="button" className="pool-shoot" onClick={shoot} disabled={view.phase !== 'aim' || placing}>
          <Zap size={20} fill="currentColor"/> TACADA</button>
      </div>
    </div>
    <div className="pool-table-wrap">
      <canvas ref={canvas} aria-label="Mesa de sinuca vertical. Arraste para apontar a tacada. Durante bola livre, arraste para reposicionar a branca."
        onPointerDown={pointerDown} onPointerMove={pointerMove} onPointerUp={release}
        onPointerCancel={release} onLostPointerCapture={release}/>
    </div>
    <div className="pool-precision"><span><Crosshair size={15}/> AJUSTE FINO DA MIRA</span>
      <div><button type="button" onClick={() => rotate(-5)} disabled={view.phase !== 'aim' || placing} aria-label="Girar mira cinco graus à esquerda">− 5°</button>
        <strong>{Math.round((angle * 180 / Math.PI + 3600) % 360)}°</strong>
        <button type="button" onClick={() => rotate(5)} disabled={view.phase !== 'aim' || placing} aria-label="Girar mira cinco graus à direita">+ 5°</button></div></div>
    <div className="pool-rules"><strong>COMO JOGAR</strong><p>Arraste o dedo pela mesa para mirar, ajuste a força e toque em <b>Tacada</b>. A primeira bola encaçapada define lisas ou listradas. Encaçape suas sete bolas e depois a 8 preta para vencer. Encaçapar sua bola mantém a vez; errar passa a vez. Na falta, o adversário reposiciona a branca. Encaçapar a 8 antes da hora perde a partida.</p></div>
    <button className="secondary-btn full" onClick={restart}><RotateCcw size={18}/> {view.winner !== null ? 'Jogar revanche' : 'Reiniciar partida'}</button>
    <p className="hint">Uma mesa, dois amigos. Sem internet, adversários virtuais ou compras. Tacadas: {view.shots}.</p>
  </GameShell>;
}
