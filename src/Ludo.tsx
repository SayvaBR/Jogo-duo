import { useState } from 'react';
import { RotateCcw, Trophy } from 'lucide-react';
import { LANES, SAFE_TILES, STARTS, TRACK, ludoMove, ludoOptions, ludoPosition, ludoRoll, newLudo } from './engine';
import type { LudoState } from './engine';
import { GameShell } from './App';

const COLORS=['#fc738a','#a78bfa','#5de0a5','#ffc861'];
const NAMES=['CORAL','ROXO','VERDE','AMARELO'];
const DICE=['','⚀','⚁','⚂','⚃','⚄','⚅'];
const xy=(x:number,y:number)=>`${x},${y}`;
const trackByPosition=new Map(TRACK.map(([x,y],index)=>[xy(x,y),index]));
const lanesByPosition=new Map(LANES.flatMap((lane,player)=>lane.map(([x,y])=>[xy(x,y),player] as const)));
function tileColor(col:number,row:number){
  const track=trackByPosition.get(xy(col,row));
  if(track!==undefined){const start=STARTS.indexOf(track as typeof STARTS[number]);if(start!==-1)return COLORS[start];return SAFE_TILES.has(track)?'#e3dcff':'#eff1ff';}
  const lane=lanesByPosition.get(xy(col,row));if(lane!==undefined)return COLORS[lane];
  if(col>=6&&col<=8&&row>=6&&row<=8)return '#ffebaa';
  if(col<6&&row>8)return '#fbd0d8';if(col<6&&row<6)return '#ddd1ff';
  if(col>8&&row<6)return '#cdf7e0';if(col>8&&row>8)return '#ffe7ac';
  return '#fff';
}
export function LudoGame({onBack,onFinish}:{onBack:()=>void;onFinish:()=>void}){
  const [count,setCount]=useState<2|3|4>(2);
  const [game,setGame]=useState<LudoState>(()=>newLudo(2));
  const options=ludoOptions(game);
  const roll=()=>setGame(previous=>ludoRoll(previous,1+Math.floor(Math.random()*6)));
  const move=(token:number)=>{const next=ludoMove(game,token);if(next===game)return;setGame(next);if(next.winner!==null&&game.winner===null)onFinish();};
  const setPlayers=(n:2|3|4)=>{setCount(n);setGame(newLudo(n));};
  return <GameShell title="Ludo" eyebrow="2 A 4 PESSOAS · MESMO APARELHO" onBack={onBack}>
    <div className="ludo-players" role="group" aria-label="Quantidade de jogadores">{([2,3,4] as const).map(n=><button key={n} className={count===n?'active':''} onClick={()=>setPlayers(n)} aria-pressed={count===n}>{n} jogadores</button>)}</div>
    <div className="turn-label" style={{color:COLORS[game.current]}}>{game.winner===null?`VEZ: ${NAMES[game.current]}`:`${NAMES[game.winner]} VENCEU!`}</div>
    <div className="ludo-board" role="group" aria-label="Tabuleiro de Ludo com peças selecionáveis">
      {Array.from({length:225},(_,i)=>{const col=i%15,row=Math.floor(i/15);return <div className="ludo-tile" key={i} style={{background:tileColor(col,row)}}/>;})}
      {game.players.flatMap(player=>game.tokens[player].map((progress,index)=>{const [x,y]=ludoPosition(player,progress,index);const available=player===game.current&&options.includes(index);return <button key={`${player}-${index}`} className={'ludo-token '+(available?'available':'')} style={{left:`${(x+.5)/15*100}%`,top:`${(y+.5)/15*100}%`,backgroundColor:COLORS[player],marginLeft:progress===56?(index-1.5)*7:0,marginTop:progress===56?(player-1.5)*5:0}} aria-label={`${NAMES[player]}, peça ${index+1}, posição ${progress===-1?'casa':progress===56?'final':progress+1}${available?', toque para mover':''}`} disabled={!available} onClick={()=>move(index)}>{index+1}</button>;}))}
    </div>
    <div className="ludo-panel"><button className="die-button" disabled={game.phase!=='roll'} onClick={roll} aria-label="Lançar dado"><span>{DICE[game.die||0]||'⚄'}</span><small>{game.phase==='roll'?'LANÇAR DADO':game.die?`SAIU ${game.die}`:'FIM'}</small></button><div className="ludo-instructions"><strong>{game.message}</strong><p>{game.phase==='move'?'Peças disponíveis estão brilhando. Toque em uma delas.':'Tire 6 para tirar uma peça da base. São necessárias 4 peças no centro para vencer.'}</p></div></div>
    <div className="game-tip"><Trophy size={20}/> Regras: saída com 6, captura fora das casas seguras, chegada exata e turno extra com 6 ou captura.</div>
    <button className="secondary-btn full" onClick={()=>setGame(newLudo(count))}><RotateCcw size={18}/> Reiniciar partida</button>
  </GameShell>;
}
