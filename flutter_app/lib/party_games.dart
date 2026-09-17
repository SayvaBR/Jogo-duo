import 'dart:async';
import 'package:flutter/material.dart';
import 'ui.dart';

const _symbols=['🍉','🚀','👾','🎲','⭐','🐸','⚡','🎧'];
class MemoryPage extends StatefulWidget{const MemoryPage({super.key});@override State<MemoryPage> createState()=>_MemoryPageState();}
class _MemoryPageState extends State<MemoryPage>{
 late List<int> deck;final Set<int> matched={};final List<int> shown=[];int turn=1,one=0,two=0;bool locked=false,done=false;Timer? pending;
 @override void initState(){super.initState();deck=List.generate(16,(i)=>i%8)..shuffle();}
 @override void dispose(){pending?.cancel();super.dispose();}
 void pick(int index){if(locked||done||shown.contains(index)||matched.contains(index))return;
   setState((){shown.add(index);if(shown.length==2){final a=shown.first,b=shown.last;if(deck[a]==deck[b]){matched.addAll([a,b]);if(turn==1)one++;else two++;shown.clear();done=matched.length==16;}
     else{locked=true;pending=Timer(const Duration(milliseconds:850),(){if(!mounted)return;setState((){shown.clear();locked=false;turn=3-turn;});});}}});
 }
 void reset(){pending?.cancel();setState((){deck=List.generate(16,(i)=>i%8)..shuffle();matched.clear();shown.clear();turn=1;one=0;two=0;locked=false;done=false;});}
 @override Widget build(BuildContext context)=>GameFrame(title:'Memória dupla',subtitle:'MEMÓRIA · 2 PESSOAS',child:SingleChildScrollView(padding:const EdgeInsets.all(16),child:Column(children:[
   DuoScore(first:one,second:two,turn:done?0:turn,middle:'PARES'),TurnBanner(done?(one==two?'EMPATE!':'JOGADOR ${one>two?1:2} VENCEU!'):'VEZ DO JOGADOR $turn',color:done?gold:turn==1?blue:pink),
   ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:AspectRatio(aspectRatio:1,child:GridView.builder(physics:const NeverScrollableScrollPhysics(),itemCount:16,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,mainAxisSpacing:8,crossAxisSpacing:8),itemBuilder:(context,i){final visible=matched.contains(i)||shown.contains(i);return Material(color:matched.contains(i)?const Color(0xFF295249):visible?const Color(0xFFEDE5FF):const Color(0xFF332950),borderRadius:BorderRadius.circular(15),child:InkWell(borderRadius:BorderRadius.circular(15),onTap:()=>pick(i),child:Center(child:Text(visible?_symbols[deck[i]]:'✦',style:TextStyle(color:visible?ink:lilac,fontSize:31,fontWeight:FontWeight.bold)))));}))),
   const GameTip('Encontre pares para marcar pontos e jogar novamente. Dois jogadores usam o mesmo celular.'),ActionButton('Nova partida',onPressed:reset),
 ])));
}
class RpsPage extends StatefulWidget{const RpsPage({super.key});@override State<RpsPage> createState()=>_RpsPageState();}
class _RpsPageState extends State<RpsPage>{
 int stage=0,first=-1,second=-1,one=0,two=0;
 static const names=['Pedra','Papel','Tesoura'];static const symbols=['✊','✋','✌️'];
 int get winner=>first==second?0:(first+1)%3==second?2:1;
 void choose(int move){if(stage==0){setState((){first=move;stage=1;});}else if(stage==2){setState((){second=move;stage=3;if(winner==1)one++;if(winner==2)two++;});}}
 void reset(){setState((){stage=0;first=-1;second=-1;});}
 @override Widget build(BuildContext context)=>GameFrame(title:'Pedra, papel, tesoura',subtitle:'ESCOLHAS SECRETAS · 2 PESSOAS',child:SingleChildScrollView(padding:const EdgeInsets.all(16),child:Column(children:[
   DuoScore(first:one,second:two,turn:stage==0?1:stage==2?2:0),const SizedBox(height:22),
   if(stage==1)Container(width:double.infinity,padding:const EdgeInsets.symmetric(vertical:42,horizontal:22),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(24)),child:Column(children:[const Icon(Icons.visibility_off,color:lilac,size:55),const SizedBox(height:22),const Text('Escolha guardada!',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:12),const Text('Passe o celular ao jogador 2. A escolha do primeiro jogador está escondida.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white70,height:1.6)),const SizedBox(height:24),ActionButton('Sou o jogador 2',icon:Icons.arrow_forward,onPressed:()=>setState(()=>stage=2))]))
   else if(stage==3)Container(width:double.infinity,padding:const EdgeInsets.symmetric(vertical:37,horizontal:20),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(24)),child:Column(children:[Text('${symbols[first]}  ×  ${symbols[second]}',style:const TextStyle(fontSize:48)),const SizedBox(height:20),Text(winner==0?'Empate!':'Jogador $winner venceu!',style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)),const SizedBox(height:10),Text('${names[first]} contra ${names[second]}',style:const TextStyle(color:Colors.white60)),const SizedBox(height:25),ActionButton('Próxima rodada',onPressed:reset)]))
   else ...[TurnBanner('JOGADOR ${stage==0?1:2}: ESCOLHA SUA JOGADA',color:stage==0?blue:pink),const SizedBox(height:13),Row(children:List.generate(3,(i)=>Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:Material(color:panel,borderRadius:BorderRadius.circular(17),child:InkWell(onTap:()=>choose(i),borderRadius:BorderRadius.circular(17),child:AspectRatio(aspectRatio:.79,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(symbols[i],style:const TextStyle(fontSize:39)),const SizedBox(height:12),Text(names[i],style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900))]))))))))],
   const GameTip('Pedra vence tesoura, tesoura vence papel, papel vence pedra. Cada escolha permanece secreta até ambos jogarem.'),
 ])));
}
