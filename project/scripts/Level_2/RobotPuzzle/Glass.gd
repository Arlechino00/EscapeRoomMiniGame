extends Area2D

@export var hammer_id      : String   = "Hammer"
@export var robot_arm_id   : String   = "Robot Arm"
@export var robot_arm_name : String   = "Robot Arm"
@export var robot_arm_icon : Texture2D = preload("res://assets/Objects/lvl2/Bitchass arm.png")

@onready var text_label   : Label    = $text
@onready var glass_fixed  : Sprite2D = $GlassFixed
@onready var glass_broken : Sprite2D = $GlassBroken

var is_broken       : bool = false
var _player_nearby  : bool = false

func _ready() -> void:
	text_label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if GameSave.is_item_picked(robot_arm_id) or Inventory.has_item(robot_arm_id) \
			or Inventory.has_item("Clean Robot Arm") or PuzzleProgress.robot_repair_solved:
		is_broken = true
		_update_visuals()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_broken:
		_player_nearby = true
		_refresh_text()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		text_label.hide()

func _refresh_text() -> void:
	if not _player_nearby:
		return
	text_label.text = get_prompt_text()
	text_label.show()

func interact() -> void:
	if is_broken:
		return
	if Inventory.has_item(hammer_id):
		_break_glass()
	else:
		_show_dialogue("This glass is too thick to smash bare-handed. I need something heavy — like a hammer.")

func _break_glass() -> void:
	is_broken = true
	_update_visuals()
	_show_dialogue("CRASH! The glass shatters. You reach in and grab the robot arm!")
	Inventory.add_item_ext({
		"id":    robot_arm_id,
		"name":  robot_arm_name,
		"icon":  robot_arm_icon,
		"color": Color.WHITE,
	})
	GameSave.mark_item_as_picked(robot_arm_id)
	text_label.hide()

func _update_visuals() -> void:
	glass_fixed.hide()
	glass_broken.show()
	$CollisionShape2D.set_deferred("disabled", true)

func get_prompt_text() -> String:
	if Inventory.has_item(hammer_id):
		return "Press E — Smash the glass"
	return "Press E — Examine Glass Showcase"

func _show_dialogue(msg: String) -> void:
	get_tree().call_group("dialogue_box", "show_text", msg)
