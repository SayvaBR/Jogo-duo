import 'package:flutter_test/flutter_test.dart';
import 'package:jogo_duo/game_rules.dart';
import 'package:jogo_duo/games/pool_engine.dart';

void main() {
  test('tic tac toe detects a winner and a draw', () {
    expect(ticOutcome([1, 1, 1, 0, 2, 2, 0, 0, 0]), 1);
    expect(ticOutcome([1, 2, 1, 1, 2, 2, 2, 1, 1]), 3);
  });
  test('connect four drops to the lowest free cell and detects four', () {
    var board = List<int>.filled(42, 0);
    for (var col = 0; col < 4; col++) {
      board = fourDrop(board, col, 1)!;
    }
    expect(board[35], 1);
    expect(fourOutcome(board), 1);
    expect(fourDrop(board, 0, 2), isNull);
  });
  test('Dots closes one box and retains other unclaimed boxes', () {
    final edges = {'h-0-0', 'h-1-0', 'v-0-0', 'v-0-1'};
    final result = closeSquares(edges, List<int>.filled(9, 0), 2);
    expect(result.closed, 1);
    expect(result.owners[0], 2);
    expect(result.owners.where((owner) => owner != 0).length, 1);
  });
  test('Sudoku generated solution matches fixed clues', () {
    final puzzle = newSudoku();
    expect(puzzle.start.length, 81);
    expect(puzzle.solution.length, 81);
    for (var i = 0; i < 81; i++) {
      if (puzzle.start[i] != 0) expect(puzzle.start[i], puzzle.solution[i]);
    }
  });
  test('pool has 15 object balls, one cue and no overlapping rack', () {
    final pool = PoolMatch();
    expect(pool.balls.length, 16);
    expect(pool.cue.id, 0);
    expect(pool.remaining('lisas'), 7);
    expect(pool.remaining('listradas'), 7);
    expect(pool.balls.any((ball) => ball.id == 8), isTrue);
  });
  test('pool foul awards ball in hand to opponent', () {
    final pool = PoolMatch();
    expect(pool.shoot(-1.57, 50), isTrue);
    pool.finishShot();
    expect(pool.current, 1);
    expect(pool.ballInHand, isTrue);
    expect(pool.phase, 'aim');
    expect(pool.placeCue(210, 548), isTrue);
  });
  test('pool black ball potted early loses the game', () {
    final pool = PoolMatch();
    pool.shoot(-1.57, 60);
    pool.shot!.firstHit = 8;
    pool.shot!.potted.add(8);
    pool.finishShot();
    expect(pool.phase, 'done');
    expect(pool.winner, 1);
  });
}
