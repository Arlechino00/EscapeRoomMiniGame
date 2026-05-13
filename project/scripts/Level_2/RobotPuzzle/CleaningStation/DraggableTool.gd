extends TextureRect

# Helper for dragging tools
func _get_drag_data(_at_position: Vector2) -> Variant:
	# 1. Create the preview node
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = size # Match original size
	
	# Keep full opacity as requested
	preview.modulate.a = 1.0
	
	# Center the preview under the mouse
	var preview_container = Control.new()
	preview_container.add_child(preview)
	preview.position = -size / 2
	
	set_drag_preview(preview_container)
	
	# 2. Return the data
	var tool_name = name.to_lower()
	return {"tool": tool_name}
