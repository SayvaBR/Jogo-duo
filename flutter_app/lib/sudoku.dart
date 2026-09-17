import 'dart:math';
import 'package:flutter/material.dart';
import 'ui.dart';

const _seed='530070000600195000098000060800060003400803001700020006060000280000419005000080079';
const _answer='534678912672195348198342567859761423426853791713924856961537284287419635345286179';
class SudokuPage extends StatefulWidget{const SudokuPage({super.key});@override State<SudokuPage> createState()=>_SudokuPageState();}
class _SudokuPageState extends State<SudokuPage>{
 late List<int> puzzle,solution,board;final Map<int,Set<int>> notes={};int selected=2,hints=3;bool pencil=false,done=false;String message='Preencha os espaços vazios com números de 1 a 9.';
 @override void initState(){super.initState();newPuzzle();}
 void newPuzzle(){final digits=List.generate(9,(i)=>i+1)..shuffle(Random());int convert(String s,int i){final n=int.parse(s[i]);return n==0?0:digits[n-1];}
   puzzle=List.generate(81,(i)=>convert(_seed,i));solution=List.generate(81,(i)=>convert(_answer,i));board=List.of(puzzle);selected=board.indexOf(0);notes.clear();hints=3;pencil=false;done=false;message='Preencha os espaços vazios com números de 1 a 9.';
 }
 bool conflicts(int index){final n=board[index];if(n==0)return false;final r=index~/9,c=index%9;for(var i=0;i<81;i++){if(i==index||board[i]!=n)continue;if(i~/9==r||i%9==c||(i~/27==r~/3&&i%9~/3==c~/3))return true;}return false;}
 void fill(int n){if(done||selected<0||puzzle[selected]!=0)return;setState((){
   if(pencil&&n!=0){notes.putIfAbsent(selected,()=>{});if(!notes[selected]!.add(n))notes[selected]!.remove(n);return;}
   board[selected]=n;notes.remove(selected);done=List.generate(81,(i)=>i).every((i)=>board[i]==solution[i]);message=done?'Parabéns! Sudoku resolvido!':conflicts(selected)?'Esse número está repetido na linha, coluna ou bloco.':'Continue resolvendo o desafio.';
 });}
 void hint(){if(done||hints==0)return;var i=selected;if(i<0||puzzle[i]!=0||board[i]==solution[i]){i=board.indexWhere((n)=>n==0);if(i<0)i=List.generate(81,(j)=>j).firstWhere((j)=>board[j]!=solution[j],orElse:()=>-1);}if(i<0)return;setState((){selected=i;hints--;board[i]=solution[i];notes.remove(i);done=List.generate(81,(j)=>j).every((j)=>board[j]==solution[j]);message=done?'Parabéns! Sudoku resolvido!':'Dica utilizada. Restam $hints dicas.';});}
 @override Widget build(BuildContext context)=>GameFrame(title:'Sudoku',subtitle:'DESAFIO INDIVIDUAL · OFFLINE',child:SingleChildScrollView(padding:const EdgeInsets.all(13),child:Column(children:[
   Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('${board.where((x)=>x!=0).length}/81 CASAS',style:const TextStyle(color:blue,fontWeight:FontWeight.w900)),Text('💡 $hints DICAS',style:const TextStyle(color:gold,fontWeight:FontWeight.w900))]),TurnBanner(message,color:done?mint:lilac),
   ConstrainedBox(constraints:const BoxConstraints(maxWidth:535),child:AspectRatio(aspectRatio:1,child:GridView.builder(itemCount:81,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:9),itemBuilder:(context,i){final n=board[i],r=i~/9,c=i%9;final same=selected>=0&&(r==selected~/9||c==selected%9);final selectedHere=i==selected;
     return GestureDetector(onTap:()=>setState(()=>selected=i),child:Container(decoration:BoxDecoration(color:selectedHere?lilac:conflicts(i)?const Color(0xFF764054):same?const Color(0xFF344462):panel,border:Border(top:BorderSide(color:Colors.white54,width:r%3==0?2:0.35),left:BorderSide(color:Colors.white54,width:c%3==0?2:0.35),right:BorderSide(color:Colors.white54,width:c==8?2:0),bottom:BorderSide(color:Colors.white54,width:r==8?2:0))),child:Center(child:n!=0?Text('$n',style:TextStyle(fontSize:19,fontWeight:puzzle[i]!=0?FontWeight.w900:FontWeight.w600,color:selectedHere?ink:puzzle[i]!=0?Colors.white:blue)):notes[i]?.isNotEmpty==true?Text((notes[i]!.toList()..sort()).join(' '),textAlign:TextAlign.center,style:const TextStyle(color:Colors.white54,fontSize:8)) :const SizedBox.shrink())));
   }))),
   const SizedBox(height:18),Row(children:List.generate(9,(i)=>Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:1),child:TextButton(onPressed:()=>fill(i+1),style:TextButton.styleFrom(padding:EdgeInsets.zero,minimumSize:const Size(0,47),backgroundColor:panel,foregroundColor:blue),child:Text('${i+1}',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900))))))),const SizedBox(height:10),
   Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()=>setState(()=>pencil=!pencil),icon:Icon(pencil?Icons.edit:Icons.edit_outlined,size:17),label:Text(pencil?'Notas: SIM':'Notas: NÃO'))),const SizedBox(width:7),Expanded(child:OutlinedButton.icon(onPressed:()=>fill(0),icon:const Icon(Icons.backspace_outlined,size:17),label:const Text('Apagar'))),const SizedBox(width:7),Expanded(child:OutlinedButton.icon(onPressed:hints>0&&!done?hint:null,icon:const Icon(Icons.lightbulb_outline,size:17),label:const Text('Dica')))]),
   const GameTip('Não repita números na mesma linha, coluna ou bloco 3 × 3. Use notas, três dicas e inicie novos desafios offline.'),ActionButton('Novo desafio',onPressed:()=>setState(newPuzzle)),
 ])));
}
