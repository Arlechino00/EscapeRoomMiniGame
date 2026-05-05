## InventoryUI.gd
## Attach to: InventoryUI (CanvasLayer)
## Add this node to group "inventory_ui"
extends CanvasLayer

@onready var panel     : PanelContainer = $Panel
@onready var item_list : VBoxContainer  = $Panel/VBoxContainer/ItemList
@onready var title     : Label          = $Panel/VBoxContainer/Title
@onready var close_btn : Button         = $Panel/VBoxContainer/CloseButton
@onready var bag_btn   : Button         = $BagButton

func _ready() -> void:
	panel.visible = false
	_style_panel()
	_style_bag_button()

	var ui_strings : Dictionary = GameStrings.get_section("ui")
	title.text     = ui_strings.get("inventory_title", "INVENTORY")
	close_btn.text = ui_strings.get("close_button", "✕  CLOSE")

	close_btn.pressed.connect(_on_close_pressed)
	bag_btn.pressed.connect(toggle)
	Inventory.inventory_changed.connect(_refresh_ui)
	_refresh_ui()

# ── Keyboard input ────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		toggle()

# ── Toggle ────────────────────────────────────────────────
func toggle() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		_refresh_ui()

func _on_close_pressed() -> void:
	panel.visible = false

# ── Style the panel ───────────────────────────────────────
func _style_panel() -> void:
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left   = -320
	panel.offset_right  = -12
	panel.offset_top    = -380
	panel.offset_bottom = 380

	var bg := StyleBoxFlat.new()
	bg.bg_color          = Color(0.04, 0.06, 0.10, 0.96)
	bg.border_color      = Color(0.0, 0.85, 1.0, 0.9)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(6)
	bg.shadow_color      = Color(0.0, 0.85, 1.0, 0.25)
	bg.shadow_size       = 12
	panel.add_theme_stylebox_override("panel", bg)

	title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color     = Color(0.0, 0.85, 1.0, 0.15)
	btn_style.border_color = Color(0.0, 0.85, 1.0, 0.8)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", btn_style)
	close_btn.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	close_btn.add_theme_font_size_override("font_size", 14)

# ── Style the bag button ──────────────────────────────────
func _style_bag_button() -> void:
	bag_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bag_btn.offset_left   = -80
	bag_btn.offset_right  = -12
	bag_btn.offset_top    = 12
	bag_btn.offset_bottom = 52

	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.04, 0.06, 0.10, 0.92)
	style.border_color = Color(0.0, 0.85, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	bag_btn.add_theme_stylebox_override("normal", style)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color     = Color(0.0, 0.85, 1.0, 0.2)
	style_hover.border_color = Color(0.0, 0.85, 1.0, 1.0)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(6)
	bag_btn.add_theme_stylebox_override("hover", style_hover)

	bag_btn.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	bag_btn.text = "[ BAG ]"

# ── Rebuild item list ─────────────────────────────────────
func _refresh_ui() -> void:
	for child in item_list.get_children():
		child.queue_free()
	
	var items = Inventory.get_all_items()
	for item in items:
		var tex_rect = TextureRect.new()
		var icon_data = item.get("icon", "")
		
		if icon_data is String and icon_data != "":
			if FileAccess.file_exists(icon_data):
				tex_rect.texture = load(icon_data)
			else:
				print("[InventoryUI] Error this path doesn't exist")
		elif icon_data is Texture2D:
			tex_rect.texture = icon_data

	if items.is_empty():
		var lbl := Label.new()
		lbl.text                 = "— empty —"
		lbl.modulate             = Color(0.0, 0.9, 1.0, 0.35)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_list.add_child(lbl)
		return

	for item in items:
		var row := PanelContainer.new()

		var row_style := StyleBoxFlat.new()
		row_style.bg_color     = Color(0.0, 0.85, 1.0, 0.07)
		row_style.border_color = Color(0.0, 0.85, 1.0, 0.3)
		row_style.set_border_width_all(1)
		row_style.set_corner_radius_all(4)
		row.add_theme_stylebox_override("panel", row_style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		row.add_child(hbox)

		# Icon slot — shows item texture if available, colored square otherwise
		var icon_wrap := PanelContainer.new()
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color     = Color(0.0, 0.85, 1.0, 0.1)
		icon_style.border_color = Color(0.0, 0.85, 1.0, 0.7)
		icon_style.set_border_width_all(1)
		icon_style.set_corner_radius_all(3)
		icon_wrap.add_theme_stylebox_override("panel", icon_style)
		icon_wrap.custom_minimum_size = Vector2(40, 40)

		var icon_texture = item.get("icon", null)
		if icon_texture != null:
			var tex_rect := TextureRect.new()			
			if typeof(icon_texture) == TYPE_STRING:  # <- This is fo loading
				tex_rect.texture = load(icon_texture)
			else:
				tex_rect.texture = icon_texture
			
			tex_rect.expand_mode         = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex_rect.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(36, 36)
			icon_wrap.add_child(tex_rect)
		else:
			var fallback := ColorRect.new()
			fallback.color               = item.get("color", Color(0.0, 0.85, 1.0, 0.3))
			fallback.custom_minimum_size = Vector2(36, 36)
			icon_wrap.add_child(fallback)

		hbox.add_child(icon_wrap)

		# Item name
		var name_lbl := Label.new()
		name_lbl.text = item.get("name", "Unknown").to_upper()
		name_lbl.add_theme_color_override("font_color", Color(0.85, 0.97, 1.0))
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)

		# Quantity badge
		var qty : int = item.get("quantity", 1)
		if qty > 1:
			var qty_lbl := Label.new()
			qty_lbl.text = "x" + str(qty)
			qty_lbl.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
			qty_lbl.add_theme_font_size_override("font_size", 13)
			hbox.add_child(qty_lbl)
			
			# Forțăm rândul să proceseze mouse-ul
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Foarte important: Spunem textului și iconiței să NU fure click-ul
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if item.get("quantity", 1) > 1:
			hbox.get_child(hbox.get_child_count()-1).mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Conectăm click-ul
		row.gui_input.connect(func(event):
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					print("!!!! CLICK DETECTAT PE RÂND !!!!") # Mesaj de siguranță
					_on_slot_cliked(item)
		)
		
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		item_list.add_child(row)
		
func _on_slot_cliked(slot_data):
	print(slot_data)
	if slot_data.get("id", "") == "puzzle_paper":
		$"../ReadingUI".open_clue()
	else:
		pass
