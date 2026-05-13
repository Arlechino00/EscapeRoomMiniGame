extends "res://scripts/Managers/World.gd"

@onready var dialogue_ui = $UI/DialogueUI
@onready var audio_player = $AudioStreamPlayer

@export var boot_sound: AudioStream = preload("res://assets/Audio/Boot.wav")
@export var call_sound: AudioStream = preload("res://assets/Audio/call_audio.wav")

var _hint_indices: Dictionary = {
	"hint_wire_puzzle":0,
	"hint_pipe_puzzle":0,
	"hint_levers_puzzle":0
}

func _ready() -> void:
	super._ready()
	add_to_group("level")
	
	if not Inventory.has_item("Book"):
		Inventory.add_item_ext({
			"id": "Book",
			"name": "Book",
			"color": Color(0.6, 0.3, 0.1),
			"icon":"res://assets/Objects/lvl1/book.png"
		})
	
	var puzzles = GameSave.get_game_data().get("puzzles", {})
	var last_shown = puzzles.get("last_dialogue_shown", "")
	
	var cable_done  = puzzles.get("cable_puzzle",  false)
	var pipe_done   = puzzles.get("pipe_puzzle",   false)
	var levers_done = puzzles.get("levers_puzzle", false)
	
	var just_completed = ""
	if levers_done and last_shown == "pipe":
		just_completed = "levers"
	elif pipe_done and last_shown == "cable":
		just_completed = "pipe"
	elif cable_done and last_shown == "intro":
		just_completed = "cable"
	
	if just_completed == "levers":
		_save_last_dialogue("levers")
		dialogue_ui.show_dialogue("levers_puzzle_done")
	elif just_completed == "pipe":
		_save_last_dialogue("pipe")
		dialogue_ui.show_dialogue("pipe_puzzle_done")
	elif just_completed == "cable":
		_save_last_dialogue("cable")
		dialogue_ui.show_dialogue("wire_puzzle_done")
	elif last_shown == "":
		_play_sound(boot_sound)
		await get_tree().create_timer(3.0).timeout
		_save_last_dialogue("intro")
		dialogue_ui.show_dialogue("intro")

func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		push_error("Audio stream is null!!")
	audio_player.stream = stream
	audio_player.play()

func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if dialogue_ui.panel.visible:
				return
			_call_doctor()

func _call_doctor() -> void:
	
	_play_sound(call_sound)
	
	var puzzles = GameSave.get_game_data().get("puzzles", {})
	var wire_done = puzzles.get("cable_puzzle", false)
	var pipe_done = puzzles.get("pipe_puzzle", false)
	var levers_done = puzzles.get("levers_puzzle", false)
	
	var key = ""
	if not wire_done:
		key = "hint_wire_puzzle"
	elif not pipe_done:
		key = "hint_pipe_puzzle"
	elif not levers_done:
		key = "hint_levers_puzzle"
	else:
		return
	_show_single_hint(key)

func _show_single_hint(key: String) -> void:
	var lines = GameStrings.get_dialogue(key)
	if lines.is_empty():
		return
	var index = _hint_indices[key]
	var line = lines[index]
	_hint_indices[key] = (index + 1) % lines.size()
	dialogue_ui.show_dialogue_line(line)

func on_wire_puzzle_completed() -> void:
	dialogue_ui.show_dialogue("wire_puzzle_done")

func on_pipe_puzzle_completed() -> void:
	dialogue_ui.show_dialogue("pipe_puzzle_done")
	
func on_levers_puzzle_completed() -> void:
	dialogue_ui.show_dialogue("levers_puzzle_done")

func _save_last_dialogue(value: String) -> void:
	var d = GameSave.get_game_data()
	var puzzles = d.get("puzzles", {})
	puzzles["last_dialogue_shown"] = value
	d["puzzles"] = puzzles
	GameSave.game_data = d
	GameSave.save_game()
