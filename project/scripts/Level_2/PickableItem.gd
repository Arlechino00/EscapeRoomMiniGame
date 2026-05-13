extends Area2D

@export var item_id    : String    = "item"
@export var item_name  : String    = "Item"
@export var item_icon  : Texture2D = null
@export var item_color : Color     = Color.WHITE

@onready var text = $text

var _picked : bool = false

func _ready() -> void:
	text.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if GameSave.is_item_picked(item_id) or Inventory.has_item(item_id):
		_picked = true
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)

func interact() -> void:
	if _picked:
		return
	_picked = true
	Inventory.add_item({
		"id":    item_id,
		"name":  item_name,
		"color": item_color,
		"icon":  item_icon,
	})
	GameSave.mark_item_as_picked(item_id)
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
