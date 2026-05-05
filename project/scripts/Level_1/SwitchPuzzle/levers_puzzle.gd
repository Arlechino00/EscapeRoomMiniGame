extends Node2D

@export var spot_id: String = "levers_panel"

@onready var puzzle_completed = $CanvasLayer
@onready var switch_box = $SwitchBox

func _ready() -> void:
	var level_id = get_tree().current_scene.name
	Analytics.puzzle_started("levers_puzzle", level_id)
	puzzle_completed.hide()
	
	if PuzzleProgress.levers_puzzle_solved:
		_go_back()
		return
	
	switch_box.puzzle_solved.connect(_on_puzzle_solved)

func _input(event)->void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_go_back()

func _on_puzzle_solved()->void:
	var level_id = get_tree().current_scene.name
	Analytics.puzzle_solved("levers_puzzle", level_id)
	Analytics.flush()
	PuzzleProgress.puzzle_solved("levers_puzzle")
	
	for lever in switch_box.levers:
		lever.set_process_input(false)
	
	puzzle_completed.show()
	await get_tree().create_timer(2.0).timeout
	_go_back()

func _go_back()->void:
	get_tree().change_scene_to_file("res://scenes/Level1/Level1.tscn")
