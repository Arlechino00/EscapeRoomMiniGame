extends Area2D

@export var item_id : String = "Sponge"
@export var item_name : String = "Sponge"
@export var item_color : Color = Color.WHITE

@onready var text_label = $text
@onready var sprite = $Sprite2D

var _picked : bool = false
var _player_nearby : bool = false

func _ready() -> void:
	text_label.hide()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if GameSave.is_item_picked(item_id) or Inventory.has_item(item_id):
		_picked = true
		hide()
		$CollisionShape2D.set_deferred("disabled", true)

func interact() -> void:
	if _picked:
		return
	_picked = true
	
	Inventory.add_item_ext({
		"id": item_id,
		"name": item_name,
		"color": item_color,
		"icon": sprite.texture
	})
	
	GameSave.mark_item_as_picked(item_id)
	text_label.hide()
	hide()
	$CollisionShape2D.set_deferred("disabled", true)

func get_prompt_text() -> String:
	return "Press E — pick up Sponge"

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _picked:
		_player_nearby = true
		text_label.text = get_prompt_text()
		text_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		text_label.hide()
