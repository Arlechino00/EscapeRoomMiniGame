extends Control

@onready var start_button: Button = $MainMenu/Start_Button
@onready var main_menu = $MainMenu
@onready var start_menu = $StarMenu
@onready var login_panel = $LoginPanel
@onready var nickname_input: LineEdit = $LoginPanel/NicknameInput
@onready var pin_input: LineEdit = $LoginPanel/PinInput
@onready var status_label: Label = $LoginPanel/StatusLabel
@onready var title_label = $RichTextLabel

func _ready() -> void:
	main_menu.visible = true
	start_menu.visible = false
	login_panel.visible = false

	Auth.login_finished.connect(_on_auth_login_finished)
	Auth.register_finished.connect(_on_auth_register_finished)

func _on_start_button_pressed() -> void:
	main_menu.hide()
	title_label.hide()
	login_panel.show()
	nickname_input.grab_focus()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	pass

# --- Login panel ---

func _on_login_button_pressed() -> void:
	var nick = nickname_input.text.strip_edges()
	var pin = pin_input.text.strip_edges()
	if nick.is_empty() or pin.is_empty():
		status_label.text = "Please enter a nickname and PIN."
		return
	status_label.text = "Logging in..."
	Auth.login(nick, pin)

func _on_register_button_pressed() -> void:
	var nick = nickname_input.text.strip_edges()
	var pin = pin_input.text.strip_edges()
	if nick.is_empty() or pin.is_empty():
		status_label.text = "Please enter a nickname and PIN."
		return
	status_label.text = "Registering..."
	Auth.register_player(nick, pin)

func _on_play_locally_button_pressed() -> void:
	var nick = nickname_input.text.strip_edges()
	Auth.play_locally(nick if not nick.is_empty() else "Local Player")

func _on_login_back_button_pressed() -> void:
	login_panel.hide()
	title_label.show()
	main_menu.show()
	status_label.text = ""
	nickname_input.text = ""
	pin_input.text = ""

# --- Auth callbacks ---

func _on_auth_login_finished(success: bool, message: String) -> void:
	if success:
		login_panel.hide()
		start_menu.show()
		status_label.text = ""
	else:
		status_label.text = message

func _on_auth_register_finished(success: bool, message: String) -> void:
	if success:
		login_panel.hide()
		start_menu.show()
		status_label.text = ""
	else:
		status_label.text = message

# --- Start menu ---

func _on_new_game_button_pressed() -> void:
	Inventory.clear_inventory()
	GameSave.game_data = {}

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
	d["current_puzzle_id"] = chosen_puzzle_id
	GameSave.set_game_data(d)

	print("[TITLE SCREEN] Am salvat în C++ ID-ul: ", GameSave.get_game_data().get("current_puzzle_id"))

	var starting_level = "res://scenes/TitleScreen/story_scene.tscn"

	if FileAccess.file_exists(starting_level):
		SceneTransition.fade_to(starting_level)
	else:
		print("Error: Didn't find the starting scene")

func _on_load_save_button_pressed() -> void:
	GameSave.load_game_and_apply()

func _on_back_button_pressed() -> void:
	start_menu.hide()
	login_panel.show()
