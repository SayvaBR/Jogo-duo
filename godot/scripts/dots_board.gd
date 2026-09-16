extends Control
## Native CanvasItem board: 4x4 boxes, full available width and forgiving touch targets.
signal move_played

const RULES = preload("res://scripts/dots_rules.gd")
const CYAN := Color("#64e7fa")
const PINK := Color("#ff82bb")
const MINT := Color("#77efc4")
const DIM := Color("#46536c")

var game = RULES.new()
var hover_edge: int = -1
var last_capture: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func reset() -> void:
	game = RULES.new()
	hover_edge = -1
	last_capture = 0
	queue_redraw()
	move_played.emit()

func score(player: int) -> int:
	return game.score(player)

func current_turn() -> int:
	return game.turn

func is_finished() -> bool:
	return game.finished

func capture_count() -> int:
	return last_capture

func _geometry() -> Array[float]:
	var span: float = maxf(50.0, minf(size.x - 28.0, size.y - 28.0))
	return [(size.x - span) / 2.0, (size.y - span) / 2.0, span / float(RULES.BOXES)]

func _position(row: int, column: int) -> Vector2:
	var g: Array[float] = _geometry()
	return Vector2(g[0] + column * g[2], g[1] + row * g[2])

func _segment(edge: int) -> Array[Vector2]:
	if edge < RULES.HORIZONTAL_COUNT:
		var row: int = edge / RULES.BOXES
		var column: int = edge % RULES.BOXES
		return [_position(row, column), _position(row, column + 1)]
	var local: int = edge - RULES.HORIZONTAL_COUNT
	var row: int = local / (RULES.BOXES + 1)
	var column: int = local % (RULES.BOXES + 1)
	return [_position(row, column), _position(row + 1, column)]

func _nearest_edge(at: Vector2) -> int:
	var nearest: int = -1
	var smallest: float = INF
	for edge in range(RULES.EDGE_COUNT):
		var segment: Array[Vector2] = _segment(edge)
		var start: Vector2 = segment[0]
		var delta: Vector2 = segment[1] - start
		var fraction: float = clampf((at - start).dot(delta) / delta.length_squared(), 0.0, 1.0)
		var distance: float = at.distance_to(start + fraction * delta)
		if distance < smallest:
			smallest = distance
			nearest = edge
	var cell: float = _geometry()[2]
	return nearest if smallest <= minf(32.0, cell * 0.32) else -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var proposed: int = _nearest_edge(event.position)
		if proposed != hover_edge:
			hover_edge = proposed
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var edge: int = _nearest_edge(event.position)
		if edge == -1:
			return
		var captured: int = game.play(edge)
		if captured == -1:
			return
		last_capture = captured
		hover_edge = -1
		queue_redraw()
		move_played.emit()
		accept_event()

func _draw() -> void:
	var g: Array[float] = _geometry()
	var frame: Rect2 = Rect2(g[0] - 13, g[1] - 13, g[2] * RULES.BOXES + 26, g[2] * RULES.BOXES + 26)
	draw_rect(frame, Color("#202943"), true)
	draw_rect(frame, Color("#596580"), false, 2.0)
	var font: Font = get_theme_default_font()
	for row in range(RULES.BOXES):
		for column in range(RULES.BOXES):
			var owner: int = game.owners[row * RULES.BOXES + column]
			var upper_left: Vector2 = _position(row, column)
			var area: Rect2 = Rect2(upper_left + Vector2(10, 10), Vector2(g[2] - 20, g[2] - 20))
			draw_rect(area, Color("#172238") if owner == 0 else (Color("#144c60") if owner == 1 else Color("#542a4b")), true)
			if owner > 0:
				var center: Vector2 = area.get_center()
				draw_circle(center, minf(g[2] * 0.21, 21.0), CYAN if owner == 1 else PINK)
				draw_string(font, center + Vector2(-6, 7), str(owner), HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#0b1225"))
	for edge in range(RULES.EDGE_COUNT):
		var points: Array[Vector2] = _segment(edge)
		var actor: int = int(game.edges.get(edge, 0))
		if edge == game.last_edge:
			draw_line(points[0], points[1], Color("#ffffff91"), 21.0, true)
		var tone: Color = CYAN if actor == 1 else (PINK if actor == 2 else DIM)
		var weight: float = 13.0 if actor != 0 else 10.0
		if edge == hover_edge and actor == 0 and not game.finished:
			tone = MINT
			weight = 18.0
		draw_line(points[0], points[1], tone, weight, true)
		for p in points:
			draw_circle(p, weight / 2.0, tone)
	for row in range(RULES.BOXES + 1):
		for column in range(RULES.BOXES + 1):
			var pos: Vector2 = _position(row, column)
			draw_circle(pos, 10.5, Color("#0d1429"))
			draw_circle(pos, 7.0, Color("#e4e7ff"))
