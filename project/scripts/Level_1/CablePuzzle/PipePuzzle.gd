extends Control

# ── Tile mapping (each PNG used exactly once) ─────────────────────────────
#
# What each PNG looks like at rotation 0° (as drawn):
#   pipe_1: corner  — LEFT arm + DOWN arm      (opens W+S)
#   pipe_2: T       — LEFT+RIGHT arms + DOWN stem  (opens W+E+S)
#   pipe_3: corner  — LEFT arm + DOWN arm      (opens W+S, dash variant of pipe_1)
#   pipe_4: T       — UP+DOWN stem + RIGHT arm (opens N+S+E)
#   pipe_5: cross   — all 4 directions         (symmetric, always valid)
#   pipe_6: straight+small stub                (opens N+S, 0°==180°, both valid)
#   pipe_7: corner  — UP arm + RIGHT arm       (opens N+E)
#   pipe_8: corner  — UP arm + RIGHT arm       (opens N+E, dash variant)
#   pipe_9: corner  — UP arm + RIGHT arm       (opens N+E, dash variant)
#
# ── Reading the solved image, left→right, top→bottom ─────────────────────
#
#  [0] top-left:   W+S corner  → pipe_1 at 0°             solution_rot = 0
#  [1] top-mid:    W+E+S T     → pipe_2 at 0°             solution_rot = 0
#  [2] top-right:  N+W corner  → pipe_3: W+S→rot3=N+W ✓  solution_rot = 3
#
#  [3] mid-left:   N+S+W T     → pipe_4: N+S+E→rot2=N+S+W ✓  solution_rot = 2
#  [4] center:     cross       → pipe_5 (skip check)      solution_rot = 0
#  [5] mid-right:  N+S straight→ pipe_6 at 0°             solution_rot = 0
#
#  [6] bot-left:   N+E corner  → pipe_7 at 0°             solution_rot = 0
#  [7] bot-mid:    N+E corner  → pipe_8 at 0°             solution_rot = 0
#  [8] bot-right:  N+W corner  → pipe_9: N+E→rot3=W+N ✓  solution_rot = 3

const TILE_DEFS = [
	{ "file": "res://assets/Objects/lvl1/PipePuzzle/pipe_1.png", "solution_rot": 0 },
	{ "file": "res://assets/Objects/lvl1/PipePuzzle/pipe_2.png", "solution_rot": 0 },
	{ "file": "res://assets/Objects/lvl1/PipePuzzle/pipe_3.png", "solution_rot": 0 },
	{ "file": "res://assets/Objects/lvl1/PipePuzzle/pipe_4.png", "solution_rot": 0 },
	{ "file": "res://assets/Objects/lvl1/PipePuzzle/pipe_5.png", "solution_rot": 0 },
	{ "file": "res://assets/Objects/lvl1/PipePuzzle/pipe_6.png", "solution_rot": 0 },
	{ "file": "res://assets/Objects/lvl1/PipePuzzle/pipe_7.png", "solution_rot": 0 },
	{ "file": "res://assets/Objects/lvl1/PipePuzzle/pipe_8.png", "solution_rot": 0 },
	{ "file": "res://assets/Objects/lvl1/PipePuzzle/pipe_9.png", "solution_rot": 0 },
]

# Scrambled start — every tile is in a WRONG rotation.
# sol:   [ 0,  0,  0,  0,  -,  0/2, 0,  0,  0 ]
# start: [ 2,  3,  1,  0,  2,  3,   1,  2,  1 ]  ← none match solution ✓
const START_ROTS = [2, 3, 1,  0, 2, 3,  1, 2, 1]

# ── Node refs ──────────────────────────────────────────────────────────────
@onready var tile_container : GridContainer = $Background/GridContainer
@onready var check_btn      : Button        = $Background/CheckButton
@onready var close_btn      : Button        = $Background/CloseButton
#@onready var success_panel  : Panel         = $SuccessPanel
@onready var already_label  : Label         = $Background/AlreadyLabel
@onready var complete_layer : CanvasLayer = $CanvasLayer

var tile_rots : Array = []
var tiles     : Array = []
var solved    : bool  = false

# ── Init ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	var level_id = get_tree().current_scene.name
	Analytics.puzzle_started("pipe_puzzle", level_id)
	solved = PuzzleProgress.pipe_puzzle_solved

	if $Background.has_node("BgImage"):
		var bg = $Background.get_node("BgImage")
		bg.texture = load("res://assets/Objects/lvl1/PipePuzzle/pipe puzzle pc only.png")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		bg.offset_right = 0
		bg.offset_bottom = 0

	$Background.visible = true
	$ColorRect.visible = true

	# ── Let anchors handle positioning; only set separations ──
	tile_container.columns = 3
	tile_container.add_theme_constant_override("h_separation", 8)
	tile_container.add_theme_constant_override("v_separation", 8)
	# DO NOT set tile_container.position — the center-anchor in .tscn handles it

	# Position title and close relative to Background size
	# Background is 900×700 (offsets: -450 to 450, -350 to 350)
	$Background/TitleLabel.position = Vector2(20, 14)
	$Background/CloseButton.position = Vector2(860, 14)   # near top-right

	# CheckButton: below the grid. Grid is centered; 3 tiles × 128 + 2 gaps × 8 = 400px tall
	# Center of Background = (450, 350). Grid top = 350 - 200 = 150, bottom = 350 + 200 = 550
	$Background/CheckButton.position = Vector2(375, 570)

	check_btn.pressed.connect(_on_check_pressed)
	close_btn.pressed.connect(_on_close_pressed)

	_build_grid()

	if solved:
		_show_already_solved()
		
func _build_grid() -> void:
	tile_rots.clear()
	tiles.clear()

	for i in range(9):
		var rot = TILE_DEFS[i]["solution_rot"] if solved else START_ROTS[i]
		tile_rots.append(rot)

		# Wrapper button — handles clicks, fixed 128×128 slot in the grid
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(128, 128)
		btn.flat = true  # invisible button, no background
		btn.clip_contents = false

		# TextureRect child — this is what we actually rotate
		# Rotating the child avoids the GridContainer position drift
		# that happens when rotating a node that owns its own layout slot
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(TILE_DEFS[i]["file"])
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.texture_filter = Control.TEXTURE_FILTER_NEAREST
		tex_rect.custom_minimum_size = Vector2(128, 128)
		tex_rect.size = Vector2(128, 128)
		# Pivot at center of the 128×128 tile
		tex_rect.pivot_offset = Vector2(64, 64)
		tex_rect.rotation_degrees = rot * 90.0

		btn.add_child(tex_rect)

		var idx = i
		btn.pressed.connect(func(): _rotate_tile(idx))
		tile_container.add_child(btn)
		tiles.append(tex_rect)  # store the TextureRect, not the button

# ── Tile interaction ───────────────────────────────────────────────────────
func _rotate_tile(idx: int) -> void:
	if solved:
		return
	tile_rots[idx] = (tile_rots[idx] + 1) % 4
	var new_rot = tiles[idx].rotation_degrees + 90.0
	var tween = create_tween()
	tween.tween_property(tiles[idx], "rotation_degrees", new_rot, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# ── Check solution ─────────────────────────────────────────────────────────
func _on_check_pressed() -> void:
	if solved:
		return

	var correct = true
	print("--- Checking Solution ---")

	for i in range(9):
		var current  = tile_rots[i] % 4
		var expected = TILE_DEFS[i]["solution_rot"]

		if i == 4:
			# Cross: all rotations identical
			print("Tile 4 (cross): skipped ✓")
			continue
		elif i == 5:
			# Straight: 0° and 180° are visually identical
			if current != 0 and current != 2:
				print("Tile 5 (straight): WRONG — is ", current, ", needs 0 or 2")
				correct = false
			else:
				print("Tile 5 (straight): correct ✓")
		else:
			if current != expected:
				print("Tile ", i, ": WRONG — is ", current, ", needs ", expected)
				correct = false
			else:
				print("Tile ", i, ": correct ✓")

	if correct:
		print(">>> Puzzle SOLVED! <<<")
		_on_puzzle_solved()
	else:
		print("Not solved yet.")
		_shake_check_button()

func _on_puzzle_solved() -> void:
	solved = true
	var level_id = get_tree().current_scene.name
	Analytics.puzzle_solved("pipe_puzzle", level_id)
	Analytics.flush()
	PuzzleProgress.puzzle_solved("pipe_puzzle")
	_play_water_flow()

# ── Water flow animation: tint tiles blue one by one ──────────────────────
func _play_water_flow() -> void:
	var tween = create_tween()
	tween.set_parallel(false)
	# Column-by-column order: col0(0,3,6) → col1(1,4,7) → col2(2,5,8)
	var order = [0, 3, 6,  7, 4, 1,  2, 5, 8]
	for i in order:
		tween.tween_callback(func(): _tint_tile(tiles[i]))
		tween.tween_interval(0.18)
	tween.tween_callback(_show_success_panel)
	
func _tint_tile(node) -> void:  # untyped — lambda captures pass as Variant
	var t = create_tween()
	t.tween_property(node, "modulate", Color(0.3, 0.7, 1.0, 1.0), 0.25)

func _show_success_panel() -> void:
	complete_layer.visible = true
	var label = complete_layer.get_node("PuzzleCompleteLabel")
	label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.5)
	#tween.tween_property(complete_layer, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/Level1/Level1.tscn")
	)
# ── Already solved state (reopening a finished puzzle) ────────────────────
func _show_already_solved() -> void:
	check_btn.disabled = true
	already_label.visible = true
	for tex_rect in tiles:
		tex_rect.modulate = Color(0.3, 0.7, 1.0, 1.0)

# ── Wrong answer feedback ──────────────────────────────────────────────────
func _shake_check_button() -> void:
	var tween = create_tween()
	var orig = check_btn.position
	for i in range(6):
		var offset = 8.0 if i % 2 == 0 else -8.0
		tween.tween_property(check_btn, "position:x", orig.x + offset, 0.04)
	tween.tween_property(check_btn, "position:x", orig.x, 0.04)

func _on_close_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Level1/Level1.tscn")

func _on_close_success_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Level1/Level1.tscn")
