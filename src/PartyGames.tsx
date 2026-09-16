import { useEffect, useRef, useState } from 'react';
import { EyeOff, RotateCcw, Trophy } from 'lucide-react';
import { GameShell } from './App';
import type { Player } from './engine';

type Props={onBack:()=>void;onFinish:()=>void};
const other=(n:Player):Player=>n===1?2:1;
const symbols=['🍉','🚀','👾','🎲','⭐','🐸','⚡','🎧'];
function deck(){const items=[...symbols,...symbols].map((value,i)=>({id:i,value}));for(let i=items.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[items[i],items[j]]=[items[j],items[i]];}return items;}
export function MemoryGame({onBack,onFinish}:Props){
  const [cards,setCards]=useState(deck);const [open,setOpen]=useState<number[]>([]);const [matched,setMatched]=useState<number[]>([]);
  const [turn,setTurn]=useState<Player>(1);const [points,setPoints]=useState<[number,number]>([0,0]);const [locked,setLocked]=useState(false);const [done,setDone]=useState(false);
  const timer=useRef<ReturnType<typeof setTimeout>|null>(null);
  useEffect(()=>()=>{if(timer.current)clearTimeout(timer.current);},[]);
  const pick=(index:number)=>{
    if(locked||done||open.includes(index)||matched.includes(index))return;
    if(open.length===0){setOpen([index]);return;}
    const first=open[0];setOpen([first,index]);
    if(cards[first].value===cards[index].value){
      const next=[...matched,first,index];setMatched(next);setPoints(old=>turn===1?[old[0]+1,old[1]]:[old[0],old[1]+1]);setOpen([]);
      if(next.length===16){setDone(true);onFinish();}
    }else{setLocked(true);timer.current=setTimeout(()=>{setOpen([]);setLocked(false);setTurn(prev=>other(prev));timer.current=null;},950);}
  };
  const reset=()=>{if(timer.current)clearTimeout(timer.current);timer.current=null;setCards(deck());setOpen([]);setMatched([]);setTurn(1);setPoints([0,0]);setLocked(false);setDone(false);};
  return <GameShell title="Memória dupla" eyebrow="2 PESSOAS · CONCENTRAÇÃO" onBack={onBack}>
    <div className="duo-score"><span className="player-chip cyan-chip">● JOGADOR 1 <b>{points[0]}</b></span><span className="score-vs">PARES</span><span className="player-chip pink-chip">● JOGADOR 2 <b>{points[1]}</b></span></div>
    <div className="turn-label">{done?points[0]===points[1]?'EMPATE!':`JOGADOR ${points[0]>points[1]?1:2} VENCEU!`:`VEZ DO JOGADOR ${turn}`}</div>
    <div className="memory-board" role="group" aria-label="Cartas do jogo da memória">{cards.map((card,i)=>{const shown=open.includes(i)||matched.includes(i);return <button key={card.id} className={'memory-card '+(shown?'flipped ':'')+(matched.includes(i)?'matched':'')} onClick={()=>pick(i)} disabled={done||locked||shown} aria-label={`Carta ${i+1}: ${shown?card.value:'escondida'}`}>{shown?card.value:'✦'}</button>;})}</div>
    <div className="game-tip"><Trophy size={20}/> Achou o par? Você ganha um ponto e joga novamente.</div>
    <button className="primary-btn full" onClick={reset}><RotateCcw size={18}/> Nova partida</button>
  </GameShell>;
}

type Edge=`h-${number}-${number}`|`v-${number}-${number}`;
const sides=(r:number,c:number):Edge[]=>[`h-${r}-${c}`,`h-${r+1}-${c}`,`v-${r}-${c}`,`v-${r}-${c+1}`];
export function DotsGame({onBack,onFinish}:Props){
  const [edges,setEdges]=useState<Edge[]>([]);const [owners,setOwners]=useState<number[]>(Array(9).fill(0));const [turn,setTurn]=useState<Player>(1);const [done,setDone]=useState(false);
  const points=[owners.filter(o=>o===1).length,owners.filter(o=>o===2).length];
  const put=(edge:Edge)=>{
    if(done||edges.includes(edge))return;
    const nextEdges=[...edges,edge],nextOwners=[...owners];let captured=0;
    for(let r=0;r<3;r++)for(let c=0;c<3;c++){const index=r*3+c;if(!nextOwners[index] && sides(r,c).every(side=>nextEdges.includes(side))){nextOwners[index]=turn;captured++;}}
    setEdges(nextEdges);setOwners(nextOwners);
    if(nextOwners.every(Boolean)){setDone(true);onFinish();}else if(!captured)setTurn(other(turn));
  };
  const reset=()=>{setEdges([]);setOwners(Array(9).fill(0));setTurn(1);setDone(false);};
  const board=[];
  for(let r=0;r<7;r++)for(let c=0;c<7;c++){
    if(r%2===0&&c%2===0)board.push(<div key={`${r}-${c}`} className="dot-node"/>);
    else if(r%2===1&&c%2===1){const owner=owners[Math.floor(r/2)*3+Math.floor(c/2)];board.push(<div key={`${r}-${c}`} className={'dot-box '+(owner===1?'dot-owned-blue':owner===2?'dot-owned-pink':'')}>{owner?owner===1?'★':'♥':''}</div>);}
    else{const id:Edge=r%2===0?`h-${r/2}-${(c-1)/2}`:`v-${(r-1)/2}-${c/2}`;const placed=edges.includes(id);board.push(<button key={id} aria-label={`Linha ${id}`} disabled={placed||done} onClick={()=>put(id)} className={'dot-edge '+(r%2===0?'horizontal':'vertical')+(placed?' placed':'')}/>);}
  }
  return <GameShell title="Pontos e caixas" eyebrow="2 PESSOAS · ESTRATÉGIA" onBack={onBack}>
    <div className="duo-score"><span className="player-chip cyan-chip">● JOGADOR 1 <b>{points[0]}</b></span><span className="score-vs">CAIXAS</span><span className="player-chip pink-chip">● JOGADOR 2 <b>{points[1]}</b></span></div>
    <div className="turn-label">{done?points[0]===points[1]?'EMPATE!':`JOGADOR ${points[0]>points[1]?1:2} VENCEU!`:`VEZ DO JOGADOR ${turn}`}</div>
    <div className="dots-board" role="group" aria-label="Tabuleiro de pontos e caixas">{board}</div>
    <div className="game-tip"><Trophy size={20}/> Toque numa linha. Feche a quarta borda de uma caixa para pontuar e jogar novamente.</div>
    <button className="primary-btn full" onClick={reset}><RotateCcw size={18}/> Nova partida</button>
  </GameShell>;
}

const moves=[{name:'Pedra',emoji:'✊'},{name:'Papel',emoji:'✋'},{name:'Tesoura',emoji:'✌️'}] as const;
export function RpsGame({onBack,onFinish}:Props){
  const [stage,setStage]=useState<'first'|'pass'|'second'|'result'>('first');const [first,setFirst]=useState<number|null>(null);const [second,setSecond]=useState<number|null>(null);const [scores,setScores]=useState<[number,number]>([0,0]);
  const winner=first===null||second===null?0:first===second?3:(first+1)%3===second?2:1;
  const choose=(move:number)=>{if(stage==='first'){setFirst(move);setStage('pass');}else if(stage==='second'&&first!==null){setSecond(move);setStage('result');if(first!==move){const p=(first+1)%3===move?2:1;setScores(old=>p===1?[old[0]+1,old[1]]:[old[0],old[1]+1]);}onFinish();}};
  const reset=()=>{setFirst(null);setSecond(null);setStage('first');};
  return <GameShell title="Pedra, papel, tesoura" eyebrow="2 PESSOAS · ESCOLHAS SECRETAS" onBack={onBack}>
    <div className="duo-score"><span className="player-chip cyan-chip">● JOGADOR 1 <b>{scores[0]}</b></span><span className="score-vs">VS</span><span className="player-chip pink-chip">● JOGADOR 2 <b>{scores[1]}</b></span></div>
    {stage==='pass'?<div className="secret-panel"><EyeOff size={48}/><h2>Escolha guardada!</h2><p>Passe o celular ao jogador 2. A escolha do primeiro jogador ficará escondida.</p><button className="primary-btn full" onClick={()=>setStage('second')}>Sou o jogador 2 →</button></div>:
      stage==='result'?<div className="secret-panel"><span className="result-emoji">{moves[first!].emoji} <span>×</span> {moves[second!].emoji}</span><h2>{winner===3?'Empate!':`Jogador ${winner} venceu!`}</h2><p>{moves[first!].name} contra {moves[second!].name}</p><button className="primary-btn full" onClick={reset}><RotateCcw size={18}/> Jogar novamente</button></div>:
      <><div className="turn-label">JOGADOR {stage==='first'?1:2}: ESCOLHA SUA JOGADA</div><p className="hint centered">A escolha só será revelada depois que os dois jogarem.</p><div className="rps-grid">{moves.map((move,i)=><button className="rps-choice" key={move.name} onClick={()=>choose(i)}><span>{move.emoji}</span><strong>{move.name}</strong></button>)}</div></>}
    <div className="game-tip"><Trophy size={20}/> Pedra vence tesoura, tesoura vence papel, papel vence pedra.</div>
  </GameShell>;
}
