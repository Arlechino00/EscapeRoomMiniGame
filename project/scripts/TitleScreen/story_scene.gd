extends Node2D

@export var target_scene: String = "res://scenes/Level1/Level1.tscn"
@export var typing_speed: float = 0.1

@onready var story_label = $CanvasLayer/StoryLabel
@onready var continue_label = $CanvasLayer/ContinueLabel

var pages: Array = []

var current_page: int = 0
var is_typing: bool = false
var full_text: String = ""

func _ready() -> void:
	pages = GameStrings.get_story("intro")
	continue_label.hide()
	_show_page(current_page)

func _show_page(index: int) -> void:
	full_text = pages[index]
	story_label.text = ""
	continue_label.hide()
	is_typing = true
	_type_text()

func _type_text() -> void:
	story_label.text = ""
	for i in range(full_text.length()):
		story_label.text += full_text[i]
		await get_tree().create_timer(typing_speed).timeout
		if not is_typing:
			break
	story_label.text = full_text
	is_typing = false
	continue_label.show()

func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if is_typing:
				is_typing = false
				story_label.text = full_text
				continue_label.show()
			else:
				current_page += 1
				if current_page >= pages.size():
					SceneTransition.boot_up(target_scene)
				else:
					_show_page(current_page)
