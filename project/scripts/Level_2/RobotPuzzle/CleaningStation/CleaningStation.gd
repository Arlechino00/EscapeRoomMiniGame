extends Area2D

const TABLE_SCENE_PATH = "res://scenes/Level2/Puzzle Robot/Table.tscn"

@export var robot_arm_id      : String = "Robot Arm"
@export var clean_robot_arm_id: String = "Clean Robot Arm"

@onready var text_label = $text

var _player_nearby := false

func _ready() -> void:
	text_label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Inventory.inventory_changed.connect(_refresh_text)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		_refresh_text()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		text_label.hide()

func _refresh_text() -> void:
	if not _player_nearby:
		return
	var prompt = get_prompt_text()
	text_label.text = prompt
	text_label.visible = (prompt != "")

func interact() -> void:
	if Inventory.has_item(clean_robot_arm_id):
		_show_dialogue("You already have the cleaned arm — bring it to the robot!")
		return
	if not Inventory.has_item(robot_arm_id):
		_hint_missing_arm()
		return
	
	# Save current position so we can return here
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var d = GameSave.get_game_data()
		d["player_x"] = player.global_position.x
		d["player_y"] = player.global_position.y
		# Ensure scene_transition is false so World.gd restores position
		d["scene_transition"] = false
		GameSave.game_data = d
		GameSave.save_game()
	
	# Transition to the standalone table scene
	get_tree().change_scene_to_file(TABLE_SCENE_PATH)

func _hint_missing_arm() -> void:
	var has_hammer : bool = Inventory.has_item("Hammer")
	var has_sponge : bool = Inventory.has_item("Sponge")
	if has_hammer and has_sponge:
		_show_dialogue("You've got the hammer and the sponge — but what exactly are you planning to clean? Go smash that glass showcase and bring the robot arm first!")
	elif has_hammer:
		_show_dialogue("The hammer is ready, but the arm isn't here yet. Go break that glass wall and get it!")
	elif has_sponge:
		_show_dialogue("A sponge alone won't do much. Find a hammer, break the glass wall over there, and bring the robot arm back.")
	else:
		_show_dialogue("This is a repair station. The robot arm is locked in a glass case nearby — grab a hammer and smash it open.")

func _show_dialogue(msg: String) -> void:
	get_tree().call_group("dialogue_box", "show_text", msg)

func get_prompt_text() -> String:
	if Inventory.has_item(robot_arm_id):
		return "Press E — Use Cleaning Station"
	return "Cleaning Station"
