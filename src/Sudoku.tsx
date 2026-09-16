import { useState } from 'react';
import { Check, Eraser, Lightbulb, Pencil, RotateCcw, Trophy } from 'lucide-react';
import { makeSudoku, sudokuConflicts, sudokuSolved } from './engine';
import type { SudokuPuzzle } from './engine';
import { GameShell } from './App';

export function SudokuGame({onBack,onFinish}:{onBack:()=>void;onFinish:()=>void}){
  const [puzzle,setPuzzle]=useState<SudokuPuzzle>(()=>makeSudoku());
  const [board,setBoard]=useState<number[]>(()=>[...puzzle.puzzle]);
  const [selected,setSelected]=useState<number>(()=>puzzle.puzzle.findIndex(x=>!x));
  const [notes,setNotes]=useState<Record<number,number[]>>({});
  const [pencil,setPencil]=useState(false);const [hints,setHints]=useState(3);
  const [done,setDone]=useState(false);const [message,setMessage]=useState('Preencha os espaços vazios de 1 a 9.');
  const filled=board.filter(Boolean).length;
  const apply=(index:number,num:number)=>{
    if(done||index<0||puzzle.puzzle[index])return;
    if(pencil&&num){setNotes(old=>{const values=old[index]||[];return {...old,[index]:values.includes(num)?values.filter(v=>v!==num):[...values,num].sort()};});return;}
    const next=[...board];next[index]=num;setBoard(next);setNotes(old=>({...old,[index]:[]}));setMessage('');
    if(sudokuSolved(next,puzzle.solution)){setDone(true);setMessage('Parabéns! Sudoku resolvido.');onFinish();}
  };
  const hint=()=>{
    if(done||!hints)return;
    const idx=selected>=0&&!puzzle.puzzle[selected]&&board[selected]!==puzzle.solution[selected]?selected:board.findIndex((n,i)=>n!==puzzle.solution[i]);
    if(idx<0)return;
    const next=[...board];next[idx]=puzzle.solution[idx];setBoard(next);setSelected(idx);setHints(n=>n-1);setNotes(old=>({...old,[idx]:[]}));setMessage('Uma casa foi preenchida com a solução correta.');
    if(sudokuSolved(next,puzzle.solution)){setDone(true);setMessage('Parabéns! Sudoku resolvido.');onFinish();}
  };
  const check=()=>{const mistakes=board.filter((n,i)=>n!==0&&n!==puzzle.solution[i]).length;setMessage(mistakes?`${mistakes} ${mistakes===1?'número precisa':'números precisam'} de revisão.`:'Até aqui, todos os números estão corretos!');};
  const reset=()=>{const next=makeSudoku();setPuzzle(next);setBoard([...next.puzzle]);setSelected(next.puzzle.findIndex(n=>!n));setNotes({});setPencil(false);setHints(3);setDone(false);setMessage('Novo tabuleiro pronto. Boa sorte!');};
  return <GameShell title="Sudoku" eyebrow="SOLO · DESAFIO DE LÓGICA" onBack={onBack}>
    <div className="sudoku-top"><span className="progress-pill">{filled}/81 CASAS</span><span className="muted">DESAFIO CLÁSSICO</span><button className="text-button" onClick={reset}><RotateCcw size={15}/> Novo</button></div>
    <div className="sudoku-board" role="group" aria-label="Tabuleiro de sudoku">{board.map((value,i)=>{
      const fixed=Boolean(puzzle.puzzle[i]);const selectedRow=Math.floor(selected/9)===Math.floor(i/9);const selectedCol=selected%9===i%9;const related=selected>=0&&(selectedRow||selectedCol||Math.floor(i/27)===Math.floor(selected/27)&&Math.floor(i%9/3)===Math.floor(selected%9/3));
      const conflict=sudokuConflicts(board,i).length>0;
      return <button key={i} className={'sudoku-cell '+(fixed?'fixed ':'')+(selected===i?'selected ':'')+(related?'related ':'')+(conflict?'conflict ':'')+(i%9===2||i%9===5?'box-right ':'')+(Math.floor(i/9)===2||Math.floor(i/9)===5?'box-bottom ':'')} onClick={()=>setSelected(i)} aria-label={`Linha ${Math.floor(i/9)+1}, coluna ${i%9+1}: ${value||'vazio'}${fixed?', número fixo':''}`}>
        {value?<strong>{value}</strong>:notes[i]?.length?<span className="sudoku-notes">{Array.from({length:9},(_,n)=><span key={n}>{notes[i].includes(n+1)?n+1:''}</span>)}</span>:null}
      </button>;
    })}</div>
    <div className={'sudoku-feedback '+(done?'success':'')} aria-live="polite">{done?<Trophy size={18}/>:<Lightbulb size={18}/>} {message||'Selecione uma casa e toque em um número.'}</div>
    <div className="sudoku-numbers" role="group" aria-label="Inserir número">{Array.from({length:9},(_,i)=><button key={i} onClick={()=>apply(selected,i+1)} disabled={done||selected<0||Boolean(puzzle.puzzle[selected])}>{i+1}</button>)}</div>
    <div className="sudoku-tools"><button className={pencil?'tool-button active':'tool-button'} onClick={()=>setPencil(v=>!v)} aria-pressed={pencil}><Pencil size={19}/> Notas</button><button className="tool-button" onClick={()=>apply(selected,0)} disabled={done}><Eraser size={19}/> Apagar</button><button className="tool-button" onClick={hint} disabled={done||!hints}><Lightbulb size={19}/> Dica ({hints})</button><button className="tool-button" onClick={check} disabled={done}><Check size={19}/> Conferir</button></div>
    <p className="hint">Cada linha, coluna e bloco 3×3 deve conter todos os números de 1 a 9 sem repetição.</p>
  </GameShell>;
}
