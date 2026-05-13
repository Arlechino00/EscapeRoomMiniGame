extends Sprite2D

signal puzzle_solved

@onready var levers = [$Lever_1, $Lever_2, $Lever_3, $Lever_4]

var correct_answers: Array = []

func _ready() -> void:
	
	var d = GameSave.get_game_data()
	var puzzle_id = d.get("current_puzzle_id", "")
	
	if puzzle_id == "":
		push_error("SwitchBox: No puzzle ID found")
		return
	
	var data = GameStrings.get_puzzle_data(puzzle_id)
	if data.is_empty():
		push_error("SwitchBox: No data found for " + puzzle_id)
		return
	
	var statements = data.get("statements", [])
	for s in statements:
		correct_answers.append(s.get("is_true", false))
		
	for lever in levers:
		lever.lever_changed.connect(_on_lever_changed)
	
	print("SwitchBox ready. Correct answers are: ", correct_answers)


func _on_lever_changed() -> void:
	if _check_solution():
		puzzle_solved.emit()
	else:
		Analytics.log_event("mistake_made", {"puzzle_id": "levers_puzzle", "reason": "wrong_combination"})

func _check_solution() -> bool:
	print("Levers count: ", levers.size(), " | Answers count: ", correct_answers.size())
	if levers.size() != correct_answers.size():
		push_error("Mismatch: %d levers but %d answers" % [levers.size(), correct_answers.size()])
		return false
	
	for i in range(levers.size()):
		var lever_val = levers[i].is_up
		var answer_val = correct_answers[i]
		print("Lever ", i+1, ": is_up=", lever_val, " (", typeof(lever_val), ") | expected=", answer_val, " (", typeof(answer_val), ") | match=", lever_val == answer_val)

	
	for i in range(levers.size()):
		if levers[i].is_up != correct_answers[i]:
			return false
	
	return true
		
