import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ui.dart';

const _colors=[pink,lilac,mint,gold];
const _names=['CORAL','ROXO','VERDE','AMARELO'];
const _track=<List<int>>[[6,13],[6,12],[6,11],[6,10],[6,9],[5,8],[4,8],[3,8],[2,8],[1,8],[0,8],[0,7],[0,6],[1,6],[2,6],[3,6],[4,6],[5,6],[6,5],[6,4],[6,3],[6,2],[6,1],[6,0],[7,0],[8,0],[8,1],[8,2],[8,3],[8,4],[8,5],[9,6],[10,6],[11,6],[12,6],[13,6],[14,6],[14,7],[14,8],[13,8],[12,8],[11,8],[10,8],[9,8],[8,9],[8,10],[8,11],[8,12],[8,13],[8,14],[7,14],[6,14]];
const _starts=[0,13,26,39];
const _lanes=<List<List<int>>>[[[7,13],[7,12],[7,11],[7,10],[7,9]],[[1,7],[2,7],[3,7],[4,7],[5,7]],[[7,1],[7,2],[7,3],[7,4],[7,5]],[[13,7],[12,7],[11,7],[10,7],[9,7]]];
const _yards=<List<List<int>>>[[[1,10],[4,10],[1,13],[4,13]],[[1,1],[4,1],[1,4],[4,4]],[[10,1],[13,1],[10,4],[13,4]],[[10,10],[13,10],[10,13],[13,13]]];
const _safe={0,8,13,21,26,34,39,47};
List<int> ludoPosition(int player,int progress,int piece){if(progress<0)return _yards[player][piece];if(progress==56)return [7,7];if(progress>=51)return _lanes[player][progress-51];return _track[(_starts[player]+progress)%52];}
class LudoPage extends StatefulWidget{const LudoPage({super.key});@override State<LudoPage> createState()=>_LudoPageState();}
class _LudoPageState extends State<LudoPage>{
 final rng=math.Random();int count=2,current=0,die=0,sixes=0;String phase='roll',message='Toque em lançar dado para começar.';int? winner,banked;bool comboOn=true,combined=false,extraCombo=false,captureCombo=false;late List<List<int>> tokens;late List<int> players;
 @override void initState(){super.initState();reset();}
 void reset(){players=count==2?[0,2]:count==3?[0,1,2]:[0,1,2,3];tokens=List.generate(4,(_)=>List.filled(4,-1));current=players.first;die=0;sixes=0;phase='roll';message='Toque em lançar dado para começar.';winner=null;banked=null;combined=false;extraCombo=false;captureCombo=false;}
 List<int> get choices{if(phase!='move'||die==0)return [];return List.generate(4,(i)=>i).where((i){final p=tokens[current][i];return p<56&&(p!=-1||die==6)&& (p<0||p+die<=56);}).toList();}
 void next({String? note}){final i=players.indexOf(current);current=players[(i+1)%players.length];die=0;sixes=0;phase='roll';banked=null;combined=false;extraCombo=false;captureCombo=false;message=note??'Vez do próximo jogador.';}
 void bonusOrNext(String note){final bonus=extraCombo||captureCombo;if(bonus){die=0;phase='roll';message='$note Jogue novamente!';banked=null;combined=false;extraCombo=false;captureCombo=false;}else{next(note:'$note Próximo jogador.');}}
 void roll(){if(phase!='roll')return;setState((){final result=rng.nextInt(6)+1;if(result==6&&sixes==2){next(note:'Três seis seguidos: perdeu a vez!');return;}
   sixes=result==6?sixes+1:0;
   if(banked!=null&&combined){die=banked!;banked=result;extraCombo=result==6;phase='move';message='Dados 6 e $result. Escolha um dado e uma peça.';if(choices.isEmpty){final nextDie=banked!;die=nextDie;banked=null;if(choices.isEmpty)bonusOrNext('Não há movimentos possíveis.');}return;}
   die=result;phase='move';message='Saiu $die. Escolha uma peça.';
   if(choices.isEmpty){if(result==6){die=0;phase='roll';message='Seis! Jogue novamente.';}else next(note:'Saiu $result, sem jogadas. Próximo jogador.');}
 });}
 bool get canBank=>comboOn&&!combined&&phase=='move'&&die==6&&tokens[current].where((p)=>p>=0&&p<56).length>=2;
 void bank(){if(!canBank)return;setState((){banked=6;combined=true;die=0;phase='roll';message='Seis guardado. Lance de novo para combinar os dados.';});}
 void swap(){if(!combined||banked==null||phase!='move')return;setState((){final other=banked!;banked=die;die=other;message='Dado $die selecionado. Escolha uma peça.';});}
 void move(int piece){if(!choices.contains(piece))return;setState((){final old=tokens[current][piece];final progress=old<0?0:old+die;tokens[current][piece]=progress;var captured=false;
   if(progress<=50){final landing=(_starts[current]+progress)%52;if(!_safe.contains(landing))for(final enemy in players){if(enemy==current)continue;for(var i=0;i<4;i++){final p=tokens[enemy][i];if(p>=0&&p<=50&&(_starts[enemy]+p)%52==landing){tokens[enemy][i]=-1;captured=true;}}}}
   if(tokens[current].every((p)=>p==56)){winner=current;phase='done';die=0;message='Jogador ${players.indexOf(current)+1} venceu!';return;}
   if(combined){captureCombo=captureCombo||captured;if(banked!=null){die=banked!;banked=null;phase='move';message='Primeiro movimento concluído. Agora use o dado $die.';if(choices.isEmpty)bonusOrNext('Segundo dado sem movimento possível.');return;}
     bonusOrNext('Os dois dados foram usados.');return;
   }
   if(die==6||captured){die=0;phase='roll';message=captured?'Capturou! Jogue novamente.':'Seis! Jogue novamente.';}else next(note:progress==56?'Peça chegou ao centro. Próxima vez.':'Peça movida. Próxima vez.');
 });}
 void tap(Offset p,double width){if(phase!='move')return;final unit=width/15;int? nearest;var best=unit*.64;for(final i in choices){final pos=ludoPosition(current,tokens[current][i],i);final at=Offset((pos[0]+.5)*unit,(pos[1]+.5)*unit);final distance=(at-p).distance;if(distance<best){best=distance;nearest=i;}}if(nearest!=null)move(nearest);}
 @override Widget build(BuildContext context){final playerIndex=players.indexOf(current)+1;return GameFrame(title:'Ludo',subtitle:'TABULEIRO · 2 A 4 PESSOAS',child:LayoutBuilder(builder:(context,bounds)=>SingleChildScrollView(padding:const EdgeInsets.fromLTRB(10,0,10,20),child:Column(children:[
   Row(mainAxisAlignment:MainAxisAlignment.center,children:[const Text('JOGADORES',style:TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w900)),const SizedBox(width:10),...([2,3,4].map((n)=>Padding(padding:const EdgeInsets.only(right:5),child:ChoiceChip(label:Text('$n'),selected:count==n,onSelected:(_)=>setState((){count=n;reset();}),showCheckmark:false,selectedColor:lilac,labelStyle:TextStyle(color:count==n?ink:Colors.white))))]),
   Wrap(spacing:6,runSpacing:5,alignment:WrapAlignment.center,children:players.map((id)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:8),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(11),border:Border.all(color:current==id?_colors[id]:Colors.white12,width:current==id?2:1)),child:Text('${_names[id]} ${tokens[id].where((p)=>p==56).length}/4',style:TextStyle(color:_colors[id],fontSize:10,fontWeight:FontWeight.w900)))).toList()),
   TurnBanner(winner!=null?'${_names[winner!]} VENCEU!':'VEZ DO JOGADOR $playerIndex · ${_names[current]}',color:winner!=null?gold:_colors[current]),
   Center(child:SizedBox(width:math.min(bounds.maxWidth-2,560.0),height:math.min(bounds.maxWidth-2,560.0),child:GestureDetector(onTapDown:(d)=>tap(d.localPosition,math.min(bounds.maxWidth-2,560.0)),child:CustomPaint(painter:_LudoPainter(tokens,players,current,choices),size:Size.square(math.min(bounds.maxWidth-2,560.0)))))),
   const SizedBox(height:10),Text(message,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:12)),const SizedBox(height:12),
   if(phase=='roll')ActionButton('LANÇAR DADO',icon:Icons.casino,onPressed:roll),
   if(phase=='move')Row(children:[Expanded(child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(13)),child:Text('🎲  $die',textAlign:TextAlign.center,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)))),if(combined&&banked!=null)...[const SizedBox(width:10),Expanded(child:OutlinedButton(onPressed:swap,child:Text('Trocar por 🎲 $banked')))] ]),
   if(canBank)...[const SizedBox(height:10),ActionButton('Guardar 6 e combinar dados',icon:Icons.add_circle_outline,onPressed:bank)],
   if(phase=='move')const Padding(padding:EdgeInsets.all(9),child:Text('TOQUE EM UMA DAS SUAS PEÇAS PARA MOVER',textAlign:TextAlign.center,style:TextStyle(color:gold,fontSize:10,fontWeight:FontWeight.w900))),
   if(phase=='done')ActionButton('Jogar novamente',onPressed:()=>setState(reset)),
   SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Dados combinados',style:TextStyle(fontSize:13,fontWeight:FontWeight.bold)),subtitle:const Text('Guarde um 6 com duas peças ativas e distribua dois dados.',style:TextStyle(fontSize:10,color:Colors.white54)),activeThumbColor:lilac,value:comboOn,onChanged:(v)=>setState(()=>comboOn=v)),
   const GameTip('Saia da base com 6, avance pela pista, capture adversários fora das casas seguras e chegue ao centro com valor exato.'),OutlinedButton.icon(onPressed:()=>setState(reset),icon:const Icon(Icons.refresh),label:const Text('Reiniciar partida')),
 ]))));}
}
class _LudoPainter extends CustomPainter{
 final List<List<int>> tokens;final List<int> players,choices;final int current;
 _LudoPainter(this.tokens,this.players,this.current,this.choices);
 @override void paint(Canvas canvas,Size size){final cell=size.width/15;final byPos=<_Position,int>{};for(var p=0;p<52;p++){final xy=_track[p];byPos[_Position(xy[0],xy[1])]=p;}
   for(var y=0;y<15;y++)for(var x=0;x<15;x++){
     var color=Colors.white;final key=_Position(x,y);final track=byPos[key];var lane=-1;for(var i=0;i<4;i++){if(_lanes[i].any((xy)=>xy[0]==x&&xy[1]==y))lane=i;}
     if(track!=null){color=_safe.contains(track)?const Color(0xFFE1D6FF):const Color(0xFFF5F4FF);final start=_starts.indexOf(track);if(start>=0)color=_colors[start];}
     else if(lane>=0)color=_colors[lane];
     else if(x>=6&&x<=8&&y>=6&&y<=8)color=const Color(0xFF2B2544);
     else if(x<6&&y>8)color=const Color(0xFFFFDFE9);else if(x<6&&y<6)color=const Color(0xFFEAE0FF);else if(x>8&&y<6)color=const Color(0xFFD3F7E5);else if(x>8&&y>8)color=const Color(0xFFFFEAC2);
     canvas.drawRect(Rect.fromLTWH(x*cell,y*cell,cell,cell),Paint()..color=color);
     canvas.drawRect(Rect.fromLTWH(x*cell,y*cell,cell,cell),Paint()..color=const Color(0xFF302746)..style=PaintingStyle.stroke..strokeWidth=.45);
     if(track!=null&&_safe.contains(track)){final center=Offset((x+.5)*cell,(y+.5)*cell);canvas.drawCircle(center,cell*.13,Paint()..color=const Color(0xFF7B69B7));}
   }
   final center=TextPainter(text:TextSpan(text:'✦',style:TextStyle(color:gold,fontWeight:FontWeight.w900,fontSize:cell*1.4)),textDirection:TextDirection.ltr)..layout();center.paint(canvas,Offset(7.5*cell-center.width/2,7.5*cell-center.height/2));
   for(final p in players)for(var i=0;i<4;i++){final xy=ludoPosition(p,tokens[p][i],i);final pad=<Offset>[const Offset(-.15,-.15),const Offset(.15,-.15),const Offset(-.15,.15),const Offset(.15,.15)][i];final center=Offset((xy[0]+.5+pad.dx)*cell,(xy[1]+.5+pad.dy)*cell);
     if(p==current&&choices.contains(i))canvas.drawCircle(center,cell*.49,Paint()..color=gold.withValues(alpha:.95));
     canvas.drawCircle(center,cell*.32,Paint()..color=Colors.white);canvas.drawCircle(center,cell*.27,Paint()..color=_colors[p]);
     final label=TextPainter(text:TextSpan(text:'${i+1}',style:TextStyle(color:ink,fontSize:cell*.25,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout();label.paint(canvas,Offset(center.dx-label.width/2,center.dy-label.height/2));
   }
 }
 @override bool shouldRepaint(covariant _LudoPainter old)=>true;
}
class _Position{final int x,y;const _Position(this.x,this.y);@override bool operator ==(Object other)=>other is _Position&&x==other.x&&y==other.y;@override int get hashCode=>Object.hash(x,y);}
