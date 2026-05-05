extends CharacterBody2D

@export var acceleration : float = 550.0
@export var friction     : float = 12.0
@export var max_speed    : float = 300.0
@export var camera_zoom  : float = 1.0

@onready var camera        : Camera2D         = $Camera2D
@onready var interact_area : Area2D           = $InteractArea
@onready var prompt_label  : Label            = $Prompt
@onready var anim          : AnimatedSprite2D = $AnimatedSprite2D  # ← ADD THIS

#@export var world_width  : float = 3000.0
#@export var world_height : float = 3000.0

@export_group("Camera Limits")
@export var limit_left : int = 0
@export var limit_top : int = 0
@export var limit_right : int = 2000
@export var limit_bottom : int = 1500

var _nearby : Node2D = null

func _ready() -> void:
	print(anim)  # should print [AnimatedSprite2D:...], NOT null
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("idle")
	prompt_label.visible = false
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	camera.limit_left   = limit_left
	camera.limit_top    = limit_top
	camera.limit_right  = limit_right
	camera.limit_bottom = limit_bottom

func _on_animation_finished() -> void:
	if anim.animation in ["hit", "interact"]:
		anim.play("idle")

func _process(_delta: float) -> void:
	_check_proximity()
	if Input.is_action_just_pressed("interact") and _nearby != null:
		if _nearby.has_method("interact"):
			_nearby.interact()
			anim.play("interact")
	if Input.is_action_just_pressed("open_inventory"):
		get_tree().call_group("inventory_ui", "toggle")

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left",  "ui_right")
	direction.y = Input.get_axis("ui_up",    "ui_down")
	if Input.is_action_pressed("move_left"):  direction.x -= 1
	if Input.is_action_pressed("move_right"): direction.x += 1
	if Input.is_action_pressed("move_up"):    direction.y -= 1
	if Input.is_action_pressed("move_down"):  direction.y += 1
	if direction.length() > 1.0:
		direction = direction.normalized()
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
		if anim.animation not in ["hit", "interact"]:
			if abs(direction.y) > abs(direction.x):
				if direction.y < 0:
					anim.play("up")
				else:
					anim.play("down")
			else:
				anim.flip_h = direction.x < 0
				anim.play("walk")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * max_speed * delta)
		if anim.animation not in ["hit", "interact"]:
			anim.play("idle")
	move_and_slide()

func play_hit() -> void:
	anim.play("hit")

func _check_proximity() -> void:
	var overlapping = interact_area.get_overlapping_areas()
	_nearby = null
	for area in overlapping:
		var target : Node2D = null
		var text   : String = ""
		if area.has_method("get_prompt_text"):
			text   = area.get_prompt_text()
			target = area
		else:
			var obj = area.get_parent()
			if obj.has_method("get_prompt_text"):
				text   = obj.get_prompt_text()
				target = obj
		if text != "" and target != null:
			_nearby = target
			return
