extends TextureRect

# This helper script allows us to override virtual methods on a child node
# without needing to create a separate .gd file for every puzzle piece.

signal data_dropped(data)
signal check_can_drop(data, result_dict)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var result = {"can_drop": false}
	check_can_drop.emit(data, result)
	return result["can_drop"]

func _drop_data(at_position: Vector2, data: Variant) -> void:
	data_dropped.emit(data)
