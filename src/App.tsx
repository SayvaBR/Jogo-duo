import { useEffect, useRef, useState } from 'react';
import { App as NativeApp } from '@capacitor/app';
import { Capacitor } from '@capacitor/core';
import { ArrowLeft, ArrowRight, Brain, Check, CircleDot, Dice5, Gamepad2, Grid3X3, Hand, Heart, LayoutGrid, ShieldCheck, Sparkles, Trophy, Users, Zap } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import AirHockey from './AirHockey';
import { TicTacToe, ConnectFour } from './BoardGames';
import { MemoryGame, DotsGame, RpsGame } from './PartyGames';
import { LudoGame } from './Ludo';
import { SudokuGame } from './Sudoku';

export type GameId = 'air'|'ludo'|'tic'|'four'|'dots'|'memory'|'rps'|'sudoku';
interface GameInfo { id:GameId; title:string; sub:string; players:string; category:'duo'|'group'|'solo'; icon:LucideIcon; color:string; tag:string; }
const games:GameInfo[]=[
  {id:'air',title:'Air Rocket',sub:'Disco, reflexos e gols',players:'2 jogadores',category:'duo',icon:Zap,color:'pink',tag:'TEMPO REAL'},
  {id:'ludo',title:'Ludo',sub:'Corra até o centro',players:'2 a 4 jogadores',category:'group',icon:Dice5,color:'purple',tag:'TABULEIRO'},
  {id:'tic',title:'Jogo da velha',sub:'Três em linha vencem',players:'2 jogadores',category:'duo',icon:Grid3X3,color:'cyan',tag:'CLÁSSICO'},
  {id:'four',title:'Ligue 4',sub:'Quatro peças na sequência',players:'2 jogadores',category:'duo',icon:CircleDot,color:'yellow',tag:'ESTRATÉGIA'},
  {id:'dots',title:'Pontos e caixas',sub:'Feche mais quadrados',players:'2 jogadores',category:'duo',icon:LayoutGrid,color:'mint',tag:'TABULEIRO'},
  {id:'memory',title:'Memória dupla',sub:'Encontre pares e pontue',players:'2 jogadores',category:'duo',icon:Brain,color:'purple',tag:'MEMÓRIA'},
  {id:'rps',title:'Pedra, papel, tesoura',sub:'Escolhas secretas',players:'2 jogadores',category:'duo',icon:Hand,color:'pink',tag:'RÁPIDO'},
  {id:'sudoku',title:'Sudoku',sub:'O desafio dos números',players:'1 jogador',category:'solo',icon:Grid3X3,color:'cyan',tag:'SOLO'}
];
export function GameShell({title,eyebrow,onBack,children}:{title:string;eyebrow:string;onBack:()=>void;children:React.ReactNode}){
  return <section className="game-view"><header className="game-header"><button className="icon-button" onClick={onBack} aria-label="Voltar para jogos"><ArrowLeft/></button><div><span className="eyebrow">{eyebrow}</span><h1>{title}</h1></div><div className="header-spacer"/></header>{children}</section>;
}
function readStats():Record<string,number>{try{return JSON.parse(localStorage.getItem('jogoduo-finished-v1')||'{}') as Record<string,number>;}catch{return {};}}
export default function App(){
  const [game,setGame]=useState<GameId|null>(null);
  const gameRef=useRef<GameId|null>(game);
  gameRef.current=game;
  const [filter,setFilter]=useState<'all'|'duo'|'group'|'solo'>('all');
  const [stats,setStats]=useState<Record<string,number>>(readStats);
  const complete=(id:GameId)=>setStats(prev=>{const next={...prev,[id]:(prev[id]||0)+1};try{localStorage.setItem('jogoduo-finished-v1',JSON.stringify(next));}catch{/* Storage optional. */}return next;});
  const back=()=>{gameRef.current=null;setGame(null);};
  useEffect(()=>{
    // The Android system gesture/button must navigate within the game instead of closing it.
    // Keep a single native subscription for the lifetime of the React root.
    if(!Capacitor.isNativePlatform())return;
    let disposed=false;
    let remove:(()=>Promise<void>)|null=null;
    void NativeApp.addListener('backButton',()=>{
      if(gameRef.current!==null){gameRef.current=null;setGame(null);}
      else void NativeApp.minimizeApp();
    }).then(handle=>{if(disposed)void handle.remove();else remove=()=>handle.remove();});
    return()=>{disposed=true;if(remove)void remove();};
  },[]);
  useEffect(()=>{
    const keyboardBack=(event:KeyboardEvent)=>{if(event.key==='Escape'&&gameRef.current!==null){event.preventDefault();gameRef.current=null;setGame(null);}};
    window.addEventListener('keydown',keyboardBack);
    return()=>window.removeEventListener('keydown',keyboardBack);
  },[]);
  if(game) return <main className="app playing">
    {game==='air'&&<AirHockey onBack={back} onFinish={()=>complete('air')}/>}
    {game==='ludo'&&<LudoGame onBack={back} onFinish={()=>complete('ludo')}/>}
    {game==='tic'&&<TicTacToe onBack={back} onFinish={()=>complete('tic')}/>}
    {game==='four'&&<ConnectFour onBack={back} onFinish={()=>complete('four')}/>}
    {game==='dots'&&<DotsGame onBack={back} onFinish={()=>complete('dots')}/>}
    {game==='memory'&&<MemoryGame onBack={back} onFinish={()=>complete('memory')}/>}
    {game==='rps'&&<RpsGame onBack={back} onFinish={()=>complete('rps')}/>}
    {game==='sudoku'&&<SudokuGame onBack={back} onFinish={()=>complete('sudoku')}/>}
  </main>;
  const shown=games.filter(g=>filter==='all'||g.category===filter);
  const total=Object.values(stats).reduce((a,b)=>a+b,0);
  return <main className="app"><div className="ambient ambient-a"/><div className="ambient ambient-b"/>
    <header className="home-header"><div className="brand-mark"><Gamepad2 size={28} strokeWidth={2.8}/></div><div className="brand-wordmark">JOGO <b>DUO</b><small>SEU FLIPERAMA DE BOLSO</small></div><div className="online-pill"><span className="live-dot"/> OFFLINE</div></header>
    <section className="hero"><div className="hero-eyebrow"><Sparkles size={15}/> A DIVERSÃO COMEÇA AQUI</div><h1>Juntos, a partida fica <em>melhor.</em></h1><p>Um celular. Seus amigos. Um monte de desafios para disputar lado a lado.</p><button className="hero-button" onClick={()=>setGame('air')}><Zap size={20} fill="currentColor"/> Jogar agora <ArrowRight size={19}/></button><div className="hero-sparks" aria-hidden="true">✦<span>✳</span>✦</div></section>
    <div className="stats-row"><div><span className="stat-icon purple-text"><Gamepad2 size={19}/></span><strong>08</strong><small>MINIJOGOS</small></div><div><span className="stat-icon cyan-text"><Users size={19}/></span><strong>2–4</strong><small>AMIGOS</small></div><div><span className="stat-icon yellow-text"><Trophy size={19}/></span><strong>{total}</strong><small>CONCLUÍDOS</small></div></div>
    <section className="catalog"><div className="catalog-heading"><div><span className="eyebrow purple-text">ESCOLHA SEU DESAFIO</span><h2>Todos os jogos <span>✦</span></h2></div><span className="count-pill">{shown.length} JOGOS</span></div>
      <div className="filters" role="group" aria-label="Filtrar jogos">{([['all','Todos'],['duo','2 jogadores'],['group','Até 4'],['solo','Solo']] as const).map(([key,name])=><button className={filter===key?'filter active':'filter'} aria-pressed={filter===key} key={key} onClick={()=>setFilter(key)}>{name}</button>)}</div>
      <div className="games-grid">{shown.map(item=><button key={item.id} className={'game-card '+item.color} onClick={()=>setGame(item.id)}><div className="game-card-top"><span className="game-icon"><item.icon size={31} strokeWidth={2.35}/></span><span className="game-arrow"><ArrowRight size={18}/></span></div><span className="game-tag">{item.tag}</span><h3>{item.title}</h3><p>{item.sub}</p><div className="game-card-footer"><Users size={14}/>{item.players}</div></button>)}</div>
    </section>
    <section className="offline-banner"><div className="shield"><ShieldCheck size={24}/></div><div><strong>Diversão sem complicação</strong><p>Sem internet, sem cadastro, sem conectar aparelhos. Só abrir e jogar!</p></div><Check className="mint-text" size={20}/></section>
    <footer className="footer"><Heart size={14} fill="currentColor"/> Feito para jogar pertinho · Jogo Duo</footer>
  </main>;
}
