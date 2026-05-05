extends Control

@onready var start_button: Button = $VBoxContainer/Start_Button

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")
