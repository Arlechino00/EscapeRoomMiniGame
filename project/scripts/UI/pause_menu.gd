extends Control

func _ready() -> void:
	hide()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused = !get_tree().paused
	get_tree().paused = is_paused
	
	if is_paused:
		show()
	else:
		hide()


func _on_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/TitleScreen/TitleScreen.tscn") 


func _on_save_pressed() -> void:
	GameSave.initiate_full_save()
	
	
