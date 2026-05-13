extends Node2D

@export var spot_id: String = "levers_panel"

var _strings: Dictionary = {}
var _wrong_attempts := 0
var _hints_used := 0

@onready var puzzle_complete_label = $CanvasLayer/PuzzleCompleteLabel
@onready var puzzle_complete_background = $CanvasLayer/ColorRect
@onready var switch_box = $SwitchBox
@onready var back_button = $CanvasLayer/Back
@onready var check_button = $CanvasLayer/Check
@onready var hint_button = $CanvasLayer/Hint
@onready var reading_ui = $ReadingUI


func _ready() -> void:
	Analytics.puzzle_started("levers_puzzle")
	puzzle_complete_background.hide()
	puzzle_complete_label.hide()
	
	if has_node("/root/GameStrings"):
		_strings = GameStrings.get_spot(spot_id)
	
	
	
	if PuzzleProgress.levers_puzzle_solved:
		_go_back()
		return
	
	if not back_button.pressed.is_connected(_go_back):
		back_button.pressed.connect(_go_back)
	if not check_button.pressed.is_connected(_on_check_pressed):
		check_button.pressed.connect(_on_check_pressed)
	if not hint_button.pressed.is_connected(_on_hint_pressed):
		hint_button.pressed.connect(_on_hint_pressed)

func _on_puzzle_solved()->void:
	Analytics.puzzle_solved("levers_puzzle", {"wrong_attempts": _wrong_attempts, "hints_used": _hints_used})
	Analytics.flush()
	PuzzleProgress.puzzle_solved("levers_puzzle")
	
	for lever in switch_box.levers:
		lever.set_process_input(false)
	
	puzzle_complete_label.text = "[center][wave][rainbow]Completed Puzzle"
	puzzle_complete_label.show()
	puzzle_complete_background.show()
	await get_tree().create_timer(2.0).timeout
	_go_back()

func _go_back()->void:
	get_tree().change_scene_to_file("res://scenes/Level1/Level1.tscn")

func _on_check_pressed() -> void:
	if switch_box._check_solution():
		_on_puzzle_solved()
	else:
		_wrong_attempts += 1
		Analytics.log_event("mistake_made", {"puzzle_id": "levers_puzzle", "wrong_attempts": _wrong_attempts})
		puzzle_complete_label.text = "Not quite right, try again!"
		puzzle_complete_label.show()
		await get_tree().create_timer(1.5).timeout
		puzzle_complete_label.hide()

func _on_hint_pressed() -> void:
	_hints_used += 1
	Analytics.log_event("hint_used", {"puzzle_id": "levers_puzzle", "hints_used": _hints_used})
	reading_ui.open_clue()
