extends Node2D

const ARM_STATES: Array[String] = [
	"res://assets/Objects/lvl2/puzzle_1/arms/Broken_arm_state_1.png",
	"res://assets/Objects/lvl2/puzzle_1/arms/broken_arm_state_2.png",
	"res://assets/Objects/lvl2/puzzle_1/arms/broken_arm_state_3.png",
	"res://assets/Objects/lvl2/puzzle_1/arms/dirty_arm_4.png",
	"res://assets/Objects/lvl2/puzzle_1/arms/fixed_arm_5.png",
]
const ROBOT_ARM_ID := "Robot Arm"
const CLEAN_ARM_ID := "Clean Robot Arm"

@onready var arm_sprite : TextureRect = $UI/ArmContainer/ArmSprite
@onready var exit_btn   : Button      = $UI/ExitButton
@onready var status_lbl : Label       = $UI/StatusLabel

var hammer_hits : int  = 0
var sponge_done : bool = false

func _ready() -> void:
	exit_btn.pressed.connect(_on_exit)
	
	# Setup the arm as a drop zone via the DropZone script signals
	arm_sprite.check_can_drop.connect(_on_check_can_drop)
	arm_sprite.data_dropped.connect(_on_data_dropped)
	
	_refresh()

func _on_check_can_drop(data: Variant, result: Dictionary) -> void:
	if typeof(data) != TYPE_DICTIONARY or not data.has("tool"):
		result["can_drop"] = false
		return
	
	var tool = data["tool"]
	if tool == "hammer":
		result["can_drop"] = hammer_hits < 3
	elif tool == "sponge":
		result["can_drop"] = hammer_hits >= 3 and not sponge_done
	else:
		result["can_drop"] = false

func _on_data_dropped(data: Variant) -> void:
	var tool = data["tool"]
	if tool == "hammer":
		_on_hammer()
	elif tool == "sponge":
		_on_sponge()

func _on_hammer() -> void:
	hammer_hits += 1
	match hammer_hits:
		1: _show_dialogue("Clang! The arm shifts slightly. Keep hitting!")
		2: _show_dialogue("Good hit! The metal is bending back into shape.")
		3: _show_dialogue("That did it — the arm is straightened. Now wipe off the grime.")
	_refresh()

func _on_sponge() -> void:
	sponge_done = true
	_show_dialogue("You scrub away the rust and grime. The arm looks almost new!")
	_refresh()
	await get_tree().create_timer(1.0).timeout
	_finish()

func _finish() -> void:
	var clean_icon: Texture2D = load(ARM_STATES[4])
	Inventory.remove_item_ext(ROBOT_ARM_ID)
	Inventory.remove_item_ext("Hammer")
	Inventory.remove_item_ext("Sponge")
	Inventory.add_item_ext({
		"id":    CLEAN_ARM_ID,
		"name":  "Clean Robot Arm",
		"icon":  clean_icon,
		"color": Color.WHITE,
	})
	_show_dialogue("The arm is clean and ready — bring it to the robot!")
	_on_exit()

func _on_exit() -> void:
	get_tree().change_scene_to_file("res://scenes/Level2/Level2.tscn")

func _show_dialogue(msg: String) -> void:
	# Since we are in a separate scene, we need to find the dialogue box or use a local one.
	# But typically these puzzles use a simplified dialogue or a local label.
	# For now, let's update the status label as well.
	status_lbl.text = msg

func _refresh() -> void:
	var idx := mini(hammer_hits, 3) if not sponge_done else 4
	arm_sprite.texture = load(ARM_STATES[idx])
	
	if sponge_done:
		status_lbl.text = "The arm is clean!"
	elif hammer_hits < 3:
		status_lbl.text = "Drag the Hammer to the arm to straighten it. (%d/3)" % hammer_hits
	else:
		status_lbl.text = "Now drag the Sponge to clean it."
