extends Area2D

signal lever_changed

@export var is_up: bool = false

@onready var lever_down = $Lever_Down
@onready var lever_up = $Lever_Up


func _ready() -> void:
	_update_visuals()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle()

func toggle():
	is_up = !is_up
	_update_visuals()
	lever_changed.emit()
	print("Maneta este acum: ", "up" if is_up else "down")

func _update_visuals():

	if is_up:
		lever_down.hide()
		lever_up.show()
	else:
		lever_up.hide()
		lever_down.show()
