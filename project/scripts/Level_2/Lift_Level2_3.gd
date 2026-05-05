extends Area2D

@export var spot_id       : String = "door"
@export var requires_item : String = ""
@export var target_scene  : String = "res://scenes/Level3/Level3.tscn"        

@onready var sprite_closed : Sprite2D        = $SpriteClosed
@onready var sprite_open   : Sprite2D        = $SpriteOpen
@onready var anim_player   : AnimationPlayer = $AnimationPlayer
@onready var text = $Label

var _used        : bool = false
var _opened      : bool = false   
var _strings     : Dictionary = {}
var player_inside: bool = false

func _ready() -> void:
	sprite_open.visible = false
	_strings = GameStrings.get_spot(spot_id)
	text.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_inside = true
		text.text = get_prompt_text()
		text.show()

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_inside = false
		text.hide()
		
func interact() -> void:
	
	if _opened:
		var d = GameSave.get_game_data()
		d["scene_transition"] = true
		GameSave.game_data = d
		GameSave.save_game()
		print("=== LIFT ===")
		print("scene_transition: ", GameSave.get_game_data().get("scene_transition"))
		print("player_x: ", GameSave.get_game_data().get("player_x"))
		print("player_y: ", GameSave.get_game_data().get("player_y"))
		text.hide()
		if target_scene != "":
			await get_tree().create_timer(0.5).timeout
			get_tree().change_scene_to_file(target_scene)
		return

	if _used:
		return

	if requires_item == "":
		_open()
		return

	if not Inventory.has_item(requires_item):
		return

	Inventory.remove_item(requires_item)
	_open()

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

	if requires_item == "":
		return _strings.get("prompt_open", "Press E to open")

	if Inventory.has_item(requires_item):
		var use_template : String = _strings.get("prompt_use", "Press E — use {item} on {spot}")
		return use_template.format({"item": requires_item, "spot": _strings.get("name", spot_id)})

	var locked_template : String = _strings.get("prompt_locked", "{spot} — requires {item}")
	return locked_template.format({"item": requires_item, "spot": _strings.get("name", spot_id)})
