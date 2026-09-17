import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ui.dart';

const winLines=<List<int>>[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
int ticOutcome(List<int> cells) {
  for(final line in winLines) {final p=cells[line[0]];if(p!=0&&p==cells[line[1]]&&p==cells[line[2]])return p;}
  return cells.every((n)=>n!=0)?3:0;
}
int fourOutcome(List<int> board) {
  for(var r=0;r<6;r++)for(var c=0;c<7;c++){
    final p=board[r*7+c];if(p==0)continue;
    for(final d in <List<int>>[[1,0],[0,1],[1,1],[1,-1]]){
      if(List.generate(3,(k)=>k+1).every((k){final y=r+k*d[0],x=c+k*d[1];return y>=0&&y<6&&x>=0&&x<7&&board[y*7+x]==p;}))return p;
    }
  }
  return board.every((n)=>n!=0)?3:0;
}
class TicPage extends StatefulWidget {const TicPage({super.key}); @override State<TicPage> createState()=>_TicPageState();}
class _TicPageState extends State<TicPage> {
 List<int> cells=List.filled(9,0);int turn=1,one=0,two=0;
 void play(int i){if(cells[i]!=0||ticOutcome(cells)!=0)return;setState((){cells[i]=turn;final result=ticOutcome(cells);if(result==1)one++;if(result==2)two++;if(result==0)turn=3-turn;});}
 @override Widget build(BuildContext context){final result=ticOutcome(cells);return GameFrame(title:'Jogo da velha',subtitle:'CLÁSSICO · 2 PESSOAS',child:SingleChildScrollView(padding:const EdgeInsets.all(16),child:Column(children:[
   DuoScore(first:one,second:two,turn:result==0?turn:0),TurnBanner(result==3?'EMPATE!':result>0?'JOGADOR $result VENCEU!':'VEZ DO JOGADOR $turn',color:result>0?gold:turn==1?blue:pink),
   ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:AspectRatio(aspectRatio:1,child:GridView.builder(physics:const NeverScrollableScrollPhysics(),itemCount:9,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,mainAxisSpacing:9,crossAxisSpacing:9),itemBuilder:(context,i)=>Material(color:panel,borderRadius:BorderRadius.circular(19),child:InkWell(borderRadius:BorderRadius.circular(19),onTap:()=>play(i),child:Center(child:Text(cells[i]==1?'✕':cells[i]==2?'◯':'',style:TextStyle(fontSize:60,fontWeight:FontWeight.w900,color:cells[i]==1?blue:pink))))))),
   const GameTip('Alinhe três símbolos na horizontal, vertical ou diagonal.'),ActionButton('Nova rodada',onPressed:()=>setState((){cells=List.filled(9,0);turn=1;})),
 ])));}
}
class FourPage extends StatefulWidget {const FourPage({super.key}); @override State<FourPage> createState()=>_FourPageState();}
class _FourPageState extends State<FourPage>{
 List<int> cells=List.filled(42,0);int turn=1,one=0,two=0;
 void drop(int col){if(fourOutcome(cells)!=0||cells[col]!=0)return;setState((){for(var r=5;r>=0;r--){if(cells[r*7+col]==0){cells[r*7+col]=turn;break;}}final result=fourOutcome(cells);if(result==1)one++;if(result==2)two++;if(result==0)turn=3-turn;});}
 @override Widget build(BuildContext context){final result=fourOutcome(cells);return GameFrame(title:'Ligue 4',subtitle:'ESTRATÉGIA · 2 PESSOAS',child:SingleChildScrollView(padding:const EdgeInsets.all(16),child:Column(children:[
   DuoScore(first:one,second:two,turn:result==0?turn:0),TurnBanner(result==3?'EMPATE!':result>0?'JOGADOR $result VENCEU!':'VEZ DO JOGADOR $turn · ${turn==1?'AZUL':'ROSA'}',color:result>0?gold:turn==1?blue:pink),
   ConstrainedBox(constraints:const BoxConstraints(maxWidth:530),child:AspectRatio(aspectRatio:7/7.4,child:Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:const Color(0xFF5553CF),borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFF7979F6),width:2)),child:Row(children:List.generate(7,(col)=>Expanded(child:InkWell(onTap:()=>drop(col),borderRadius:BorderRadius.circular(10),child:Column(children:[const SizedBox(height:26,child:Icon(Icons.keyboard_arrow_down,color:Colors.white70,size:24)),...List.generate(6,(row)=>Expanded(child:Padding(padding:const EdgeInsets.all(2),child:Container(decoration:BoxDecoration(shape:BoxShape.circle,color:cells[row*7+col]==1?blue:cells[row*7+col]==2?pink:ink,border:Border.all(color:Colors.black26,width:2))))))])))))),
   const GameTip('Toque em uma coluna para soltar sua peça. Faça quatro em linha, coluna ou diagonal.'),ActionButton('Nova rodada',onPressed:()=>setState((){cells=List.filled(42,0);turn=1;})),
 ])));}
}
class DotsPage extends StatefulWidget {const DotsPage({super.key}); @override State<DotsPage> createState()=>_DotsPageState();}
class _DotsPageState extends State<DotsPage> {
 final Map<String,int> edges={};final List<int> owners=List.filled(16,0);
 String? preview,last;int turn=1;bool done=false;
 String h(int r,int c)=>'h-$r-$c';String v(int r,int c)=>'v-$r-$c';
 List<String> sides(int r,int c)=>[h(r,c),h(r+1,c),v(r,c),v(r,c+1)];
 void put(String? edge){if(edge==null||done||edges.containsKey(edge))return;setState((){
    edges[edge]=turn;last=edge;preview=null;var captured=0;
    for(var r=0;r<4;r++)for(var c=0;c<4;c++){final i=r*4+c;if(owners[i]==0&&sides(r,c).every(edges.containsKey)){owners[i]=turn;captured++;}}
    done=owners.every((p)=>p!=0);if(!done&&captured==0)turn=3-turn;
  });}
 String? nearest(Offset p,double size){const margin=28.0;final unit=(size-2*margin)/4;String? selected;var best=unit*.40;
   for(var r=0;r<5;r++)for(var c=0;c<4;c++){final key=h(r,c);if(edges.containsKey(key))continue;final dist=math.sqrt(math.pow(p.dx-(margin+(c+.5)*unit),2)+math.pow(p.dy-(margin+r*unit),2));if(dist<best){best=dist;selected=key;}}
   for(var r=0;r<4;r++)for(var c=0;c<5;c++){final key=v(r,c);if(edges.containsKey(key))continue;final dist=math.sqrt(math.pow(p.dx-(margin+c*unit),2)+math.pow(p.dy-(margin+(r+.5)*unit),2));if(dist<best){best=dist;selected=key;}}
   return selected;
 }
 void track(Offset p,double size){if(done)return;final value=nearest(p,size);if(value!=preview)setState(()=>preview=value);}
 void reset(){setState((){edges.clear();owners.fillRange(0,16,0);turn=1;preview=null;last=null;done=false;});}
 @override Widget build(BuildContext context){final a=owners.where((x)=>x==1).length,b=owners.where((x)=>x==2).length;return GameFrame(title:'Pontos e caixas',subtitle:'TABULEIRO · 2 PESSOAS',child:LayoutBuilder(builder:(context,bounds){final width=math.min(bounds.maxWidth-20,590.0);return SingleChildScrollView(padding:const EdgeInsets.fromLTRB(10,4,10,18),child:Column(children:[
    DuoScore(first:a,second:b,turn:done?0:turn,middle:'CAIXAS'),TurnBanner(done?(a==b?'EMPATE!':'JOGADOR ${a>b?1:2} VENCEU!'):'VEZ DO JOGADOR $turn · ${turn==1?'AZUL':'ROSA'}',color:done?gold:turn==1?blue:pink),
    const SizedBox(height:6),SizedBox(width:width,height:width,child:GestureDetector(behavior:HitTestBehavior.opaque,
      onTapDown:(d)=>track(d.localPosition,width),onTapUp:(d)=>put(nearest(d.localPosition,width)),onTapCancel:()=>setState(()=>preview=null),
      onPanStart:(d)=>track(d.localPosition,width),onPanUpdate:(d)=>track(d.localPosition,width),onPanEnd:(_)=>put(preview),
      child:CustomPaint(painter:_DotsPainter(Map.of(edges),List.of(owners),preview,last),size:Size.square(width)))),
    const SizedBox(height:12),Row(mainAxisAlignment:MainAxisAlignment.center,children:[_legend(blue,'Jogador 1'),const SizedBox(width:18),_legend(pink,'Jogador 2'),const SizedBox(width:18),_legend(gold,'Última linha')]),
    const GameTip('Toque ou arraste até uma linha. A prévia mostra sua jogada; a última fica dourada. Fechou uma caixa? Você pontua e joga de novo.'),ActionButton('Nova partida',onPressed:reset),
  ]));}));}
 Widget _legend(Color color,String label)=>Row(mainAxisSize:MainAxisSize.min,children:[Container(width:8,height:8,decoration:BoxDecoration(color:color,shape:BoxShape.circle)),const SizedBox(width:4),Text(label,style:const TextStyle(color:Colors.white60,fontSize:9,fontWeight:FontWeight.bold))]);
}
class _DotsPainter extends CustomPainter{
 final Map<String,int> edges;final List<int> owners;final String? preview,last;
 _DotsPainter(this.edges,this.owners,this.preview,this.last);
 @override void paint(Canvas canvas,Size size){const gap=28.0;final s=(size.width-2*gap)/4;
   final rect=RRect.fromRectAndRadius(Offset.zero&size,const Radius.circular(24));
   canvas.drawRRect(rect,Paint()..color=const Color(0xFF1B2940));
   canvas.drawRRect(rect,Paint()..color=const Color(0xFF51607D)..style=PaintingStyle.stroke..strokeWidth=2);
   for(var r=0;r<4;r++)for(var c=0;c<4;c++){final player=owners[r*4+c];if(player==0)continue;final left=gap+c*s+7,top=gap+r*s+7;canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left,top,s-14,s-14),const Radius.circular(14)),Paint()..color=(player==1?blue:pink).withValues(alpha:.32));
     final text=TextPainter(text:TextSpan(text:player==1?'★':'♥',style:TextStyle(fontSize:s*.33,color:player==1?blue:pink,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout();text.paint(canvas,Offset(left+(s-14-text.width)/2,top+(s-14-text.height)/2));
   }
   void line(String key,Offset a,Offset b){final player=edges[key];final selected=preview==key;final color=key==last?gold:player==1?blue:player==2?pink:selected?(owners.isNotEmpty?blue:lilac):Colors.white.withValues(alpha:.13);
     canvas.drawLine(a,b,Paint()..color=Colors.black.withValues(alpha:.18)..strokeWidth=player!=null||selected?16:14..strokeCap=StrokeCap.round);
     canvas.drawLine(a,b,Paint()..color=color..strokeWidth=player!=null||selected?11:8..strokeCap=StrokeCap.round);
   }
   for(var r=0;r<5;r++)for(var c=0;c<4;c++)line('h-$r-$c',Offset(gap+c*s,gap+r*s),Offset(gap+(c+1)*s,gap+r*s));
   for(var r=0;r<4;r++)for(var c=0;c<5;c++)line('v-$r-$c',Offset(gap+c*s,gap+r*s),Offset(gap+c*s,gap+(r+1)*s));
   for(var r=0;r<5;r++)for(var c=0;c<5;c++){
     final p=Offset(gap+c*s,gap+r*s);canvas.drawCircle(p,9,Paint()..color=const Color(0xFF101427));canvas.drawCircle(p,6,Paint()..color=Colors.white);
   }
 }
 @override bool shouldRepaint(covariant _DotsPainter old)=>true;
}
