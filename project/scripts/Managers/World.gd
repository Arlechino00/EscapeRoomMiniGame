extends Node2D

@export var world_width  : float = 1900.0
@export var world_height : float = 3000.0

@onready var spawn = $PlayerManager/Spawn
@onready var items_node  : Node2D = $Interactions/Items
@onready var spots_node  : Node2D = $Interactions/UseSpot

# World.gd
func _ready() -> void:
	var d = GameSave.get_game_data()
	
	# Read and clear the flag HERE, immediately, before this node is freed
	if d.get("scene_transition") == true:
		print("[WORLD] Detecatată tranziție de nivel. Mut jucătorul la Spawn.")
		d["scene_transition"] = false
		GameSave.game_data = d
		GameSave.save_game()
		call_deferred("_move_player_to_spawn")
	else:
		call_deferred("_restore_player_position")

func _move_player_to_spawn() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn.global_position
		print("Player spawned at: ", spawn.global_position)

func _restore_player_position() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var d = GameSave.get_game_data()
	var x = float(d.get("player_x", 0.0))
	var y = float(d.get("player_y", 0.0))
	player.global_position = Vector2(x, y) if (x != 0.0 or y != 0.0) else spawn.global_position
	print("Player restored at: ", player.global_position)
