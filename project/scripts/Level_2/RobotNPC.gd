extends Area2D

@onready var broken_sprite = $"Broken Robot"
@onready var repaired_sprite = $"Repaired Robot"
@onready var text_label = $text

@export var clean_arm_id : String = "Clean Robot Arm"
@export var keycard_id : String = "Keycard"
@export var keycard_icon : Texture2D = preload("res://assets/Objects/Keycard.png")

var is_repaired : bool = false
var _player_nearby := false
var attempts : int = 0
var hints_used : int = 0

func _ready() -> void:
	is_repaired = PuzzleProgress.robot_repair_solved
	text_label.hide()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Inventory.inventory_changed.connect(_refresh_text)
	
	if is_repaired:
		_play_repaired_visuals()
	else:
		_play_broken_visuals()

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
	if prompt != "":
		text_label.text = "Press E — " + prompt
		text_label.show()
	else:
		text_label.hide()

func interact() -> void:
	if is_repaired:
		if not Inventory.has_item(keycard_id):
			_give_keycard()
		_show_dialogue_key("robot_lvl2_repaired")
		return
	
	attempts += 1
	if Inventory.has_item(clean_arm_id):
		_repair_robot()
	elif Inventory.has_item("Robot Arm"):
		_show_dialogue_key("robot_lvl2_has_arm")
	elif Inventory.has_item("Hammer"):
		hints_used += 1
		_show_dialogue_key("robot_lvl2_broken")
	else:
		_show_dialogue_key("robot_lvl2_broken")
	_refresh_text()

func _repair_robot() -> void:
	is_repaired = true
	Inventory.remove_item_ext(clean_arm_id)
	PuzzleProgress.puzzle_solved("robot_repair", {
		"attempts": attempts,
		"hints_used": hints_used,
		"wrong_answers": 0
	})
	
	_play_repaired_visuals()
	_give_keycard() # Give it immediately
	_show_dialogue_key("robot_lvl2_repaired")

func _give_keycard() -> void:
	if not Inventory.has_item(keycard_id):
		Inventory.add_item_ext({
			"id": keycard_id,
			"name": "Keycard",
			"icon": keycard_icon,
			"color": Color.GOLD
		})
		# We don't mark as picked because it's a reward instance
		# and it might conflict with Level 1's keycard flag.
		print("[Robot] Keycard given to player.")

func _play_repaired_visuals() -> void:
	broken_sprite.hide()
	repaired_sprite.show()

func _play_broken_visuals() -> void:
	broken_sprite.show()
	repaired_sprite.hide()

func _show_dialogue_key(key: String, on_finish: Callable = Callable()) -> void:
	get_tree().call_group("dialogue_box", "show_dialogue", key, on_finish)

func get_prompt_text() -> String:
	if is_repaired:
		return "Talk to Robot"
	if Inventory.has_item(clean_arm_id):
		return "Give Clean Arm to Robot"
	return "Talk to Robot"
