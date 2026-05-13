extends "res://scripts/Managers/World.gd"

@onready var dialogue_ui = $UI/DialogueUI
@onready var audio_player = $AudioStreamPlayer

@export var call_sound: AudioStream = preload("res://assets/Audio/call_audio.wav")

var _hint_indices: Dictionary = {
	"hint_lvl2_robot": 0,
	"hint_lvl2_hammer": 0,
	"hint_lvl2_glass": 0,
	"hint_lvl2_station": 0,
	"hint_lvl2_repaired": 0,
	"hint_lvl2_lift": 0,
	"hint_lvl2_ekko": 0
}

func _ready() -> void:
	super._ready()
	add_to_group("level")
	
	var puzzles = GameSave.get_game_data().get("puzzles", {})
	var last_shown = puzzles.get("last_dialogue_shown_lvl2", "")
	var robot_done = puzzles.get("robot_repair", false)
	
	if robot_done and last_shown == "intro":
		_save_last_dialogue("robot_repair")
		dialogue_ui.show_dialogue("robot_repair_done")
	elif last_shown == "":
		_save_last_dialogue("intro")
		dialogue_ui.show_dialogue("lvl2_intro")

func _save_last_dialogue(value: String) -> void:
	var d = GameSave.get_game_data()
	var puzzles = d.get("puzzles", {})
	puzzles["last_dialogue_shown_lvl2"] = value
	d["puzzles"] = puzzles
	GameSave.game_data = d
	GameSave.save_game()

func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if dialogue_ui and dialogue_ui.panel.visible:
				return
			_call_doctor()

func _call_doctor() -> void:
	_play_sound(call_sound)
	
	var puzzles = GameSave.get_game_data().get("puzzles", {})
	var robot_repaired = puzzles.get("robot_repair", false)
	var vines_cleared = GameSave.get_game_data().get("vines_cleared", false)
	
	var key = ""
	
	if not robot_repaired:
		if Inventory.has_item("Clean Robot Arm"):
			key = "hint_lvl2_repaired"
		elif Inventory.has_item("Robot Arm"):
			key = "hint_lvl2_station"
		elif Inventory.has_item("Hammer"):
			key = "hint_lvl2_glass"
		elif not Inventory.has_item("Hammer") and not Inventory.has_item("Sponge"):
			# Might need to find tools or talk to robot
			key = "hint_lvl2_robot"
		else:
			key = "hint_lvl2_hammer"
	else:
		if Inventory.has_item("Keycard") and not vines_cleared:
			# Likely at the lift or needs to go there
			key = "hint_lvl2_lift"
		elif vines_cleared:
			key = "hint_lvl2_lift" # Should be done, but maybe lost?
		else:
			key = "hint_lvl2_repaired" # Need to get keycard from robot if they don't have it

	if key == "":
		key = "hint_lvl2_robot"
		
	_show_single_hint(key)

func _show_single_hint(key: String) -> void:
	var lines = GameStrings.get_dialogue(key)
	if lines.is_empty():
		print("[Level2] No hint lines for: ", key)
		return
	var index = _hint_indices.get(key, 0)
	var line = lines[index]
	_hint_indices[key] = (index + 1) % lines.size()
	
	if dialogue_ui:
		dialogue_ui.show_dialogue_line(line)
	else:
		get_tree().call_group("dialogue_box", "show_text", line)

func _play_sound(stream: AudioStream) -> void:
	if stream == null: return
	if audio_player:
		audio_player.stream = stream
		audio_player.play()
	else:
		# Fallback if AudioStreamPlayer is missing in scene
		var asp = AudioStreamPlayer.new()
		add_child(asp)
		asp.stream = stream
		asp.play()
		asp.finished.connect(asp.queue_free)
