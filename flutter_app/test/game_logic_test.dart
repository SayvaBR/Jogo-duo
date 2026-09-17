import 'package:flutter_test/flutter_test.dart';
import 'package:jogo_duo/board_games.dart';
import 'package:jogo_duo/ludo.dart';
import 'package:jogo_duo/main.dart';

void main(){
 test('Jogo da velha reconhece vitória e empate',(){
   expect(ticOutcome([1,1,1,0,2,0,2,0,0]),1);
   expect(ticOutcome([1,2,1,1,2,2,2,1,1]),3);
   expect(ticOutcome(List.filled(9,0)),0);
 });
 test('Ligue 4 reconhece quatro peças horizontais e verticais',(){
   final horizontal=List.filled(42,0);for(var c=0;c<4;c++)horizontal[35+c]=1;expect(fourOutcome(horizontal),1);
   final vertical=List.filled(42,0);for(var r=2;r<6;r++)vertical[r*7]=2;expect(fourOutcome(vertical),2);
 });
 test('Ludo distingue base, pista e chegada',(){
   expect(ludoPosition(0,-1,0),[1,10]);expect(ludoPosition(0,0,0),[6,13]);expect(ludoPosition(0,56,0),[7,7]);
 });
 testWidgets('Tela inicial apresenta o Jogo Duo com nove jogos', (tester) async {
   await tester.pumpWidget(const JogoDuo());
   expect(find.text('JOGO DUO'),findsOneWidget);
   expect(find.text('9 JOGOS'),findsOneWidget);
 });
}
