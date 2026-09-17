import 'package:flutter/material.dart';
import 'ui.dart';
import 'board_games.dart';
import 'party_games.dart';
import 'ludo.dart';
import 'sudoku.dart';
import 'arcade_games.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const JogoDuo()); }
class JogoDuo extends StatelessWidget {
  const JogoDuo({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(title:'Jogo Duo',debugShowCheckedModeBanner:false,
    theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:ink,colorScheme:ColorScheme.fromSeed(seedColor:lilac,brightness:Brightness.dark),fontFamily:'Roboto'),
    home:const HomeScreen());
}
class _Item {
 final String title,detail,players,tag,group; final IconData icon; final Color color; final Widget Function() builder;
 const _Item(this.title,this.detail,this.players,this.tag,this.group,this.icon,this.color,this.builder);
}
final _items = <_Item>[
  _Item('Air Rocket','Reflexos e gols','2 jogadores','TEMPO REAL','Dupla',Icons.sports_hockey,pink,()=>const AirHockeyPage()),
  _Item('Sinuca','Mire, encaçape e vença','2 jogadores','BOLA 8','Dupla',Icons.sports_baseball,mint,()=>const PoolPage()),
  _Item('Ludo','Corra até o centro','2 a 4 jogadores','TABULEIRO','Grupo',Icons.casino,lilac,()=>const LudoPage()),
  _Item('Jogo da velha','Três em linha vencem','2 jogadores','CLÁSSICO','Dupla',Icons.grid_3x3,blue,()=>const TicPage()),
  _Item('Ligue 4','Quatro peças na sequência','2 jogadores','ESTRATÉGIA','Dupla',Icons.circle_outlined,gold,()=>const FourPage()),
  _Item('Pontos e caixas','Feche o maior número de caixas','2 jogadores','TABULEIRO','Dupla',Icons.crop_square,mint,()=>const DotsPage()),
  _Item('Memória dupla','Encontre os pares','2 jogadores','MEMÓRIA','Dupla',Icons.psychology,lilac,()=>const MemoryPage()),
  _Item('Pedra, papel, tesoura','Escolhas secretas','2 jogadores','RÁPIDO','Dupla',Icons.back_hand,pink,()=>const RpsPage()),
  _Item('Sudoku','O desafio dos números','1 jogador','SOLO','Solo',Icons.apps,blue,()=>const SudokuPage()),
];
class HomeScreen extends StatefulWidget {const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState();}
class _HomeScreenState extends State<HomeScreen> {
 String filter='Todos';
 @override Widget build(BuildContext context) {
 final visible=_items.where((g)=>filter=='Todos'||g.group==filter).toList();
 return Scaffold(backgroundColor:ink,body:SafeArea(child:CustomScrollView(slivers:[
  SliverPadding(padding:const EdgeInsets.fromLTRB(20,20,20,0),sliver:SliverToBoxAdapter(child:Row(children:[
    Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:lilac,borderRadius:BorderRadius.circular(17)),child:const Icon(Icons.sports_esports,color:ink,size:29)),
    const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('JOGO DUO',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900,letterSpacing:-.8)),Text('SEU FLIPERAMA DE BOLSO',style:TextStyle(color:Colors.white54,fontSize:9,letterSpacing:1.4,fontWeight:FontWeight.bold))])),
    Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:const Color(0xFF1A302A),borderRadius:BorderRadius.circular(30)),child:const Text('● OFFLINE',style:TextStyle(color:mint,fontWeight:FontWeight.w900,fontSize:10)))
  ]))),
  SliverPadding(padding:const EdgeInsets.all(20),sliver:SliverToBoxAdapter(child:Container(
    padding:const EdgeInsets.all(24),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF45337E),Color(0xFF211D3D)]),borderRadius:BorderRadius.circular(25),border:Border.all(color:const Color(0xFF65539F))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('✦ A DIVERSÃO COMEÇA AQUI',style:TextStyle(color:lilac,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1.3)),const SizedBox(height:14),const Text('Juntos, a partida fica melhor.',style:TextStyle(fontSize:32,fontWeight:FontWeight.w900,height:1.08)),const SizedBox(height:12),const Text('Um celular. Seus amigos. Nove desafios para jogar lado a lado.',style:TextStyle(color:Colors.white70,height:1.5)),const SizedBox(height:19),FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>const DotsPage())),icon:const Icon(Icons.play_arrow),label:const Text('Jogar agora'),style:FilledButton.styleFrom(backgroundColor:lilac,foregroundColor:ink))])))),
  SliverPadding(padding:const EdgeInsets.fromLTRB(20,0,20,0),sliver:SliverToBoxAdapter(child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Todos os jogos ✦',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),Text('${visible.length} JOGOS',style:const TextStyle(color:lilac,fontSize:11,fontWeight:FontWeight.w900))]))),
  SliverToBoxAdapter(child:SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.fromLTRB(20,15,20,18),child:Row(children:['Todos','Dupla','Grupo','Solo'].map((g)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(g),selected:filter==g,showCheckmark:false,onSelected:(_)=>setState(()=>filter=g),selectedColor:lilac,labelStyle:TextStyle(color:filter==g?ink:Colors.white70,fontWeight:FontWeight.bold)))).toList()))),
  SliverPadding(padding:const EdgeInsets.symmetric(horizontal:20),sliver:SliverLayoutBuilder(builder:(context,constraints){final wide=MediaQuery.sizeOf(context).width>610;return SliverGrid.builder(itemCount:visible.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:wide?3:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:wide?1.16:.77),itemBuilder:(context,i){final g=visible[i];return Material(color:panel,borderRadius:BorderRadius.circular(20),child:InkWell(borderRadius:BorderRadius.circular(20),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>g.builder())),child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(border:Border.all(color:Colors.white12),borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:g.color.withValues(alpha:.16),borderRadius:BorderRadius.circular(15)),child:Icon(g.icon,color:g.color,size:27)),const Spacer(),const Icon(Icons.arrow_forward,color:Colors.white38,size:18)]),
    const Spacer(),Text(g.tag,style:TextStyle(color:g.color,fontSize:9,letterSpacing:1.1,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(g.title,maxLines:2,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900,height:1.1)),const SizedBox(height:4),Text(g.detail,maxLines:2,style:const TextStyle(fontSize:11,color:Colors.white60)),const SizedBox(height:9),const Divider(color:Colors.white12,height:1),const SizedBox(height:8),Text('♟ ${g.players}',style:const TextStyle(color:Colors.white54,fontSize:10,fontWeight:FontWeight.bold))
 ]))));});})),
  const SliverPadding(padding:EdgeInsets.all(20),sliver:SliverToBoxAdapter(child:Text('Sem internet, contas ou anúncios. Compartilhe a diversão.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white54,fontSize:11))))
 ]))));
 }
}
