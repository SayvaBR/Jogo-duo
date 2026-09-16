import 'dart:math';

const ticLines = <List<int>>[
  [0, 1, 2], [3, 4, 5], [6, 7, 8],
  [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6],
];

/// 0 = ongoing, 1/2 = winner, 3 = draw.
int ticOutcome(List<int> board) {
  for (final line in ticLines) {
    final first = board[line[0]];
    if (first != 0 && line.every((i) => board[i] == first)) return first;
  }
  return board.every((value) => value != 0) ? 3 : 0;
}

int fourOutcome(List<int> board) {
  const directions = <List<int>>[[1, 0], [0, 1], [1, 1], [1, -1]];
  for (var row = 0; row < 6; row++) {
    for (var col = 0; col < 7; col++) {
      final owner = board[row * 7 + col];
      if (owner == 0) continue;
      for (final dir in directions) {
        var connected = true;
        for (var offset = 1; offset <= 3; offset++) {
          final r = row + dir[0] * offset;
          final c = col + dir[1] * offset;
          if (r < 0 || r >= 6 || c < 0 || c >= 7 || board[r * 7 + c] != owner) {
            connected = false;
            break;
          }
        }
        if (connected) return owner;
      }
    }
  }
  return board.every((value) => value != 0) ? 3 : 0;
}

List<int>? fourDrop(List<int> board, int col, int player) {
  if (col < 0 || col >= 7 || board[col] != 0 || fourOutcome(board) != 0) return null;
  final next = List<int>.of(board);
  for (var row = 5; row >= 0; row--) {
    final i = row * 7 + col;
    if (next[i] == 0) {
      next[i] = player;
      return next;
    }
  }
  return null;
}

/// Edge identifiers are h-row-column or v-row-column on a 4 by 4 dot grid.
List<String> squareSides(int row, int col) => [
  'h-$row-$col', 'h-${row + 1}-$col', 'v-$row-$col', 'v-$row-${col + 1}',
];

class DotsResult {
  const DotsResult(this.owners, this.closed);
  final List<int> owners;
  final int closed;
}

DotsResult closeSquares(Set<String> edges, List<int> owners, int turn) {
  final next = List<int>.of(owners);
  var closed = 0;
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 3; col++) {
      final i = row * 3 + col;
      if (next[i] == 0 && squareSides(row, col).every(edges.contains)) {
        next[i] = turn;
        closed++;
      }
    }
  }
  return DotsResult(next, closed);
}

const sudokuSeed = '530070000600195000098000060800060003400803001700020006060000280000419005000080079';
const sudokuAnswer = '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

class SudokuPuzzle {
  const SudokuPuzzle(this.start, this.solution);
  final List<int> start, solution;
}

SudokuPuzzle newSudoku([Random? random]) {
  final rng = random ?? Random();
  final digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(rng);
  final bands = [0, 1, 2]..shuffle(rng);
  final stacks = [0, 1, 2]..shuffle(rng);
  final rows = <int>[];
  final cols = <int>[];
  for (final band in bands) {
    final inBand = [0, 1, 2]..shuffle(rng);
    rows.addAll(inBand.map((r) => band * 3 + r));
  }
  for (final stack in stacks) {
    final inStack = [0, 1, 2]..shuffle(rng);
    cols.addAll(inStack.map((c) => stack * 3 + c));
  }
  final flip = rng.nextBool();
  List<int> convert(String template) => List.generate(81, (index) {
    final r = index ~/ 9, c = index % 9;
    final source = (flip ? cols[c] : rows[r]) * 9 + (flip ? rows[r] : cols[c]);
    final value = int.parse(template[source]);
    return value == 0 ? 0 : digits[value - 1];
  });
  return SudokuPuzzle(convert(sudokuSeed), convert(sudokuAnswer));
}

Set<int> sudokuConflicts(List<int> board, int index) {
  final n = board[index];
  if (n == 0) return {};
  final row = index ~/ 9, col = index % 9;
  return {
    for (var i = 0; i < 81; i++)
      if (i != index && board[i] == n &&
        (i ~/ 9 == row || i % 9 == col ||
          (i ~/ 27 == index ~/ 27 && i % 9 ~/ 3 == col ~/ 3))) i,
  };
}
