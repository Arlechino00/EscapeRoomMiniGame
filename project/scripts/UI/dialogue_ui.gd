extends CanvasLayer


@onready var panel = $Panel
@onready var name_label = $Panel/NameLabel
@onready var dialogue_label = $Panel/DialogueLabel
@onready var continue_label = $Panel/ContinueLabel
@onready var portrait_rect = $Panel/PortraitRect
@onready var choice_container = $Panel/ChoiceContainer
@onready var true_button = $Panel/ChoiceContainer/TrueButton
@onready var false_button = $Panel/ChoiceContainer/FalseButton

@export var typing_speed: float = 0.03

const PORTRAITS = {
	"Dr. Helsinki": preload("res://assets/Characters/doctor/doctor_icon.png"),
	"Broken Robot": preload("res://assets/Characters/broken_robot/broken_robot_icon.png"),
	"Robot": preload("res://assets/Characters/broken_robot/broken_robot_icon.png")
}
const PORTRAIT_EKKO := "res://assets/Characters/boss/Question_Mark.png"

var _lines: Array = []
var _current_line : int = 0
var _is_typing: bool = false
var _full_text: String = ""
var _on_finish: Callable
var _on_answer: Callable
var _is_question_mode: bool = false
var _typing_id: int = 0

func _ready() -> void:
	panel.hide()
	choice_container.hide()
	add_to_group("dialogue_box")
	true_button.pressed.connect(_on_true_pressed)
	false_button.pressed.connect(_on_false_pressed)

func _set_portrait(speaker: String) -> void:
	portrait_rect.texture = null
	portrait_rect.hide()
	if PORTRAITS.has(speaker):
		portrait_rect.texture = PORTRAITS[speaker]
		portrait_rect.show()
	elif speaker == "EKKO":
		var tex := load(PORTRAIT_EKKO) as Texture2D
		if tex:
			portrait_rect.texture = tex
			portrait_rect.show()

func show_text(text: String) -> void:
	show_dialogue_line(text)

func show_dialogue(key: String, on_finish: Callable = Callable()) -> void:
	_lines = GameStrings.get_dialogue(key)
	if _lines.is_empty():
		return
	_on_finish = on_finish
	_current_line = 0
	_is_question_mode = false
	choice_container.hide()
	panel.show()
	_show_line(_current_line)

func show_dialogue_line(line: String) -> void:
	_lines = [line]
	_current_line = 0
	_on_finish = Callable()
	_is_question_mode = false
	choice_container.hide()
	panel.show()
	_show_line(0)

func show_dialogue_lines(lines: Array, on_finish: Callable = Callable()) -> void:
	if lines.is_empty():
		if on_finish.is_valid():
			on_finish.call()
		return
	_lines = lines
	_on_finish = on_finish
	_current_line = 0
	_is_question_mode = false
	choice_container.hide()
	panel.show()
	_show_line(_current_line)

func show_question(text: String, on_answer: Callable) -> void:
	_on_answer = on_answer
	_is_question_mode = true
	_full_text = text
	name_label.text = "EKKO"
	_set_portrait("EKKO")
	dialogue_label.text = ""
	continue_label.hide()
	true_button.disabled = true
	false_button.disabled = true
	choice_container.show()
	panel.show()
	_is_typing = true
	_type_text()

func _show_line(index: int) -> void:
	_full_text = _lines[index]
	name_label.text = ""
	portrait_rect.hide()
	if ":" in _full_text:
		var parts = _full_text.split(":", true, 1)
		var speaker = parts[0].strip_edges()
		name_label.text = speaker
		_full_text = parts[1].strip_edges()
		_set_portrait(speaker)

	dialogue_label.text = ""
	continue_label.hide()
	_is_typing = true
	_type_text()

func _type_text() -> void:
	_typing_id += 1
	var current_id = _typing_id
	var local_full_text = _full_text
	
	dialogue_label.text = ""
	for i in range(local_full_text.length()):
		if not _is_typing or current_id != _typing_id:
			break
		dialogue_label.text += local_full_text[i]
		await get_tree().create_timer(typing_speed).timeout
	
	# Only proceed with finishing logic if this is still the active typing task
	if current_id == _typing_id:
		dialogue_label.text = local_full_text
		_is_typing = false
		if _is_question_mode:
			true_button.disabled = false
			false_button.disabled = false
		else:
			continue_label.show()

func _input(event) -> void:
	if not panel.visible:
		return
	if _is_question_mode:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if _is_typing:
				_is_typing = false
				dialogue_label.text = _full_text
				continue_label.show()
			else:
				_next_line()

func _next_line() -> void:
	_current_line += 1
	if _current_line >= _lines.size():
		panel.hide()
		if _on_finish.is_valid():
			_on_finish.call()
	else:
		_show_line(_current_line)

func _on_true_pressed() -> void:
	if _is_typing:
		_is_typing = false
		dialogue_label.text = _full_text
		true_button.disabled = false
		false_button.disabled = false
		return
	if _on_answer.is_valid():
		_is_question_mode = false
		choice_container.hide()
		panel.hide()
		var cb = _on_answer
		_on_answer = Callable()
		cb.call(true)

func _on_false_pressed() -> void:
	if _is_typing:
		_is_typing = false
		dialogue_label.text = _full_text
		true_button.disabled = false
		false_button.disabled = false
		return
	if _on_answer.is_valid():
		_is_question_mode = false
		choice_container.hide()
		panel.hide()
		var cb = _on_answer
		_on_answer = Callable()
		cb.call(false)
