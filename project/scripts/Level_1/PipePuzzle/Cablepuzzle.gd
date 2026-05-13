extends Control

# ── Exports ────────────────────────────────────────────────────────────────────
@export var max_wrong_attempts: int = 5
@export var return_scene_path: String = "res://scenes/Level1/Level1.tscn"

# ── Constants ──────────────────────────────────────────────────────────────────
const CABLE_COLORS := {
	"red":    Color("ca150cff"),
	"yellow": Color("#c6b315"),
	"blue":   Color("#042985"),
	"green":  Color("#5a7e00"),
}
const CABLE_TEXTURES := {
	"red":    "res://assets/Objects/lvl1/CablePuzzle/Red Cable.png",
	"yellow": "res://assets/Objects/lvl1/CablePuzzle/Yellow Cable.png",
	"blue":   "res://assets/Objects/lvl1/CablePuzzle/Blue Cable.png",
	"green":  "res://assets/Objects/lvl1/CablePuzzle/Green Cable.png",
}
const SNAP_RADIUS : float = 45.0
const WIRE_WIDTH  : float = 10.0

# ── Node refs ──────────────────────────────────────────────────────────────────
@onready var left_panel    : Control = $Background/VBox/PanelRow/LeftPanel
@onready var right_panel   : Control = $Background/VBox/PanelRow/RightPanel
@onready var wire_layer    : Control = $Background/VBox/PanelRow/WireLayer
@onready var solved_banner : Control = $SolvedBanner
@onready var attempts_label: Label   = $Background/VBox/AttemptsLabel
@onready var close_btn     : Button  = $Background/VBox/TopBar/CloseButton
@onready var complete_layer : CanvasLayer = $CanvasLayer


# ── State ──────────────────────────────────────────────────────────────────────
var _cable_order : Array[String] = ["red", "yellow", "blue", "green"]
var _right_order : Array[String] = []
var _connections : Dictionary    = {}
var _wrong_count : int           = 0

# Drag state
var _dragging    : bool    = false
var _drag_color  : String  = ""
var _drag_line   : Line2D  = null
var _drag_origin : Vector2 = Vector2.ZERO

# Node/Slot maps
var _left_nodes  : Dictionary = {} # color -> TextureRect
var _right_slots : Dictionary = {} # color -> slot Control node

# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	Analytics.puzzle_started("cable_puzzle")
	solved_banner.hide()
	close_btn.pressed.connect(_close)
	_reset()

func _close() -> void:
	get_tree().change_scene_to_file(return_scene_path)

func _reset() -> void:
	_connections.clear()
	_wrong_count = 0
	_dragging    = false

	for child in wire_layer.get_children():
		child.queue_free()
	for child in left_panel.get_children():
		if child is TextureRect: child.queue_free()
	for child in right_panel.get_children():
		if child is TextureRect: child.queue_free()

	_left_nodes.clear()
	_right_slots.clear()

	_right_order = _cable_order.duplicate()
	_right_order.shuffle()

	_update_attempts_label()

	await get_tree().process_frame
	await get_tree().process_frame
	_build_panels()

func _build_panels() -> void:
	var n       = _cable_order.size()
	var cable_h = 32.0
	var lw      = left_panel.size.x   # 208
	var rw      = right_panel.size.x

	# Get hand-placed slot markers (settled after 2 frames)
	var l_slots = left_panel.get_children().filter(func(nd): return not nd is TextureRect)
	var r_slots = right_panel.get_children().filter(func(nd): return not nd is TextureRect)

	# ── Left panel ─────────────────────────────────────────────────────────────
	for i in n:
		var color_name = _cable_order[i]
		var cable = _make_cable_node(color_name, true, Vector2(lw, cable_h))
		left_panel.add_child(cable)

		# Use the exact slot Y so the cable overlays the pipe art in the background
		var slot_centre_y = l_slots[i].position.y
		cable.position = Vector2(0.0, slot_centre_y - cable_h * 0.5)

		_left_nodes[color_name] = cable
		cable.gui_input.connect(_on_left_input.bind(color_name))

	# ── Right panel ────────────────────────────────────────────────────────────
	for i in n:
		var color_name = _right_order[i]
		var cable = _make_cable_node(color_name, false, Vector2(rw, cable_h))
		right_panel.add_child(cable)

		var slot_node = r_slots[i]
		cable.position = Vector2(0.0, slot_node.position.y - cable_h * 0.5)

		_right_slots[color_name] = slot_node

func _make_cable_node(color_name: String, face_right: bool, sz: Vector2) -> TextureRect:
	var tex_rect = TextureRect.new()
	tex_rect.texture = load(CABLE_TEXTURES[color_name])
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = sz
	tex_rect.size = sz
	if not face_right:
		tex_rect.flip_h = true
	return tex_rect

# ── Input & Connections ───────────────────────────────────────────────────────
func _on_left_input(event: InputEvent, color_name: String) -> void:
	if _connections.get(color_name, false): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_drag(color_name)

func _start_drag(color_name: String) -> void:
	_dragging   = true
	_drag_color = color_name

	_drag_line = Line2D.new()
	_drag_line.width = WIRE_WIDTH
	_drag_line.default_color = CABLE_COLORS[color_name]
	_drag_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_drag_line.end_cap_mode   = Line2D.LINE_CAP_ROUND
	wire_layer.add_child(_drag_line)

	var cable      = _left_nodes[color_name]
	var tip_global = cable.global_position + Vector2(cable.size.x, cable.size.y * 0.5)
	_drag_origin   = wire_layer.get_global_transform().affine_inverse() * tip_global
	_drag_line.add_point(_drag_origin)
	_drag_line.add_point(_drag_origin)

func _input(event: InputEvent) -> void:
	if not _dragging: return

	if event is InputEventMouseMotion:
		var local_mouse = wire_layer.get_global_transform().affine_inverse() * event.global_position
		_drag_line.set_point_position(1, local_mouse)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_try_connect(event.global_position)

func _try_connect(global_drop: Vector2) -> void:
	_dragging  = false
	var best_color = ""
	var best_dist  = SNAP_RADIUS

	for color_name in _right_slots:
		if _connections.get(color_name, false): continue
		var slot_node = _right_slots[color_name]
		var dist = global_drop.distance_to(slot_node.global_position)
		if dist < best_dist:
			best_dist  = dist
			best_color = color_name

	if best_color == _drag_color:
		_on_correct_match(_drag_color)
	else:
		Analytics.log_event("mistake_made", {"puzzle_id": "cable_puzzle", "reason": "wrong_connection"})
		if _drag_line:
			_drag_line.queue_free()
			_drag_line = null
		_wrong_count += 1
		_update_attempts_label()
		if _wrong_count >= max_wrong_attempts:
			await get_tree().create_timer(0.4).timeout
			_reset()

func _on_correct_match(color_name: String) -> void:
	_connections[color_name] = true
	var target_slot = _right_slots[color_name]
	var end_local   = wire_layer.get_global_transform().affine_inverse() * target_slot.global_position
	_drag_line.set_point_position(1, end_local)

	_left_nodes[color_name].modulate.a = 0.5
	for child in right_panel.get_children():
		if child is TextureRect and child.texture == load(CABLE_TEXTURES[color_name]):
			child.modulate.a = 0.5

	if _connections.size() == _cable_order.size():
		_on_puzzle_solved()

func _update_attempts_label() -> void:
	attempts_label.text = "Attempts remaining: %d" % (max_wrong_attempts - _wrong_count)

func _on_puzzle_solved() -> void:
	Analytics.puzzle_solved("cable_puzzle", {"wrong_attempts": _wrong_count})
	Analytics.flush()
	complete_layer.visible = true
	var label = complete_layer.get_node("PuzzleCompleteLabel")
	label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.5)
	if has_node("/root/PuzzleProgress"):
		get_node("/root/PuzzleProgress").puzzle_solved("cable_puzzle")
	await get_tree().create_timer(2.0).timeout
	_close()
