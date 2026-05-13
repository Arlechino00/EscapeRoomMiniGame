extends CanvasLayer

@onready var rect = $ColorRect
var _tween: Tween

func _ready()-> void:
	rect.color = Color.BLACK
	rect.modulate.a = 0.0

func fade_to(target_scene: String)-> void:
	await _fade_in()
	get_tree().change_scene_to_file(target_scene)
	await _fade_out()
	
func _fade_in() -> void:
	_tween = create_tween()
	_tween.tween_property(rect, "modulate:a", 1.0, 0.8)
	await _tween.finished

func _fade_out() -> void:
	_tween = create_tween()
	_tween.tween_property(rect, "modulate:a", 0.0, 0.8)
	await _tween.finished
	
func boot_up(target_scene: String) -> void:
	await _scanlines_in()
	get_tree().change_scene_to_file(target_scene)
	await _scanlines_out()

func _scanlines_in() -> void:
	rect.color = Color.WHITE
	_tween = create_tween()
	_tween.tween_property(rect, "modulate:a", 1.0, 0.1)
	await _tween.finished
	await get_tree().create_timer(0.2).timeout
	rect.color = Color.BLACK
	await get_tree().create_timer(0.3).timeout

func _scanlines_out() -> void:
	rect.color = Color.BLACK
	rect.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_property(rect, "modulate:a", 0.0, 1.2)
	await _tween.finished
