import { useEffect, useRef, useState } from 'react';
import { Crown, Dice6, RotateCcw, ShieldCheck, Sparkles, Trophy } from 'lucide-react';
import { LANES, SAFE_TILES, STARTS, TRACK, ludoOptions, ludoPosition } from './engine';
import { bankSix, canBankSix, chooseComboDie, comboMove, comboRoll, newComboLudo } from './ludoCombo';
import type { ComboLudoState } from './ludoCombo';
import { GameShell } from './App';

const COLORS=['#ff6f91','#a78bfa','#5de0a5','#ffce65'];
const NAMES=['CORAL','ROXO','VERDE','AMARELO'];
const PIPS:Record<number,number[]>={1:[4],2:[0,8],3:[0,4,8],4:[0,2,6,8],5:[0,2,4,6,8],6:[0,2,3,5,6,8]};
const xy=(x:number,y:number)=>`${x},${y}`;
const trackByPosition=new Map(TRACK.map(([x,y],index)=>[xy(x,y),index]));
const lanesByPosition=new Map(LANES.flatMap((lane,player)=>lane.map(([x,y])=>[xy(x,y),player] as const)));
function tileColor(col:number,row:number){
  const track=trackByPosition.get(xy(col,row));
  if(track!==undefined){const start=STARTS.indexOf(track as typeof STARTS[number]);if(start!==-1)return COLORS[start];return SAFE_TILES.has(track)?'#e7dcff':'#f5f4ff';}
  const lane=lanesByPosition.get(xy(col,row));if(lane!==undefined)return COLORS[lane];
  if(col>=6&&col<=8&&row>=6&&row<=8)return '#25223f';
  if(col<6&&row>8)return '#ffe1e8';if(col<6&&row<6)return '#eae2ff';
  if(col>8&&row<6)return '#d5f9e7';if(col>8&&row>8)return '#fff0ca';
  return '#fff';
}
function DieFace({value}:{value:number}){return <span className="ludo-die-face" aria-label={`Dado: ${value}`}>{Array.from({length:9},(_,index)=><i key={index} className={(PIPS[value]||[]).includes(index)?'filled':''}/>)}</span>;}
export function LudoGame({onBack,onFinish}:{onBack:()=>void;onFinish:()=>void}){
  const [count,setCount]=useState<2|3|4>(2);
  const [game,setGame]=useState<ComboLudoState>(()=>newComboLudo(2));
  const [visual,setVisual]=useState<number[][]>(()=>newComboLudo(2).tokens);
  const [comboEnabled,setComboEnabled]=useState(true);
  const [animating,setAnimating]=useState(false);
  const [movingToken,setMovingToken]=useState<number|null>(null);
  const [effect,setEffect]=useState<'capture'|'six'|'home'|'win'|null>(null);
  const timer=useRef<ReturnType<typeof setTimeout>|null>(null);
  useEffect(()=>()=>{if(timer.current!==null)clearTimeout(timer.current);},[]);
  const stopTimer=()=>{if(timer.current!==null)clearTimeout(timer.current);timer.current=null;};
  const restart=(n:2|3|4=count)=>{stopTimer();const fresh=newComboLudo(n);setCount(n);setGame(fresh);setVisual(fresh.tokens);setAnimating(false);setMovingToken(null);setEffect(null);};
  const roll=()=>{
    if(animating||game.phase!=='roll')return;
    const value=1+Math.floor(Math.random()*6);
    setEffect(null);
    setGame(old=>comboRoll(old,value));
  };
  const options=ludoOptions(game);
  const move=(token:number)=>{
    if(animating||!options.includes(token))return;
    const next=comboMove(game,token);if(next===game)return;
    const player=game.current,start=game.tokens[player][token],end=next.tokens[player][token];
    const captured=next.tokens.some((row,p)=>p!==player&&row.some((value,i)=>value===-1&&game.tokens[p][i]!==-1));
    const used=game.die;
    setAnimating(true);setMovingToken(token);setEffect(null);
    let progress=start;
    const tick=()=>{
      progress++;
      setVisual(old=>{const rows=old.map(row=>[...row]);rows[player][token]=progress;return rows;});
      if(progress<end)timer.current=setTimeout(tick,155);
      else timer.current=setTimeout(()=>{
        setVisual(next.tokens);setGame(next);setAnimating(false);setMovingToken(null);
        setEffect(next.winner!==null?'win':captured?'capture':end===56?'home':used===6?'six':null);
        if(next.winner!==null)onFinish();
        timer.current=null;
      },210);
    };
    timer.current=setTimeout(tick,110);
  };
  const busy=animating;
  const pieces=game.players.flatMap(player=>visual[player].map((progress,index)=>{const [x,y]=ludoPosition(player,progress,index);return {player,progress,index,x,y,key:xy(x,y)};}));
  const groups=new Map<string,typeof pieces>();for(const piece of pieces)groups.set(piece.key,[...(groups.get(piece.key)||[]),piece]);
  const showCombo=game.phase==='move'&&game.combined&&game.die!==null&&game.banked.length===1;
  return <GameShell title="Ludo" eyebrow="A GRANDE CORRIDA · 2 A 4 AMIGOS" onBack={onBack}>
    <div className="ludo-players" role="group" aria-label="Quantidade de jogadores">{([2,3,4] as const).map(n=><button key={n} className={count===n?'active':''} disabled={busy} onClick={()=>restart(n)} aria-pressed={count===n}>{n} jogadores</button>)}</div>
    <div className="ludo-variant"><div><strong>🎲 Dados combinados</strong><small>Guarde o 6, lance de novo e distribua os dois valores.</small></div><button className={comboEnabled?'enabled':''} type="button" disabled={busy||game.combined} aria-pressed={comboEnabled} onClick={()=>setComboEnabled(value=>!value)}>{comboEnabled?'ATIVADO':'DESATIVADO'}</button></div>
    <div className="ludo-scoreboard" aria-label="Progresso dos jogadores">{game.players.map(player=><div key={player} className={'ludo-score-chip '+(game.current===player&&game.winner===null?'is-turn':'')} style={{borderColor:game.current===player?COLORS[player]:undefined}}><span className="ludo-player-dot" style={{background:COLORS[player]}}/><span>{NAMES[player]}</span><strong>{game.tokens[player].filter(p=>p===56).length}/4</strong></div>)}</div>
    <div className="ludo-turn-card" style={{borderColor:COLORS[game.current],backgroundColor:`${COLORS[game.current]}19`}} aria-live="polite"><span className="ludo-turn-dot" style={{background:COLORS[game.current]}}/><div><small>{game.winner===null?'AGORA É A VEZ DE':'PARTIDA ENCERRADA'}</small><strong>{game.winner===null?NAMES[game.current]:`${NAMES[game.winner]} VENCEU!`}</strong></div>{game.winner===null?<span className="ludo-turn-icon">{game.phase==='roll'?'🎲':'➜'}</span>:<Crown size={27} color={COLORS[game.winner]}/>}</div>
    <div className={'ludo-board ludo-board-premium '+(animating?'is-animating':'')} role="group" aria-label="Tabuleiro de Ludo. As peças disponíveis têm destaque e também aparecem nos botões abaixo.">
      {Array.from({length:225},(_,i)=>{const col=i%15,row=Math.floor(i/15),track=trackByPosition.get(xy(col,row));const start=track!==undefined?STARTS.indexOf(track as typeof STARTS[number]):-1;return <div className={'ludo-tile '+(start>=0?'start-tile ':'')+(track!==undefined&&SAFE_TILES.has(track)?'safe-tile':'')} key={i} style={{background:tileColor(col,row)}} aria-hidden="true">{start>=0?'➤':track!==undefined&&SAFE_TILES.has(track)?'★':null}</div>;})}
      <div className="ludo-center" aria-hidden="true"><span>★</span></div>
      {!busy&&game.phase==='move'&&game.die!==null&&options.map(index=>{const current=game.tokens[game.current][index],target=current===-1?0:current+game.die!;const [x,y]=ludoPosition(game.current,target,index);return <span key={index} className="ludo-target" style={{left:`${(x+.5)/15*100}%`,top:`${(y+.5)/15*100}%`,borderColor:COLORS[game.current]}} aria-hidden="true"/>;})}
      {pieces.map(piece=>{const stack=groups.get(piece.key)||[],slot=stack.findIndex(item=>item.player===piece.player&&item.index===piece.index);const center=piece.progress===56;const spread=center?.53:.31;const dx=stack.length===1?0:((slot%(center?4:2))-(center?1.5:.5))*spread;const dy=stack.length===1?0:(Math.floor(slot/(center?4:2))-(center?1.5:stack.length>2?.5:0))*spread;
        const available=!busy&&piece.player===game.current&&options.includes(piece.index);return <button key={`${piece.player}-${piece.index}`} className={'ludo-token ludo-token-premium '+(available?'available ':'')+(animating&&piece.player===game.current&&movingToken===piece.index?'in-motion':'')} style={{left:`${(piece.x+.5+dx)/15*100}%`,top:`${(piece.y+.5+dy)/15*100}%`,backgroundColor:COLORS[piece.player]}} aria-label={`${NAMES[piece.player]}, peça ${piece.index+1}, ${piece.progress===-1?'na base':piece.progress===56?'no centro':`casa ${piece.progress+1}`}${available?', toque para mover':''}`} disabled={!available} onClick={()=>move(piece.index)}><span className="ludo-token-shine"/><span className="ludo-token-number">{piece.index+1}</span></button>;})}
      {effect==='capture'&&<div className="ludo-board-flash" aria-hidden="true">CAPTURA!</div>}
      {game.winner!==null&&<div className="ludo-win-overlay" aria-hidden="true">{Array.from({length:20},(_,i)=><span key={i} style={{left:`${(i*37)%97}%`,animationDelay:`${(i%7)*-.17}s`,backgroundColor:COLORS[i%4]}}/>)}</div>}
    </div>
    {showCombo&&<div className="ludo-dice-tray" role="group" aria-label="Escolha qual valor de dado usar primeiro"><strong>SEUS DADOS · escolha a ordem</strong><div><button className="chosen" aria-pressed="true" disabled={busy} onClick={()=>{}}><DieFace value={game.die!}/>Usar {game.die}</button><button aria-pressed="false" disabled={busy} onClick={()=>setGame(old=>chooseComboDie(old))}><DieFace value={game.banked[0]}/>Usar {game.banked[0]}</button></div></div>}
    {game.phase==='move'&&!busy&&options.length>0&&<div className="ludo-piece-picker"><strong>QUAL PEÇA VAI ANDAR {game.die} {game.die===1?'CASA':'CASAS'}?</strong><div>{options.map(index=><button key={index} onClick={()=>move(index)} style={{borderColor:COLORS[game.current]}} aria-label={`Mover peça ${index+1} com dado ${game.die}`}>PEÇA <b>{index+1}</b></button>)}</div></div>}
    {comboEnabled&&!busy&&canBankSix(game)&&<button className="ludo-bank-button" onClick={()=>{setGame(old=>bankSix(old));setEffect('six');}}><Dice6 size={21}/> Guardar o 6 e lançar novamente <span>6 + ? →</span></button>}
    <div className="ludo-panel ludo-panel-premium"><button className="die-button ludo-roll" disabled={busy||game.phase!=='roll'} onClick={roll} aria-label={game.banked.length?'Lançar segundo dado':'Lançar dado'}><DieFace value={game.die||5}/><small>{game.phase==='roll'?game.banked.length?'LANÇAR 2º DADO':'LANÇAR DADO':game.die?`SAIU ${game.die}`:'AGUARDE'}</small></button><div className="ludo-instructions" aria-live="polite"><span className="ludo-status-eyebrow">{animating?'PEÇA EM MOVIMENTO':effect==='capture'?'CAPTURA!':effect==='six'?'SEIS!':effect==='home'?'CHEGOU!':effect==='win'?'VITÓRIA!':game.combined?'DADOS COMBINADOS':'SUA JOGADA'}</span><strong>{animating?'Acompanhe o peão, casa por casa.':game.message}</strong><p>{game.winner!==null?'Que tal uma revanche?':showCombo?'Selecione 6 ou o outro valor; depois toque na peça escolhida.':game.phase==='move'?'Peças pulsando podem jogar. O círculo marca o destino.':'Tire 6 para sair da base. Capture fora das casas seguras.'}</p></div></div>
    <div className="ludo-rule-pills"><span><ShieldCheck size={15}/> ★ Casa segura</span><span><Sparkles size={15}/> 6 dá nova jogada</span><span><Trophy size={15}/> 4 peças para vencer</span></div>
    <button className="secondary-btn full" disabled={busy} onClick={()=>restart()}><RotateCcw size={18}/>{game.winner!==null?'Jogar revanche':'Reiniciar partida'}</button>
    <p className="hint">Modo da casa opcional: com pelo menos 2 peças em jogo, guarde um 6 e lance outra vez; cada dado move uma peça à sua escolha. Três seis seguidos encerram a vez.</p>
  </GameShell>;
}
