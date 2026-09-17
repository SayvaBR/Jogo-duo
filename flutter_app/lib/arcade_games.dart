import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'ui.dart';

void _circle(Canvas canvas,double x,double y,double r,Color color){canvas.drawCircle(Offset(x,y),r,Paint()..color=color);}
void _line(Canvas canvas,Offset a,Offset b,Color color,double stroke){canvas.drawLine(a,b,Paint()..color=color..strokeWidth=stroke..strokeCap=StrokeCap.round);}

class AirHockeyPage extends StatefulWidget{const AirHockeyPage({super.key});@override State<AirHockeyPage> createState()=>_AirHockeyPageState();}
class _AirHockeyPageState extends State<AirHockeyPage>{
 late _Hockey engine;int top=0,bottom=0;bool paused=false;int? winner;
 @override void initState(){super.initState();engine=_Hockey(onScore:(){if(!mounted)return;WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)setState((){top=engine.scores[1];bottom=engine.scores[0];winner=engine.winner;paused=engine.paused;});});});}
 void restart(){setState((){engine.reset();top=0;bottom=0;paused=false;winner=null;});}
 @override Widget build(BuildContext context)=>GameFrame(title:'Air Rocket',subtitle:'TEMPO REAL · 2 PESSOAS',child:LayoutBuilder(builder:(context,bounds)=>SingleChildScrollView(padding:const EdgeInsets.fromLTRB(13,0,13,20),child:Column(children:[
   Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('ROSA $top',style:const TextStyle(color:pink,fontWeight:FontWeight.w900)),const Text('PRIMEIRO A 7',style:TextStyle(color:Colors.white54,fontSize:10)),Text('AZUL $bottom',style:const TextStyle(color:blue,fontWeight:FontWeight.w900))]),const SizedBox(height:9),
   Center(child:ConstrainedBox(constraints:BoxConstraints(maxWidth:math.min(bounds.maxWidth-5,385)),child:AspectRatio(aspectRatio:360/600,child:ClipRRect(borderRadius:BorderRadius.circular(20),child:Listener(
     onPointerDown:(e)=>engine.down(e.pointer,e.localPosition),onPointerMove:(e)=>engine.move(e.pointer,e.localPosition),onPointerUp:(e)=>engine.up(e.pointer),onPointerCancel:(e)=>engine.up(e.pointer),
     child:GameWidget(game:engine)))))) ,
   const SizedBox(height:14),TurnBanner(winner!=null?'${winner==0?'AZUL':'ROSA'} VENCEU!':paused?'PARTIDA PAUSADA':'ARRASTE SEU REBATEDOR NA SUA METADE',color:winner!=null?gold:lilac),
   Row(children:[Expanded(child:OutlinedButton.icon(onPressed:restart,icon:const Icon(Icons.refresh),label:const Text('Reiniciar'))),const SizedBox(width:10),Expanded(child:FilledButton.icon(onPressed:winner!=null?null:()=>setState((){engine.paused=!engine.paused;paused=engine.paused;}),icon:Icon(paused?Icons.play_arrow:Icons.pause),label:Text(paused?'Continuar':'Pausar')))]),
   const GameTip('Dois dedos podem jogar ao mesmo tempo. Rosa controla a parte superior, azul a inferior. Vence quem fizer 7 gols.'),
 ]))));}
}
class _Hockey extends FlameGame{
 final VoidCallback onScore;_Hockey({required this.onScore});
 final scores=<int>[0,0];final paddles=<Offset>[const Offset(180,520),const Offset(180,80)];final Map<int,int> fingers={};double x=180,y=300,vx=150,vy=320;bool paused=false;int? winner;
 void reset(){scores[0]=0;scores[1]=0;paddles[0]=const Offset(180,520);paddles[1]=const Offset(180,80);fingers.clear();x=180;y=300;vx=145;vy=330;paused=false;winner=null;}
 void down(int pointer,Offset p){if(paused||winner!=null)return;final player=p.dy/(canvasSize.y==0?1:canvasSize.y)<.5?1:0;if(fingers.containsValue(player))return;fingers[pointer]=player;move(pointer,p);}
 void move(int pointer,Offset p){final player=fingers[pointer];if(player==null||paused)return;final px=(p.dx/(canvasSize.x==0?1:canvasSize.x)*360).clamp(26.0,334.0);final py=(p.dy/(canvasSize.y==0?1:canvasSize.y)*600).clamp(player==0?326.0:26.0,player==0?574.0:274.0);paddles[player]=Offset(px,py);}
 void up(int pointer)=>fingers.remove(pointer);
 void serve(int scored){x=180;y=300;vx=(math.Random().nextDouble()-.5)*190;vy=scored==0?310:-310;paddles[0]=const Offset(180,520);paddles[1]=const Offset(180,80);}
 @override void update(double dt){super.update(dt);if(paused||winner!=null)return;final step=dt.clamp(0.0,.032);x+=vx*step;y+=vy*step;
   if(x<11){x=11;vx=vx.abs();}if(x>349){x=349;vx=-vx.abs();}
   for(final pad in paddles){final dx=x-pad.dx,dy=y-pad.dy,dist=math.sqrt(dx*dx+dy*dy);if(dist>0&&dist<37){final nx=dx/dist,ny=dy/dist;final approach=vx*nx+vy*ny;x=pad.dx+nx*37.1;y=pad.dy+ny*37.1;if(approach<0){vx-=2*approach*nx;vy-=2*approach*ny;}vx+=nx*140;vy+=ny*140;final speed=math.sqrt(vx*vx+vy*vy);if(speed>0){final target=speed.clamp(340.0,850.0);vx=vx/speed*target;vy=vy/speed*target;}}}
   if(y<-11||y>611){if(x>115&&x<245){final scored=y<0?0:1;scores[scored]++;if(scores[scored]>=7){winner=scored;paused=true;}else serve(scored);onScore();}else{y=y<0?11:589;vy=-vy;}}
   else if(y<11&&(x<=115||x>=245)){y=11;vy=vy.abs();}else if(y>589&&(x<=115||x>=245)){y=589;vy=-vy.abs();}
 }
 @override void render(Canvas canvas){super.render(canvas);canvas.save();canvas.scale(canvasSize.x/360,canvasSize.y/600);
   canvas.drawRect(const Rect.fromLTWH(0,0,360,600),Paint()..color=const Color(0xFF131D35));
   for(var i=30;i<360;i+=30)_line(canvas,Offset(i.toDouble(),0),Offset(i.toDouble(),600),Colors.white.withValues(alpha:.075),1);
   for(var i=30;i<600;i+=30)_line(canvas,Offset(0,i.toDouble()),Offset(360,i.toDouble()),Colors.white.withValues(alpha:.075),1);
   canvas.drawRect(const Rect.fromLTWH(5,5,350,590),Paint()..color=lilac..strokeWidth=3..style=PaintingStyle.stroke);
   _line(canvas,const Offset(5,300),const Offset(355,300),lilac.withValues(alpha:.6),2);
   canvas.drawCircle(const Offset(180,300),52,Paint()..color=lilac.withValues(alpha:.4)..strokeWidth=2..style=PaintingStyle.stroke);
   _line(canvas,const Offset(115,5),const Offset(245,5),pink,8);_line(canvas,const Offset(115,595),const Offset(245,595),blue,8);
   for(var i=0;i<2;i++){final p=paddles[i];_circle(canvas,p.dx,p.dy,26,i==0?blue:pink);_circle(canvas,p.dx,p.dy,10,Colors.white);}
   _circle(canvas,x,y,11,Colors.white);
   if(paused){canvas.drawRect(const Rect.fromLTWH(0,0,360,600),Paint()..color=ink.withValues(alpha:.64));}
   canvas.restore();
 }
}

class _Ball {final int id;double x,y,vx=0,vy=0;bool pocketed=false;_Ball(this.id,this.x,this.y);}
class _Pocket {final double x,y,r;const _Pocket(this.x,this.y,this.r);}
const _pockets=[_Pocket(38,40,22),_Pocket(382,40,22),_Pocket(38,360,20),_Pocket(382,360,20),_Pocket(38,680,22),_Pocket(382,680,22)];
String? _group(int id)=>id>=1&&id<=7?'lisas':id>=9&&id<=15?'listradas':null;
class PoolPage extends StatefulWidget{const PoolPage({super.key});@override State<PoolPage> createState()=>_PoolPageState();}
class _PoolPageState extends State<PoolPage>{
 late _Pool engine;double angle=-math.pi/2,power=56;bool placing=false;
 @override void initState(){super.initState();engine=_Pool(onChanged:(){WidgetsBinding.instance.addPostFrameCallback((_){if(mounted){setState((){placing=engine.ballInHand;});}});});}
 void reset(){setState((){engine.reset();angle=-math.pi/2;power=56;placing=false;});}
 void interact(Offset pos,Size size){if(engine.phase!='aim')return;final x=pos.dx/size.width*420,y=pos.dy/size.height*720;if(placing){if(engine.place(x,y))setState((){});return;}final cue=engine.balls.first;setState(()=>angle=math.atan2(y-cue.y,x-cue.x));}
 @override Widget build(BuildContext context)=>GameFrame(title:'Sinuca',subtitle:'BOLA 8 · 2 PESSOAS · OFFLINE',child:LayoutBuilder(builder:(context,bounds)=>SingleChildScrollView(padding:const EdgeInsets.fromLTRB(10,2,10,22),child:Column(children:[
   DuoScore(first:engine.remaining(0),second:engine.remaining(1),turn:engine.winner==null?engine.current+1:0,middle:'RESTAM'),
   TurnBanner(engine.winner!=null?'JOGADOR ${engine.winner!+1} VENCEU!':engine.phase=='moving'?'BOLAS EM MOVIMENTO':'VEZ DO JOGADOR ${engine.current+1}',color:engine.winner!=null?gold:engine.current==0?blue:pink),
   Text(engine.message,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:11,height:1.4)),const SizedBox(height:6),
   if(engine.ballInHand&&engine.phase=='aim')OutlinedButton.icon(onPressed:()=>setState(()=>placing=!placing),icon:const Icon(Icons.pan_tool_outlined),label:Text(placing?'Confirmar posição da branca':'Mover bola branca')),
   Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('FORÇA ${power.round()}%',style:const TextStyle(color:gold,fontSize:10,fontWeight:FontWeight.w900)),Slider(value:power,min:10,max:100,onChanged:engine.phase=='aim'&&!placing?(v)=>setState(()=>power=v):null)])),FilledButton.icon(onPressed:engine.phase=='aim'&&!placing?(){engine.shoot(angle,power);setState((){});}:null,icon:const Icon(Icons.bolt),label:const Text('TACADA'))]),
   Center(child:ConstrainedBox(constraints:BoxConstraints(maxWidth:math.min(bounds.maxWidth-1,420)),child:AspectRatio(aspectRatio:420/720,child:ClipRRect(borderRadius:BorderRadius.circular(22),child:LayoutBuilder(builder:(context,table)=>GestureDetector(behavior:HitTestBehavior.opaque,
     onTapDown:(d)=>interact(d.localPosition,table.biggest),onPanStart:(d)=>interact(d.localPosition,table.biggest),onPanUpdate:(d)=>interact(d.localPosition,table.biggest),
     child:GameWidget(game:engine))))))),
   Row(mainAxisAlignment:MainAxisAlignment.center,children:[OutlinedButton(onPressed:engine.phase=='aim'&&!placing?()=>setState(()=>angle-=math.pi/36):null,child:const Text('− 5°')),Padding(padding:const EdgeInsets.symmetric(horizontal:19),child:Text('${(angle*180/math.pi+3600).round()%360}°',style:const TextStyle(fontWeight:FontWeight.w900))),OutlinedButton(onPressed:engine.phase=='aim'&&!placing?()=>setState(()=>angle+=math.pi/36):null,child:const Text('+ 5°'))]),
   Row(mainAxisAlignment:MainAxisAlignment.center,children:[Text('J1 ${engine.groups[0]??'mesa aberta'}',style:const TextStyle(color:blue,fontSize:11)),const SizedBox(width:15),Text('J2 ${engine.groups[1]??'mesa aberta'}',style:const TextStyle(color:pink,fontSize:11))]),
   const GameTip('Arraste na mesa para mirar, ajuste a força e dê a tacada. A primeira bola encaçapada define lisas e listradas. Encaçape seu grupo antes da bola 8; faltas dão bola branca livre ao adversário.'),ActionButton('Reiniciar partida',onPressed:reset),
 ]))));}
}
class _Pool extends FlameGame{
 final VoidCallback onChanged;_Pool({required this.onChanged}){reset();}
 final List<_Ball> balls=[];final groups=<String?>[null,null];int current=0,shots=0;String phase='aim',message='Mire, ajuste a força e faça a primeira tacada.';bool ballInHand=false;int? winner,firstHit;final potted=<int>[];bool scratch=false;int ownAtStart=-1;
 void reset(){balls.clear();balls.add(_Ball(0,210,548));const ids=[1,9,2,3,8,10,11,4,12,5,6,13,7,14,15];var k=0;for(var row=0;row<5;row++)for(var i=0;i<=row;i++){balls.add(_Ball(ids[k++],210+(i-row/2)*20.5,225+row*17.85));}groups[0]=null;groups[1]=null;current=0;shots=0;phase='aim';message='Mire, ajuste a força e faça a primeira tacada.';ballInHand=false;winner=null;firstHit=null;potted.clear();scratch=false;ownAtStart=-1;}
 int remaining(int player)=>balls.where((b)=>!b.pocketed&&_group(b.id)==groups[player]&&groups[player]!=null).length;
 bool free(double x,double y)=>x>=48&&x<=372&&y>=50&&y<=670&&!_pockets.any((p)=>math.sqrt(math.pow(x-p.x,2)+math.pow(y-p.y,2))<p.r+2)&&balls.every((b)=>b.id==0||b.pocketed||math.sqrt(math.pow(x-b.x,2)+math.pow(y-b.y,2))>=21);
 bool place(double x,double y){if(phase!='aim'||!ballInHand||!free(x,y))return false;final cue=balls.first;cue.x=x;cue.y=y;cue.vx=0;cue.vy=0;cue.pocketed=false;return true;}
 void respot(){final cue=balls.first;cue.pocketed=false;cue.vx=0;cue.vy=0;for(var y=548.0;y<650;y+=23){for(var x=210.0;x<365;x+=23){for(final xx in [x,420-x]){if(free(xx,y)){cue.x=xx;cue.y=y;return;}}}}cue.x=210;cue.y=548;}
 void shoot(double angle,double power){if(phase!='aim'||winner!=null)return;final cue=balls.first;cue.vx=math.cos(angle)*(210+power*6.5);cue.vy=math.sin(angle)*(210+power*6.5);phase='moving';ballInHand=false;firstHit=null;potted.clear();scratch=false;ownAtStart=groups[current]==null?-1:remaining(current);shots++;message='Bolas em movimento...';}
 void pocket(_Ball b){if(b.pocketed)return;b.pocketed=true;b.vx=0;b.vy=0;potted.add(b.id);if(b.id==0)scratch=true;}
 void step(double dt){for(final b in balls){if(b.pocketed)continue;b.x+=b.vx*dt;b.y+=b.vy*dt;final speed=math.sqrt(b.vx*b.vx+b.vy*b.vy);if(speed<6){b.vx=0;b.vy=0;}else{final next=math.max(0,speed-172*dt);b.vx=b.vx/speed*next;b.vy=b.vy/speed*next;}
   if(_pockets.any((p)=>math.sqrt(math.pow(b.x-p.x,2)+math.pow(b.y-p.y,2))<p.r)){pocket(b);continue;}
   if(b.x<48){b.x=48;b.vx=b.vx.abs()*.84;}if(b.x>372){b.x=372;b.vx=-b.vx.abs()*.84;}if(b.y<50){b.y=50;b.vy=b.vy.abs()*.84;}if(b.y>670){b.y=670;b.vy=-b.vy.abs()*.84;}
 }
 for(var i=0;i<balls.length;i++){final a=balls[i];if(a.pocketed)continue;for(var j=i+1;j<balls.length;j++){final b=balls[j];if(b.pocketed)continue;var dx=b.x-a.x,dy=b.y-a.y,d=math.sqrt(dx*dx+dy*dy);if(d>=20)continue;if(d<.0001){dx=20;dy=0;d=20;}final nx=dx/d,ny=dy/d,overlap=20-d;a.x-=nx*overlap*.5;a.y-=ny*overlap*.5;b.x+=nx*overlap*.5;b.y+=ny*overlap*.5;final approach=(b.vx-a.vx)*nx+(b.vy-a.vy)*ny;if(approach<0){if(firstHit==null){if(a.id==0&&b.id!=0)firstHit=b.id;else if(b.id==0&&a.id!=0)firstHit=a.id;}final impulse=-(1+.96)*approach/2;a.vx-=impulse*nx;a.vy-=impulse*ny;b.vx+=impulse*nx;b.vy+=impulse*ny;}}}
 }
 void finish(){for(final b in balls){b.vx=0;b.vy=0;}final opponent=1-current;final group=groups[current];final valid=firstHit!=null&&(group==null?firstHit!=8:ownAtStart==0?firstHit==8:_group(firstHit!)==group);final foul=scratch||!valid;final black=potted.contains(8);
   if(black){final legal=group!=null&&ownAtStart==0&&firstHit==8&&!foul;winner=legal?current:opponent;phase='done';message=legal?'Jogador ${current+1} encaçapou a 8 e venceu!':'Bola 8 fora de hora: jogador ${opponent+1} venceu!';onChanged();return;}
   if(!foul&&group==null){for(final id in potted){final chosen=_group(id);if(chosen!=null){groups[current]=chosen;groups[opponent]=chosen=='lisas'?'listradas':'lisas';break;}}}
   final keep=!foul&&potted.any((id)=>groups[current]!=null&&_group(id)==groups[current]);if(foul){current=opponent;ballInHand=true;respot();message=scratch?'Branca na caçapa! Jogador ${current+1} reposiciona.':'Falta: primeira bola incorreta ou nenhuma atingida. Jogador ${current+1} reposiciona.';}else if(keep){message='Boa tacada! Jogador ${current+1} continua.';}else{current=opponent;message='Vez do jogador ${current+1}.';}phase='aim';onChanged();
 }
 @override void update(double dt){super.update(dt);if(phase!='moving')return;final elapsed=dt.clamp(0.0,.05),n=math.max(1,(elapsed*120).ceil());for(var i=0;i<n;i++)step(elapsed/n);if(balls.every((b)=>b.pocketed||math.sqrt(b.vx*b.vx+b.vy*b.vy)<6))finish();}
 static const colors=<int,Color>{1:gold,2:Color(0xFF397FE5),3:Color(0xFFEC5864),4:Color(0xFF995AC6),5:Color(0xFFE79A36),6:mint,7:Color(0xFF903B52),8:Color(0xFF1B2030),9:gold,10:Color(0xFF397FE5),11:Color(0xFFEC5864),12:Color(0xFF995AC6),13:Color(0xFFE79A36),14:mint,15:Color(0xFF903B52)};
 @override void render(Canvas canvas){super.render(canvas);canvas.save();canvas.scale(canvasSize.x/420,canvasSize.y/720);
   canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2,2,416,716),const Radius.circular(26)),Paint()..color=const Color(0xFF704731));
   canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16,16,388,688),const Radius.circular(20)),Paint()..color=const Color(0xFF251B24));
   canvas.drawRect(const Rect.fromLTWH(38,40,344,640),Paint()..color=const Color(0xFF116B52));
   _line(canvas,const Offset(40,360),const Offset(380,360),Colors.white.withValues(alpha:.13),1);
   for(final p in _pockets){_circle(canvas,p.x,p.y,p.r+3,const Color(0xFF633B2B));_circle(canvas,p.x,p.y,p.r,ink);}
   if(phase=='aim'&&!ballInHand){final cue=balls.first;_line(canvas,Offset(cue.x,cue.y),Offset(cue.x+math.cos(_aim)*370,cue.y+math.sin(_aim)*370),Colors.white.withValues(alpha:.65),1.5);_line(canvas,Offset(cue.x-math.cos(_aim)*26,cue.y-math.sin(_aim)*26),Offset(cue.x-math.cos(_aim)*160,cue.y-math.sin(_aim)*160),const Color(0xFFE5BB81),6);}
   for(final b in balls){if(b.pocketed)continue;_circle(canvas,b.x+1,b.y+2,10,ink.withValues(alpha:.6));_circle(canvas,b.x,b.y,10,b.id==0?Colors.white:colors[b.id]!);
     if(b.id>=9){canvas.save();canvas.clipPath(Path()..addOval(Rect.fromCircle(center:Offset(b.x,b.y),radius:10)));canvas.drawRect(Rect.fromLTWH(b.x-10,b.y-4.5,20,9),Paint()..color=Colors.white);canvas.restore();}
     if(b.id!=0){_circle(canvas,b.x,b.y,4.5,Colors.white);final text=TextPainter(text:TextSpan(text:'${b.id}',style:const TextStyle(color:ink,fontSize:6,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout();text.paint(canvas,Offset(b.x-text.width/2,b.y-text.height/2));}
   }
   if(ballInHand&&phase=='aim'){_circle(canvas,balls.first.x,balls.first.y,14,mint.withValues(alpha:.45));}
   if(phase=='done'){canvas.drawRect(const Rect.fromLTWH(38,310,344,95),Paint()..color=ink.withValues(alpha:.88));final text=TextPainter(text:TextSpan(text:'JOGADOR ${winner!+1} VENCEU!',style:const TextStyle(color:gold,fontSize:24,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout();text.paint(canvas,Offset(210-text.width/2,350-text.height/2));}
   canvas.restore();
 }
 double _aim=-math.pi/2;void setAim(double value){_aim=value;}
}
