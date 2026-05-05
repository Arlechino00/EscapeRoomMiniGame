extends Area2D

# ── Exports ────────────────────────────────────────────────────────────────────
@export var spot_id       : String = "cable_puzzle"
@export var target_scene  : String = "res://scenes/Level1/puzzles/CablePuzzle/Cablepuzzle.tscn"

var _strings : Dictionary = {}
var player_inside = false 

@onready var text = $Text

func _ready() -> void:
	text.hide()
	if has_node("/root/GameStrings"):
		_strings = GameStrings.get_spot(spot_id)
	text.text = _strings.get("prompt_open", "Press E to interact")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body)->void:
	if body.is_in_group("player"):
		if _is_solved():
			return
		player_inside = true
		text.show()

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_inside = false
		text.hide()

func _input(event) -> void:
	if player_inside and event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:
			if _is_solved():
				return
			GameSave.initiate_full_save()
			text.hide()
			get_tree().change_scene_to_file(target_scene)

func _is_solved() -> bool:
	var puzzles = GameSave.get_game_data().get("puzzles", {})
	return puzzles.get("cable_puzzle", false)
