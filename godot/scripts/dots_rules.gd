extends RefCounted
## Pure turn/score/ownership logic for a 4x4 Points and Boxes board.
const BOXES: int = 4
const HORIZONTAL_COUNT: int = (BOXES + 1) * BOXES
const EDGE_COUNT: int = HORIZONTAL_COUNT * 2

var edges: Dictionary = {} # edge id -> player (1 or 2)
var owners: Array[int] = []
var turn: int = 1
var finished: bool = false
var last_edge: int = -1

func _init() -> void:
	owners.resize(BOXES * BOXES)
	owners.fill(0)

func horizontal_id(row: int, column: int) -> int:
	return row * BOXES + column

func vertical_id(row: int, column: int) -> int:
	return HORIZONTAL_COUNT + row * (BOXES + 1) + column

func score(player: int) -> int:
	return owners.count(player)

func remaining_edges() -> int:
	return EDGE_COUNT - edges.size()

func box_sides(row: int, column: int) -> Array[int]:
	return [horizontal_id(row, column), horizontal_id(row + 1, column), vertical_id(row, column), vertical_id(row, column + 1)]

## Returns -1 if the move is illegal; otherwise returns the number of boxes captured.
func play(edge_id: int) -> int:
	if finished or edge_id < 0 or edge_id >= EDGE_COUNT or edges.has(edge_id):
		return -1
	var actor: int = turn
	edges[edge_id] = actor
	last_edge = edge_id
	var captured: int = 0
	for row in range(BOXES):
		for column in range(BOXES):
			var index: int = row * BOXES + column
			if owners[index] != 0:
				continue
			var complete: bool = true
			for side in box_sides(row, column):
				if not edges.has(side):
					complete = false
					break
			if complete:
				owners[index] = actor
				captured += 1
	finished = not owners.has(0)
	if captured == 0 and not finished:
		turn = 3 - turn
	return captured
