extends Area2D

@export var spot_id       : String = "door"
@export var requires_item : String = "Keycard"
@export var target_scene  : String = "res://scenes/Level3/Level3.tscn"

@onready var sprite_closed : Sprite2D        = $SpriteClosed
@onready var sprite_open   : Sprite2D        = $SpriteOpen
@onready var anim_player   : AnimationPlayer = $AnimationPlayer
@onready var text = $Label

@onready var vine1 = $SpriteClosed/Vine1
@onready var vine2 = $SpriteClosed/Vine2
@onready var vine3 = $SpriteClosed/Vine3
@onready var vine4 = $SpriteClosed/Vine4

var _used        : bool = false
var _opened      : bool = false
var _strings     : Dictionary = {}
var player_inside: bool = false

# Quiz state (reset each time quiz starts)
var _quiz_active  : bool = false
var _correct_count: int  = 0   # correct answers so far (need 3 to pass)
var _wrong_count  : int  = 0   # max 1 allowed; 2nd wrong = game over
var _question_idx : int  = 0
var _statements   : Array = []
var _answers      : Array = []  # expected is_true values

func _ready() -> void:
	sprite_open.visible = false
	_strings = GameStrings.get_spot(spot_id)
	text.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_vines()

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_inside = true
		text.text = get_prompt_text()
		text.show()

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_inside = false
		text.hide()

func _update_vines() -> void:
	var cleared = GameSave.get_game_data().get("vines_cleared", false)
	vine1.visible = not cleared and _correct_count < 1
	vine2.visible = not cleared and _correct_count < 2
	vine3.visible = not cleared and _correct_count < 3
	vine4.visible = not cleared and _wrong_count < 1

func interact() -> void:
	if _opened:
		_change_scene()
		return

	if _quiz_active:
		return

	var cleared = GameSave.get_game_data().get("vines_cleared", false)
	if not cleared:
		_start_ekko_quiz()
		return

	if not Inventory.has_item(requires_item):
		text.text = get_prompt_text()
		text.show()
		return

	Inventory.remove_item(requires_item)
	_open()

func _start_ekko_quiz() -> void:
	_quiz_active = true
	_correct_count = 0
	_wrong_count = 0
	_question_idx = 0
	text.hide()

	var d = GameSave.get_game_data()
	var current_id = d.get("current_puzzle_id", "question_1")
	var vines_id = _get_next_question_id(current_id)
	var data = GameStrings.get_puzzle_data(vines_id)
	_statements = data.get("statements", [])
	_answers.clear()
	for stmt in _statements:
		_answers.append(stmt.get("is_true", false))

	Analytics.log_event("puzzle_started", {"puzzle_id": "vines_puzzle"})

	print("[VinesPuzzle] Question set: ", vines_id)
	for i in range(_statements.size()):
		var stmt = _statements[i]
		print("  [%d] %s  →  %s" % [
			i + 1,
			stmt.get("text", ""),
			"TRUE" if stmt.get("is_true", false) else "FALSE"
		])

	get_tree().call_group("dialogue_box", "show_dialogue", "ekko_intro", _ask_next_question)

func _get_next_question_id(current_id: String) -> String:
	var num = int(current_id.split("_")[1])
	return "question_" + str((num % 3) + 1)

func _ask_next_question() -> void:
	if _question_idx >= _statements.size():
		_finish_quiz()
		return
	var stmt = _statements[_question_idx]
	var q_text = "Statement %d: %s" % [_question_idx + 1, stmt.get("text", "")]
	get_tree().call_group("dialogue_box", "show_question", q_text, _on_answered)

func _on_answered(answer: bool) -> void:
	var expected = _answers[_question_idx]
	_question_idx += 1
	var is_last := _question_idx >= _statements.size()

	if answer == expected:
		_correct_count += 1
		_update_vines()
		var next = _finish_quiz if is_last else _ask_next_question
		get_tree().call_group("dialogue_box", "show_dialogue", "ekko_correct", next)
	else:
		_wrong_count += 1
		Analytics.log_event("mistake_made", {
			"puzzle_id": "vines_puzzle",
			"wrong_attempts": _wrong_count,
			"reason": "wrong_answer"
		})
		_update_vines()
		if _wrong_count >= 2:
			get_tree().call_group("dialogue_box", "show_dialogue", "ekko_wrong", _do_game_over)
		else:
			var next = _finish_quiz if is_last else _ask_next_question
			get_tree().call_group("dialogue_box", "show_dialogue", "ekko_one_wrong", next)

func _finish_quiz() -> void:
	if _correct_count >= 3:
		get_tree().call_group("dialogue_box", "show_dialogue", "ekko_all_correct", _complete_quiz)
	else:
		get_tree().call_group("dialogue_box", "show_dialogue", "ekko_wrong", _do_game_over)

func _complete_quiz() -> void:
	_quiz_active = false
	_correct_count = 3
	_update_vines()

	var d = GameSave.get_game_data()
	d["vines_cleared"] = true
	GameSave.game_data = d
	GameSave.save_game()

	PuzzleProgress.puzzle_solved("vines_puzzle", {
		"wrong_attempts": _wrong_count,
		"question_id": _get_next_question_id(d.get("current_puzzle_id", "question_1"))
	})

	if player_inside:
		text.text = get_prompt_text()
		text.show()

func _do_game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/TitleScreen/TitleScreen.tscn")

func _change_scene() -> void:
	var d = GameSave.get_game_data()
	d["scene_transition"] = true
	GameSave.game_data = d
	GameSave.save_game()
	text.hide()
	Analytics.end_session(true, 1)
	Analytics.flush()
	if target_scene != "":
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(target_scene)

func _open() -> void:
	_used = true
	text.hide()
	if anim_player.has_animation("open"):
		anim_player.play("open")
		await anim_player.animation_finished
	else:
		sprite_closed.visible = false
		sprite_open.visible   = true
	_opened = true
	if player_inside:
		text.text = get_prompt_text()
		text.show()

func get_prompt_text() -> String:
	if _opened:
		return _strings.get("prompt_next", "Press E to go to next level")
	if _used:
		return ""
	var cleared = GameSave.get_game_data().get("vines_cleared", false)
	if not cleared:
		return "Press E — Clear the vines"
	if requires_item == "" or Inventory.has_item(requires_item):
		var use_template : String = _strings.get("prompt_use", "Press E — use {item} on {spot}")
		return use_template.format({"item": requires_item, "spot": _strings.get("name", spot_id)})
	var locked_template : String = _strings.get("prompt_locked", "{spot} — requires {item}")
	return locked_template.format({"item": requires_item, "spot": _strings.get("name", spot_id)})
