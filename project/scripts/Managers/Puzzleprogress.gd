extends Node


var pipe_puzzle_solved : bool = false
var cable_puzzle_solved : bool = false
var levers_puzzle_solved : bool = false


var puzzles_solved : int = 0

func _ready() -> void:
	
	var puzzles = GameSave.get_game_data().get("puzzles", {})
	pipe_puzzle_solved = puzzles.get("pipe_puzzle", false)
	cable_puzzle_solved = puzzles.get("cable_puzzle", false)
	levers_puzzle_solved = puzzles.get("levers_puzzle", false)
	
	puzzles_solved = 0
	if pipe_puzzle_solved: puzzles_solved += 1
	if cable_puzzle_solved: puzzles_solved += 1
	if levers_puzzle_solved: puzzles_solved += 1
	
	print("PuzzleProgress loaded - solved: ", puzzles_solved)

func puzzle_solved(puzzle_id: String) -> void:
	match puzzle_id:
		"pipe_puzzle":
			if not pipe_puzzle_solved:
				pipe_puzzle_solved = true
				puzzles_solved += 1
				_save(puzzle_id)
		"cable_puzzle":
			if not cable_puzzle_solved:
				cable_puzzle_solved = true
				puzzles_solved += 1
				_save(puzzle_id)
		"levers_puzzle":
			if not levers_puzzle_solved:
				levers_puzzle_solved = true
				puzzles_solved += 1
				_save(puzzle_id)
	
	print("Total puzzles solved: ", puzzles_solved)

func _save(puzzle_id : String) -> void:
	var d = GameSave.get_game_data()
	var puzzles = d.get("puzzles", {})
	puzzles[puzzle_id] = true
	d["puzzles"] = puzzles
	GameSave.save_game()
	print("Saved: ", puzzle_id)
