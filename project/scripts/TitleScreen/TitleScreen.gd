extends Control

@onready var start_button: Button = $MainMenu/Start_Button
@onready var main_menu = $MainMenu
@onready var start_menu = $StarMenu

func _ready() -> void:
	main_menu.visible = true
	start_menu.visible = false
func _on_start_button_pressed() -> void:
	main_menu.hide()
	start_menu.show()
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()
	

func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_new_game_button_pressed() -> void:
	Inventory.clear_inventory()
	GameSave.game_data = {}
	
	#For puzzle_3
	
	var data = GameStrings.load_json("res://data/Questions.json")
	
	if data.is_empty() or not data.has("puzzles"):
		print("Error: the questions couldn't be loaded")
		return
	
	var keys = data["puzzles"].keys()
	randomize()
	var random_index = randi() % keys.size()
	var chosen_puzzle_id = keys[random_index]
	
	print("[Random]: I have chosen a puzzle: ", chosen_puzzle_id)
	
	Analytics.log_event("question_assigned", {
		"question_id": chosen_puzzle_id
	})
	Analytics.flush()
	
	var d = GameSave.get_game_data()
	d["current_puzzle_id"] = chosen_puzzle_id;
	GameSave.set_game_data(d)
	
	print("[TITLE SCREEN] Am salvat în C++ ID-ul: ", GameSave.get_game_data().get("current_puzzle_id"))
	
	
	var starting_level = "res://scenes/Level1/Level1.tscn"
	
	if FileAccess.file_exists(starting_level):
		get_tree().change_scene_to_file(starting_level)
	else:
		print("Error: Didn't find the starting scene")


func _on_load_save_button_pressed() -> void:
	GameSave.load_game_and_apply()


func _on_back_button_pressed() -> void:
	start_menu.hide()
	main_menu.show()
