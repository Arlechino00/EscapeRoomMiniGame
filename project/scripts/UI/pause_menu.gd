extends Control

@onready var save_message: Label = $Background/SaveMessage

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused = !get_tree().paused
	get_tree().paused = is_paused
	if is_paused:
		show()
	else:
		hide()

func _on_save_pressed() -> void:
	GameSave.initiate_full_save()

	if Auth.is_local_mode():
		save_message.text = "Game saved locally."
	else:
		save_message.text = "Game saved successfully on the server."

	save_message.show()
	await get_tree().create_timer(3.0).timeout
	save_message.hide()

func _on_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/TitleScreen/TitleScreen.tscn")
