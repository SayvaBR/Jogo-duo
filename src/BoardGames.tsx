import { useState } from 'react';
import { RotateCcw, Trophy } from 'lucide-react';
import { fourDrop, fourOutcome, ticMove, ticOutcome } from './engine';
import type { Mark, Player } from './engine';
import { GameShell } from './App';

type Props={onBack:()=>void;onFinish:()=>void};
const opponent=(p:Player):Player=>p===1?2:1;
const EMPTY_TIC=()=>Array<Mark>(9).fill(0);
const EMPTY_FOUR=()=>Array<Mark>(42).fill(0);
function Score({scores}:{scores:[number,number]}){return <div className="duo-score"><span className="player-chip cyan-chip">● JOGADOR 1 <b>{scores[0]}</b></span><span className="score-vs">VS</span><span className="player-chip pink-chip">● JOGADOR 2 <b>{scores[1]}</b></span></div>;}
export function TicTacToe({onBack,onFinish}:Props){
  const [board,setBoard]=useState<Mark[]>(EMPTY_TIC);const [turn,setTurn]=useState<Player>(1);const [scores,setScores]=useState<[number,number]>([0,0]);
  const outcome=ticOutcome(board);
  const place=(index:number)=>{const next=ticMove(board,index,turn);if(!next)return;setBoard(next);const result=ticOutcome(next);if(result){onFinish();if(result!==3)setScores(old=>result===1?[old[0]+1,old[1]]:[old[0],old[1]+1]);}else setTurn(opponent(turn));};
  const reset=()=>{setBoard(EMPTY_TIC());setTurn(1);};
  return <GameShell title="Jogo da velha" eyebrow="2 PESSOAS · CLÁSSICO" onBack={onBack}>
    <Score scores={scores}/><div className="turn-label">{outcome===3?'EMPATE!':outcome?`JOGADOR ${outcome} VENCEU!`:`VEZ DO JOGADOR ${turn}`}</div>
    <div className="tic-grid" role="group" aria-label="Tabuleiro de jogo da velha">{board.map((mark,i)=><button key={i} className={'tic-cell '+(mark===1?'tic-x':mark===2?'tic-o':'')} onClick={()=>place(i)} disabled={Boolean(mark||outcome)} aria-label={`Casa ${i+1}: ${mark===1?'X':mark===2?'O':'vazia'}`}>{mark===1?'✕':mark===2?'◯':''}</button>)}</div>
    <div className="game-tip"><Trophy size={20}/> Alinhe 3 símbolos na horizontal, vertical ou diagonal.</div>
    <button className="primary-btn full" onClick={reset}><RotateCcw size={18}/>{outcome?'Próxima rodada':'Reiniciar rodada'}</button>
  </GameShell>;
}
export function ConnectFour({onBack,onFinish}:Props){
  const [board,setBoard]=useState<Mark[]>(EMPTY_FOUR);const [turn,setTurn]=useState<Player>(1);const [scores,setScores]=useState<[number,number]>([0,0]);
  const outcome=fourOutcome(board);
  const drop=(col:number)=>{const next=fourDrop(board,col,turn);if(!next)return;setBoard(next);const result=fourOutcome(next);if(result){onFinish();if(result!==3)setScores(old=>result===1?[old[0]+1,old[1]]:[old[0],old[1]+1]);}else setTurn(opponent(turn));};
  const reset=()=>{setBoard(EMPTY_FOUR());setTurn(1);};
  return <GameShell title="Ligue 4" eyebrow="2 PESSOAS · ESTRATÉGIA" onBack={onBack}>
    <Score scores={scores}/><div className="turn-label">{outcome===3?'EMPATE!':outcome?`JOGADOR ${outcome} VENCEU!`:`VEZ DO JOGADOR ${turn} · ${turn===1?'AZUL':'ROSA'}`}</div>
    <div className="four-board" role="group" aria-label="Tabuleiro de Ligue 4">{Array.from({length:7},(_,col)=><button key={col} className="four-column" disabled={Boolean(outcome||board[col])} aria-label={`Soltar peça na coluna ${col+1}`} onClick={()=>drop(col)}><span className="four-arrow">⌄</span>{Array.from({length:6},(_,row)=><span key={row} className={'four-hole '+(board[row*7+col]===1?'blue-hole':board[row*7+col]===2?'pink-hole':'')}/>)}</button>)}</div>
    <div className="game-tip"><Trophy size={20}/> Conecte 4 peças na mesma linha, coluna ou diagonal.</div>
    <button className="primary-btn full" onClick={reset}><RotateCcw size={18}/>{outcome?'Próxima rodada':'Reiniciar rodada'}</button>
  </GameShell>;
}
