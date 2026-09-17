import 'package:flutter/material.dart';
const ink = Color(0xFF101427);
const panel = Color(0xFF1D2540);
const lilac = Color(0xFFBCA9FF);
const blue = Color(0xFF66E0F5);
const pink = Color(0xFFFF89B6);
const mint = Color(0xFF79EABF);
const gold = Color(0xFFFFD77D);

class GameFrame extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const GameFrame({super.key, required this.title, required this.subtitle, required this.child});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: ink,
    appBar: AppBar(backgroundColor: ink, surfaceTintColor: ink, foregroundColor: Colors.white,
      titleSpacing: 0, title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(subtitle.toUpperCase(), style: const TextStyle(color: lilac, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      ])),
    body: SafeArea(top: false, child: child),
  );
}
class DuoScore extends StatelessWidget {
  final int first, second, turn;
  final String middle;
  const DuoScore({super.key, this.first=0, this.second=0, required this.turn, this.middle='VS'});
  @override Widget build(BuildContext context) => Row(children: [
    Expanded(child: _player(1,first,blue,turn==1)),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 10),child: Text(middle,style: const TextStyle(fontSize: 11,fontWeight: FontWeight.bold,color: Colors.white54))),
    Expanded(child: _player(2,second,pink,turn==2)),
  ]);
  Widget _player(int id,int value,Color color,bool active) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13,horizontal: 10),
    decoration: BoxDecoration(color: panel,borderRadius: BorderRadius.circular(15),border: Border.all(color:active?color:Colors.white12,width:active?2:1)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children:[
      Flexible(child: Text('JOGADOR $id',style:TextStyle(color:color,fontSize:10,fontWeight:FontWeight.w900))),
      Text('$value',style:TextStyle(color:color,fontSize:19,fontWeight:FontWeight.w900))
    ]),
  );
}
class TurnBanner extends StatelessWidget {
  final String text;
  final Color color;
  const TurnBanner(this.text,{super.key,this.color=lilac});
  @override Widget build(BuildContext context)=>Container(
    width:double.infinity,margin:const EdgeInsets.symmetric(vertical:12),padding:const EdgeInsets.all(13),
    decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(14)),
    child:Text(text,textAlign:TextAlign.center,style:TextStyle(color:color,fontSize:12,fontWeight:FontWeight.w900,letterSpacing:.5)),
  );
}
class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  const ActionButton(this.label,{super.key,required this.onPressed,this.icon=Icons.refresh});
  @override Widget build(BuildContext context)=>SizedBox(width:double.infinity,child:FilledButton.icon(
    onPressed:onPressed,icon:Icon(icon,size:19),label:Text(label,style:const TextStyle(fontWeight:FontWeight.w900)),
    style:FilledButton.styleFrom(backgroundColor:lilac,foregroundColor:ink,minimumSize:const Size(0,50),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),
  ));
}
class GameTip extends StatelessWidget {
  final String text;
  const GameTip(this.text,{super.key});
  @override Widget build(BuildContext context)=>Container(
    width:double.infinity,margin:const EdgeInsets.symmetric(vertical:14),padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(15),border:Border.all(color:Colors.white12)),
    child:Row(children:[const Icon(Icons.lightbulb_outline,color:gold,size:19),const SizedBox(width:10),Expanded(child:Text(text,style:const TextStyle(color:Colors.white70,fontSize:12,height:1.5)))]),
  );
}
