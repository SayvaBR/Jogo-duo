import { describe, expect, it } from 'vitest';
import { fourDrop, fourOutcome, ludoMove, ludoOptions, ludoPosition, ludoRoll, makeSudoku, newLudo, sudokuConflicts, sudokuSolved, ticMove, ticOutcome, TRACK, STARTS } from './engine';
import type { Mark, LudoState } from './engine';

describe('Jogo da velha',()=>{
  it('não permite jogar em casa ocupada',()=>{const empty=Array<Mark>(9).fill(0);const one=ticMove(empty,0,1)!;expect(one[0]).toBe(1);expect(empty[0]).toBe(0);expect(ticMove(one,0,2)).toBeNull();});
  it('reconhece vitória e bloqueia jogadas depois da vitória',()=>{const board:Mark[]=[1,1,1,2,2,0,0,0,0];expect(ticOutcome(board)).toBe(1);expect(ticMove(board,8,2)).toBeNull();});
  it('reconhece empate',()=>expect(ticOutcome([1,2,1,1,2,2,2,1,1])).toBe(3));
});
describe('Ligue 4',()=>{
  it('deixa a peça cair na primeira casa livre de baixo para cima',()=>{const b=Array<Mark>(42).fill(0);const a=fourDrop(b,3,1)!;expect(a[5*7+3]).toBe(1);expect(fourDrop(a,3,2)![4*7+3]).toBe(2);expect(b.every(n=>n===0)).toBe(true);});
  it('detecta alinhamento horizontal, vertical e diagonal',()=>{
    const h=Array<Mark>(42).fill(0);[0,1,2,3].forEach(c=>h[5*7+c]=1);expect(fourOutcome(h)).toBe(1);
    const v=Array<Mark>(42).fill(0);[1,2,3,4].forEach(r=>v[r*7+4]=2);expect(fourOutcome(v)).toBe(2);
    const d=Array<Mark>(42).fill(0);[0,1,2,3].forEach(k=>d[(2+k)*7+k]=1);expect(fourOutcome(d)).toBe(1);
  });
  it('rejeita coluna cheia e coluna inexistente',()=>{const b=Array<Mark>(42).fill(0);for(let r=0;r<6;r++)b[r*7]=r%2?1:2;expect(fourDrop(b,0,1)).toBeNull();expect(fourDrop(b,-1,1)).toBeNull();});
});
describe('Ludo',()=>{
  it('tem exatamente 52 casas externas e posições de partida opostas para dois jogadores',()=>{expect(TRACK).toHaveLength(52);expect(new Set(TRACK.map(p=>p.join(','))).size).toBe(52);expect(STARTS).toEqual([0,13,26,39]);expect(newLudo(2).players).toEqual([0,2]);});
  it('só tira peça da base com seis, com vez extra',()=>{const game=newLudo(2);expect(ludoRoll(game,1).current).toBe(2);const six=ludoRoll(game,6);expect(ludoOptions(six)).toEqual([0,1,2,3]);const moved=ludoMove(six,0);expect(moved.tokens[0][0]).toBe(0);expect(moved.current).toBe(0);expect(moved.phase).toBe('roll');});
  it('terceiro seis consecutivo perde a vez',()=>{const prior={...newLudo(2),sixes:2};const after=ludoRoll(prior,6);expect(after.current).toBe(2);expect(after.sixes).toBe(0);});
  it('captura fora das casas seguras e concede nova jogada',()=>{const game:LudoState={...newLudo(2),die:1,phase:'move',tokens:[[3,-1,-1,-1],[-1,-1,-1,-1],[30,-1,-1,-1],[-1,-1,-1,-1]]};const after=ludoMove(game,0);expect(after.tokens[0][0]).toBe(4);expect(after.tokens[2][0]).toBe(-1);expect(after.phase).toBe('roll');expect(after.current).toBe(0);});
  it('exige número exato para finalizar e não move peça já concluída',()=>{const game:LudoState={...newLudo(2),die:2,phase:'move',tokens:[[55,56,56,56],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]]};expect(ludoOptions(game)).toEqual([]);expect(ludoPosition(0,56,0)).toEqual([7,7]);const final={...game,die:1};expect(ludoMove(final,0).winner).toBe(0);});
});
describe('Sudoku',()=>{
  it('faz permutações sem modificar pistas ou a solução correspondente',()=>{for(let seed=0;seed<10;seed++){let n=seed+1;const result=makeSudoku(()=>{n=(Math.imul(1664525,n)+1013904223)>>>0;return n/4294967296;});expect(result.puzzle).toHaveLength(81);expect(result.solution).toHaveLength(81);expect(result.puzzle.every((v,i)=>!v||v===result.solution[i])).toBe(true);for(let i=0;i<81;i++)expect(sudokuConflicts(result.solution,i)).toHaveLength(0);expect(sudokuSolved(result.solution,result.solution)).toBe(true);}});
  it('identifica repetição e recusa tabuleiro incompleto',()=>{const board=Array<number>(81).fill(0);board[0]=5;board[1]=5;expect(sudokuConflicts(board,0)).toContain(1);expect(sudokuSolved(board,Array<number>(81).fill(5))).toBe(false);});
});
