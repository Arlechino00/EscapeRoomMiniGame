extends ColorRect


func _ready() -> void:
	_check_visibility()

func _process(_delta) -> void:
	_check_visibility()

func _check_visibility() -> void:
	var puzzles = GameSave.get_game_data().get("puzzles", {})
	if puzzles.get("cable_puzzle", false):
		hide()
	else:
		show() 
