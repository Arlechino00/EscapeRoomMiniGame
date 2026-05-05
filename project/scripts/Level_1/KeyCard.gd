
extends Area2D

@export var item_name  : String    = "Item"
@export var item_color : Color     = Color.GOLD
@export var item_icon  : Texture2D = null
@export var required_puzzles: Array[String] = ["pipe_puzzle", "levers_puzzle", "cable_puzzle"]
@export var requires_puzzles: bool = false

@onready var text = $text

var _picked : bool = false

func _ready() -> void:
	# Auto-set item_name from sprite texture filename if still default
	if item_name == "Item":
		var sprite = get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			var path = sprite.texture.resource_path
			item_name = path.get_file().get_basename().capitalize()
	text.hide()
	
	if requires_puzzles:
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		set_process(true)
	else:
		set_process(false)
		
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# FINAL CHECK: If we already have this item, disappear immediately
	if Inventory.has_item(item_name):
		_picked = true
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		set_process(false)

func _process(_delta) -> void:
	if _all_puzzles_solved():
		visible = true
		$CollisionShape2D.set_deferred("disabled", false)
		print("The key has appeared")
		set_process(false)

func _all_puzzles_solved() -> bool:
	var puzzles = GameSave.get_game_data().get("puzzles", {})
	for id in required_puzzles:
		if not puzzles.get(id, false):
			return false
	return true

func interact() -> void:
	if _picked:
		return
	_picked = true

	
	var icon = item_icon
	if icon == null:
		var sprite = get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			icon = sprite.texture

	Inventory.add_item({
		"id":    item_name,
		"name":  item_name,
		"color": item_color,
		"icon":  icon,
	})
	text.hide()
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)

func get_prompt_text() -> String:
	if _picked:
		return ""
	return "Press E — pick up \"%s\"" % item_name

func _on_body_entered(body) -> void:
	if body.is_in_group("player") and not _picked:
		text.text = get_prompt_text()
		text.show()

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		text.hide()
