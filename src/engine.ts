// Pure, dependency-free rules. The UI never decides whether a move is legal.
export type Player = 1 | 2;
export type Mark = 0 | Player;
export type Outcome = 0 | Player | 3; // 3 = draw
export const TTT_LINES = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]] as const;
export function ticOutcome(board: readonly Mark[]): Outcome {
  for (const [a,b,c] of TTT_LINES) if (board[a] && board[a] === board[b] && board[a] === board[c]) return board[a];
  return board.every(Boolean) ? 3 : 0;
}
export function ticMove(board: readonly Mark[], index: number, turn: Player): Mark[] | null {
  if (board.length !== 9 || !Number.isInteger(index) || index < 0 || index > 8 || board[index] || ticOutcome(board)) return null;
  const next = [...board]; next[index] = turn; return next;
}

export type FourBoard = Mark[];
export function fourOutcome(board: readonly Mark[]): Outcome {
  for (let r=0;r<6;r++) for(let c=0;c<7;c++) {
    const p = board[r*7+c]; if (!p) continue;
    for (const [dr,dc] of [[1,0],[0,1],[1,1],[1,-1]]) {
      if ([1,2,3].every(k => r+dr*k>=0 && r+dr*k<6 && c+dc*k>=0 && c+dc*k<7 && board[(r+dr*k)*7+c+dc*k]===p)) return p;
    }
  }
  return board.every(Boolean) ? 3 : 0;
}
export function fourDrop(board: readonly Mark[], column: number, turn: Player): FourBoard | null {
  if (board.length !== 42 || !Number.isInteger(column) || column<0 || column>6 || board[column] || fourOutcome(board)) return null;
  const next = [...board];
  for(let row=5;row>=0;row--) if(!next[row*7+column]) { next[row*7+column]=turn; return next; }
  return null;
}

// 52 outer tiles, five private home tiles and one finishing step per token.
export const TRACK: readonly [number,number][] = [
  [6,13],[6,12],[6,11],[6,10],[6,9],[5,8],[4,8],[3,8],[2,8],[1,8],[0,8],[0,7],[0,6],
  [1,6],[2,6],[3,6],[4,6],[5,6],[6,5],[6,4],[6,3],[6,2],[6,1],[6,0],[7,0],[8,0],
  [8,1],[8,2],[8,3],[8,4],[8,5],[9,6],[10,6],[11,6],[12,6],[13,6],[14,6],[14,7],[14,8],
  [13,8],[12,8],[11,8],[10,8],[9,8],[8,9],[8,10],[8,11],[8,12],[8,13],[8,14],[7,14],[6,14]
];
export const STARTS = [0,13,26,39] as const;
export const LANES: readonly (readonly [number,number][])[] = [
  [[7,13],[7,12],[7,11],[7,10],[7,9]],
  [[1,7],[2,7],[3,7],[4,7],[5,7]],
  [[7,1],[7,2],[7,3],[7,4],[7,5]],
  [[13,7],[12,7],[11,7],[10,7],[9,7]]
];
export const YARDS: readonly (readonly [number,number][])[] = [
  [[1,10],[4,10],[1,13],[4,13]],
  [[1,1],[4,1],[1,4],[4,4]],
  [[10,1],[13,1],[10,4],[13,4]],
  [[10,10],[13,10],[10,13],[13,13]]
];
export const SAFE_TILES = new Set([0,8,13,21,26,34,39,47]);
export type LudoPhase = 'roll'|'move'|'done';
export interface LudoState {
  players: number[];
  tokens: number[][];
  current: number;
  die: number | null;
  sixes: number;
  phase: LudoPhase;
  winner: number | null;
  message: string;
}
export function newLudo(count: 2|3|4): LudoState {
  const players = count===2 ? [0,2] : count===3 ? [0,1,2] : [0,1,2,3];
  return {players,tokens:Array.from({length:4},()=>[-1,-1,-1,-1]),current:players[0],die:null,sixes:0,phase:'roll',winner:null,message:'Toque no dado para começar.'};
}
export function ludoOptions(state:LudoState): number[] {
  if(state.phase!=='move' || state.die===null) return [];
  return state.tokens[state.current].flatMap((pos,i) => pos===56 || pos===-1 && state.die!==6 || pos>=0 && pos+state.die>56 ? [] : [i]);
}
export function nextLudo(state:LudoState): LudoState {
  const idx=state.players.indexOf(state.current);
  const next=state.players[(idx+1)%state.players.length];
  return {...state,current:next,die:null,sixes:0,phase:'roll',message:'Vez do próximo jogador.'};
}
export function ludoRoll(state:LudoState,die:number):LudoState {
  if(state.phase!=='roll' || !Number.isInteger(die) || die<1 || die>6) return state;
  if(die===6 && state.sixes===2) return {...nextLudo(state),message:'Três seis seguidos: perdeu a vez!'};
  const rolled={...state,die,sixes:die===6 ? state.sixes+1 : 0,phase:'move' as const,message:`Saiu ${die}. Escolha uma peça.`};
  if(ludoOptions(rolled).length) return rolled;
  if(die===6) return {...rolled,die:null,phase:'roll',message:'Saiu 6: jogue de novo.'};
  return {...nextLudo(rolled),message:`Saiu ${die}; sem jogadas possíveis. Próxima vez.`};
}
export function ludoMove(state:LudoState,token:number):LudoState {
  if(!ludoOptions(state).includes(token) || state.die===null) return state;
  const die=state.die;
  const tokens=state.tokens.map(row=>[...row]);
  const previous=tokens[state.current][token];
  const progress=previous===-1 ? 0 : previous+die;
  tokens[state.current][token]=progress;
  let captured=false;
  if(progress<=50) {
    const landing=(STARTS[state.current]+progress)%52;
    if(!SAFE_TILES.has(landing)) for(const enemy of state.players) if(enemy!==state.current)
      for(let i=0;i<4;i++) if(tokens[enemy][i]>=0 && tokens[enemy][i]<=50 && (STARTS[enemy]+tokens[enemy][i])%52===landing) {
        tokens[enemy][i]=-1; captured=true;
      }
  }
  if(tokens[state.current].every(p=>p===56)) return {...state,tokens,die:null,phase:'done',winner:state.current,message:'Partida encerrada!'};
  if(die===6 || captured) return {...state,tokens,die:null,phase:'roll',message:captured?'Capturou! Jogue novamente.':'Seis! Jogue novamente.'};
  return {...nextLudo({...state,tokens}),message:progress===56?'Peça chegou ao centro!':'Peça movida. Próximo jogador.'};
}
export function ludoPosition(player:number,progress:number,token:number):[number,number] {
  if(progress===-1) return [...YARDS[player][token]] as [number,number];
  if(progress===56) return [7,7];
  if(progress>=51) return [...LANES[player][progress-51]] as [number,number];
  return [...TRACK[(STARTS[player]+progress)%52]] as [number,number];
}

// A canonical, uniquely solvable puzzle; transformations preserve its unique solution.
const SEED = ['530070000','600195000','098000060','800060003','400803001','700020006','060000280','000419005','000080079'].join('');
const ANSWER = ['534678912','672195348','198342567','859761423','426853791','713924856','961537284','287419635','345286179'].join('');
function shuffle<T>(items:T[],rng:()=>number):T[]{
  for(let i=items.length-1;i>0;i--){const j=Math.floor(rng()*(i+1));[items[i],items[j]]=[items[j],items[i]];} return items;
}
export interface SudokuPuzzle { puzzle:number[]; solution:number[]; }
export function makeSudoku(rng:()=>number=Math.random):SudokuPuzzle {
  const bands=shuffle([0,1,2],rng), stacks=shuffle([0,1,2],rng);
  const rows=bands.flatMap(b=>shuffle([0,1,2],rng).map(r=>b*3+r));
  const cols=stacks.flatMap(s=>shuffle([0,1,2],rng).map(c=>s*3+c));
  const digits=shuffle([1,2,3,4,5,6,7,8,9],rng);
  const transpose=rng()<0.5;
  const convert=(seed:string)=>Array.from({length:81},(_,i)=>{
    const row=Math.floor(i/9),col=i%9;
    const n=Number(seed[(transpose?cols[col]:rows[row])*9+(transpose?rows[row]:cols[col])]);
    return n ? digits[n-1]:0;
  });
  return {puzzle:convert(SEED),solution:convert(ANSWER)};
}
export function sudokuConflicts(board:readonly number[], index:number):number[] {
  if(index<0 || index>80 || !board[index]) return [];
  const row=Math.floor(index/9),col=index%9,v=board[index];
  return board.flatMap((n,i)=>i!==index && n===v && (Math.floor(i/9)===row || i%9===col || Math.floor(i/27)===Math.floor(index/27) && Math.floor(i%9/3)===Math.floor(col/3))?[i]:[]);
}
export function sudokuSolved(board:readonly number[],solution:readonly number[]):boolean {
  return board.length===81 && board.every((n,i)=>n!==0 && n===solution[i]);
}
