import { useEffect, useRef, useState } from 'react';
import type { PointerEvent } from 'react';
import { ArrowLeft, Pause, Play, RotateCcw } from 'lucide-react';

const W=360,H=600,R=11,P=25,GOAL_L=115,GOAL_R=245;
type Point={x:number;y:number};
type Puck=Point & {vx:number;vy:number};
type Match={puck:Puck;paddles:[Point,Point];scores:[number,number];playing:boolean;winner:number|null;pointers:Map<number,number>};
function initial():Match{return {puck:{x:180,y:300,vx:120*(Math.random()<.5?-1:1),vy:310*(Math.random()<.5?-1:1)},paddles:[{x:180,y:520},{x:180,y:80}],scores:[0,0],playing:true,winner:null,pointers:new Map()};}
function serve(m:Match,point:number){m.puck={x:180,y:300,vx:(Math.random()-.5)*240,vy:point===0?300:-300};m.paddles=[{x:180,y:520},{x:180,y:80}];}
function step(m:Match,dt:number,scored:(scores:[number,number],winner:number|null)=>void){
  if(!m.playing)return;
  const puck=m.puck;puck.x+=puck.vx*dt;puck.y+=puck.vy*dt;
  if(puck.x<R){puck.x=R;puck.vx=Math.abs(puck.vx);}if(puck.x>W-R){puck.x=W-R;puck.vx=-Math.abs(puck.vx);}
  for(let player=0;player<2;player++){
    const pad=m.paddles[player],dx=puck.x-pad.x,dy=puck.y-pad.y,dist=Math.hypot(dx,dy);
    if(dist<R+P&&dist>0){const nx=dx/dist,ny=dy/dist,approaching=puck.vx*nx+puck.vy*ny;
      puck.x=pad.x+nx*(R+P+.7);puck.y=pad.y+ny*(R+P+.7);
      if(approaching<0){puck.vx-=2*approaching*nx;puck.vy-=2*approaching*ny;}
      puck.vx+=nx*155;puck.vy+=ny*155;
      const speed=Math.hypot(puck.vx,puck.vy),target=Math.min(900,Math.max(350,speed));puck.vx=puck.vx/speed*target;puck.vy=puck.vy/speed*target;
    }
  }
  if(puck.y<-R||puck.y>H+R){if(puck.x>GOAL_L&&puck.x<GOAL_R){
    const point=puck.y<0?0:1;m.scores[point]++;m.winner=m.scores[point]>=7?point:null;m.playing=m.winner===null;
    scored([...m.scores] as [number,number],m.winner);if(m.winner===null)serve(m,point);
  }else{puck.y=puck.y<0?R:H-R;puck.vy*=-1;}}
  else if(puck.y<R&&(puck.x<=GOAL_L||puck.x>=GOAL_R)){puck.y=R;puck.vy=Math.abs(puck.vy);}
  else if(puck.y>H-R&&(puck.x<=GOAL_L||puck.x>=GOAL_R)){puck.y=H-R;puck.vy=-Math.abs(puck.vy);}
}
function draw(ctx:CanvasRenderingContext2D,m:Match){
  ctx.clearRect(0,0,W,H);ctx.fillStyle='#111b34';ctx.fillRect(0,0,W,H);ctx.strokeStyle='rgba(199,219,255,.20)';ctx.lineWidth=2;
  for(let x=30;x<W;x+=30){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,H);ctx.stroke();}
  for(let y=30;y<H;y+=30){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(W,y);ctx.stroke();}
  ctx.strokeStyle='#7d93cf';ctx.lineWidth=3;ctx.strokeRect(3,3,W-6,H-6);ctx.beginPath();ctx.moveTo(0,300);ctx.lineTo(W,300);ctx.moveTo(180,270);ctx.arc(180,300,54,0,Math.PI*2);ctx.stroke();
  ctx.lineWidth=7;ctx.strokeStyle='#ff6b9d';ctx.beginPath();ctx.moveTo(GOAL_L,4);ctx.lineTo(GOAL_R,4);ctx.stroke();ctx.strokeStyle='#66e5fd';ctx.beginPath();ctx.moveTo(GOAL_L,H-4);ctx.lineTo(GOAL_R,H-4);ctx.stroke();
  ctx.fillStyle='rgba(255,107,157,.11)';ctx.fillRect(0,0,W,300);ctx.fillStyle='rgba(102,229,253,.07)';ctx.fillRect(0,300,W,300);
  ctx.textAlign='center';ctx.font='900 74px system-ui';ctx.fillStyle='rgba(255,255,255,.09)';ctx.fillText(String(m.scores[1]),180,213);ctx.fillText(String(m.scores[0]),180,442);
  m.paddles.forEach((pad,i)=>{ctx.beginPath();ctx.arc(pad.x,pad.y,P,0,Math.PI*2);ctx.fillStyle=i===0?'#66e5fd':'#ff6b9d';ctx.fill();ctx.lineWidth=5;ctx.strokeStyle=i===0?'#258eb7':'#a73570';ctx.stroke();ctx.beginPath();ctx.arc(pad.x,pad.y,9,0,Math.PI*2);ctx.fillStyle='#f6f8ff';ctx.fill();});
  ctx.beginPath();ctx.arc(m.puck.x,m.puck.y,R,0,Math.PI*2);ctx.fillStyle='#fff';ctx.fill();ctx.lineWidth=3;ctx.strokeStyle='#b4bce3';ctx.stroke();
  if(!m.playing){ctx.fillStyle='rgba(13,16,32,.72)';ctx.fillRect(0,0,W,H);ctx.textAlign='center';ctx.fillStyle='#fff';ctx.font='900 30px system-ui';ctx.fillText(m.winner===null?'PAUSADO':m.winner===0?'AZUL VENCEU!':'ROSA VENCEU!',W/2,H/2);}
}
export default function AirHockey({onBack,onFinish}:{onBack:()=>void;onFinish:()=>void}){
  const canvas=useRef<HTMLCanvasElement>(null),match=useRef<Match>(initial());
  const [scores,setScores]=useState<[number,number]>([0,0]),[paused,setPaused]=useState(false),[winner,setWinner]=useState<number|null>(null);
  useEffect(()=>{const element=canvas.current;if(!element)return;const dpr=Math.min(window.devicePixelRatio||1,2);element.width=W*dpr;element.height=H*dpr;
    const ctx=element.getContext('2d');if(!ctx)return;ctx.setTransform(dpr,0,0,dpr,0,0);
    let frame=0,previous=0;const loop=(time:number)=>{const dt=previous?Math.min((time-previous)/1000,.032):0;previous=time;
      step(match.current,dt,(score,win)=>{setScores(score);setWinner(win);if(win!==null){setPaused(true);onFinish();}});draw(ctx,match.current);frame=requestAnimationFrame(loop);};
    frame=requestAnimationFrame(loop);return()=>cancelAnimationFrame(frame);
  },[onFinish]);
  const point=(e:PointerEvent<HTMLCanvasElement>):Point=>{const rect=e.currentTarget.getBoundingClientRect();return{x:(e.clientX-rect.left)/rect.width*W,y:(e.clientY-rect.top)/rect.height*H};};
  const move=(e:PointerEvent<HTMLCanvasElement>)=>{const m=match.current,p=m.pointers.get(e.pointerId);if(p===undefined||!m.playing)return;const v=point(e);m.paddles[p]={x:Math.max(P,Math.min(W-P,v.x)),y:p===0?Math.max(326,Math.min(H-P,v.y)):Math.max(P,Math.min(274,v.y))};};
  const down=(e:PointerEvent<HTMLCanvasElement>)=>{if(!match.current.playing)return;const p=point(e).y<300?1:0;if([...match.current.pointers.values()].includes(p))return;e.currentTarget.setPointerCapture(e.pointerId);match.current.pointers.set(e.pointerId,p);move(e);};
  const release=(e:PointerEvent<HTMLCanvasElement>)=>{match.current.pointers.delete(e.pointerId);if(e.currentTarget.hasPointerCapture(e.pointerId))e.currentTarget.releasePointerCapture(e.pointerId);};
  const toggle=()=>{if(winner!==null)return;match.current.playing=!match.current.playing;setPaused(!match.current.playing);};
  const restart=()=>{match.current=initial();setScores([0,0]);setWinner(null);setPaused(false);};
  return <section className="game-view air-page"><header className="game-header"><button className="icon-button" aria-label="Voltar" onClick={onBack}><ArrowLeft/></button><div><span className="eyebrow">2 PESSOAS · TEMPO REAL</span><h1>Air Rocket</h1></div><button className="icon-button" aria-label="Reiniciar partida" onClick={restart}><RotateCcw/></button></header>
    <div className="air-score"><span className="pink">● ROSA {scores[1]}</span><span className="muted">PRIMEIRO A 7</span><span className="cyan">AZUL {scores[0]} ●</span></div>
    <div className="air-court"><canvas ref={canvas} aria-label="Mesa de Air Rocket. Jogador rosa controla a metade de cima e azul a metade de baixo." onPointerDown={down} onPointerMove={move} onPointerUp={release} onPointerCancel={release} onLostPointerCapture={release}/></div>
    <div className="air-actions"><button className="secondary-btn" onClick={restart}><RotateCcw size={17}/> Nova partida</button><button className="primary-btn" onClick={toggle} disabled={winner!==null}>{paused?<Play size={17}/>:<Pause size={17}/>} {paused?'Continuar':'Pausar'}</button></div>
    <p className="hint">Cada pessoa arrasta seu rebatedor na sua metade da tela. Vence quem fizer sete gols.</p>
  </section>;
}
