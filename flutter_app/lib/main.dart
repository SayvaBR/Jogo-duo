import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'games/classics.dart';
import 'games/ludo.dart';
import 'games/pool.dart';
import 'games/air_hockey.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const JogoDuoApp());
}

const bg = Color(0xFF0D1021);
const panel = Color(0xFF20263D);
const violet = Color(0xFFBBA8FF);
const cyan = Color(0xFF75E6FB);
const pink = Color(0xFFFF8DB9);
const mint = Color(0xFF77EAC0);
const gold = Color(0xFFFFD27B);

class JogoDuoApp extends StatelessWidget {
  const JogoDuoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Jogo Duo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: violet, surface: panel),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.5),
        headlineSmall: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -.7),
        titleLarge: TextStyle(fontWeight: FontWeight.w900),
        titleMedium: TextStyle(fontWeight: FontWeight.w800),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: violet, foregroundColor: const Color(0xFF17152F),
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      )),
    ),
    home: const GameCatalog(),
  );
}

class GameItem {
  const GameItem(this.title, this.subtitle, this.people, this.icon, this.tone, this.builder);
  final String title, subtitle, people;
  final IconData icon;
  final Color tone;
  final Widget Function(VoidCallback onFinish) builder;
}

class GameCatalog extends StatefulWidget {
  const GameCatalog({super.key});
  @override State<GameCatalog> createState() => _GameCatalogState();
}

class _GameCatalogState extends State<GameCatalog> {
  int finished = 0;
  String filter = 'Todos';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => finished = prefs.getInt('games_finished') ?? 0);
  }
  Future<void> _complete() async {
    setState(() => finished++);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('games_finished', finished);
  }
  late final List<GameItem> games = [
    GameItem('Air Rocket', 'Disco, reflexos e gols', '2 jogadores', Icons.sports_hockey, pink, (finish) => AirHockeyPage(onFinish: finish)),
    GameItem('Ludo', 'Corrida de peões e dados combinados', '2 a 4 jogadores', Icons.casino, violet, (finish) => LudoPage(onFinish: finish)),
    GameItem('Sinuca', 'Mesa de bola 8, física e tacadas', '2 jogadores', Icons.sports_bar, mint, (finish) => PoolPage(onFinish: finish)),
    GameItem('Jogo da velha', 'Três em linha vencem', '2 jogadores', Icons.grid_3x3, cyan, (finish) => TicPage(onFinish: finish)),
    GameItem('Ligue 4', 'Quatro peças em sequência', '2 jogadores', Icons.circle_outlined, gold, (finish) => ConnectPage(onFinish: finish)),
    GameItem('Pontos e caixas', 'Preencha mais quadrados', '2 jogadores', Icons.grid_on, mint, (finish) => DotsPage(onFinish: finish)),
    GameItem('Memória dupla', 'Encontre os oito pares', '2 jogadores', Icons.psychology, violet, (finish) => MemoryPage(onFinish: finish)),
    GameItem('Pedra, papel, tesoura', 'Escolhas secretas', '2 jogadores', Icons.back_hand, pink, (finish) => RpsPage(onFinish: finish)),
    GameItem('Sudoku', 'Desafio dos números', '1 jogador', Icons.apps, cyan, (finish) => SudokuPage(onFinish: finish)),
  ];
  @override Widget build(BuildContext context) {
    final shown = games.where((game) => filter == 'Todos' ||
      (filter == '2 jogadores' && game.people == '2 jogadores') ||
      (filter == 'Até 4' && game.people == '2 a 4 jogadores') ||
      (filter == 'Solo' && game.people == '1 jogador')).toList();
    return Scaffold(body: SafeArea(child: CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 10), sliver: SliverList(delegate: SliverChildListDelegate([
        Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: violet, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.sports_esports, color: bg, size: 28)),
          const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('JOGO DUO', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -1)), Text('SEU FLIPERAMA DE BOLSO', style: TextStyle(fontSize: 9, color: Color(0xFF929AB8), letterSpacing: 1))])),
          const Chip(label: Text('● OFFLINE', style: TextStyle(color: mint, fontSize: 10, fontWeight: FontWeight.bold)), backgroundColor: Color(0xFF19372F))]),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: const Color(0xFF322858), border: Border.all(color: const Color(0xFF6150A3)), borderRadius: BorderRadius.circular(26)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('✦ A DIVERSÃO COMEÇA AQUI', style: TextStyle(color: violet, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.3)),
          const SizedBox(height: 16), const Text('Juntos, a partida fica melhor.', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30, height: 1.1)),
          const SizedBox(height: 12), const Text('Um celular, seus amigos e nove jogos feitos para tocar, competir e rir.', style: TextStyle(color: Color(0xFFCDC7E2), height: 1.5)),
          const SizedBox(height: 20), FilledButton.icon(onPressed: () => _open(games[0]), icon: const Icon(Icons.play_arrow), label: const Text('Jogar agora')),
        ])), const SizedBox(height: 14),
        Row(children: [Expanded(child: _Stat('09', 'MINIJOGOS', Icons.videogame_asset, violet)), const SizedBox(width: 8), Expanded(child: _Stat('2–4', 'AMIGOS', Icons.people, cyan)), const SizedBox(width: 8), Expanded(child: _Stat('$finished', 'CONCLUÍDOS', Icons.emoji_events, gold))]),
        const SizedBox(height: 28), const Text('Escolha seu desafio ✦', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['Todos', '2 jogadores', 'Até 4', 'Solo'].map((value) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(value), selected: filter == value, onSelected: (_) => setState(() => filter = value)))).toList())),
        const SizedBox(height: 16),
      ]))),
      SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 18), sliver: SliverLayoutBuilder(builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        return SliverGrid(delegate: SliverChildBuilderDelegate((context, index) {
          final game = shown[index];
          return InkWell(onTap: () => _open(game), borderRadius: BorderRadius.circular(21), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: panel, border: Border.all(color: const Color(0xFF3F435C)), borderRadius: BorderRadius.circular(21)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(game.icon, color: game.tone, size: 31), const Spacer(), Text(game.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5), Text(game.subtitle, maxLines: 2, style: const TextStyle(fontSize: 10, color: Color(0xFFB2BAD1))),
            const SizedBox(height: 8), Text(game.people, style: TextStyle(fontSize: 10, color: game.tone, fontWeight: FontWeight.w800)),
          ])));
        }, childCount: shown.length), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: width < 560 ? 2 : 3, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 186));
      })),
      const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Text('SEM INTERNET · SEM ANÚNCIOS · FEITO PARA JOGAR JUNTO', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9EAAC6), fontWeight: FontWeight.bold, fontSize: 10)))),
    ])));
  }
  void _open(GameItem game) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => game.builder(_complete)));
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.caption, this.icon, this.tone);
  final String value, caption; final IconData icon; final Color tone;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)), child: Column(children: [Icon(icon, color: tone, size: 17), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(caption, style: const TextStyle(fontSize: 8, color: Color(0xFFB4BFDA), fontWeight: FontWeight.bold))]));
}

class GameFrame extends StatelessWidget {
  const GameFrame({super.key, required this.title, required this.subtitle, required this.children});
  final String title, subtitle; final List<Widget> children;
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(12, 6, 16, 8), child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Voltar aos jogos', onPressed: () => Navigator.of(context).pop()), const SizedBox(width: 5), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subtitle, style: const TextStyle(fontSize: 9, color: violet, fontWeight: FontWeight.w900, letterSpacing: 1)), Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))]))])),
    Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(14, 7, 14, 25), children: children)),
  ])));
}

class StatusBanner extends StatelessWidget {
  const StatusBanner(this.label, {super.key, this.tone = violet});
  final String label; final Color tone;
  @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: tone.withValues(alpha: .5))), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: tone, fontWeight: FontWeight.w900, fontSize: 13)));
}

class RestartButton extends StatelessWidget {
  const RestartButton(this.onTap, {super.key, this.label = 'Nova partida'});
  final VoidCallback onTap; final String label;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 16), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.refresh), label: Text(label))));
}
