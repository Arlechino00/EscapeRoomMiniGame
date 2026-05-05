## Inventory.gd
## Autoload singleton backed by the C++ InventorySystem.
extends InventorySystem

signal inventory_changed

func _ready() -> void:
	print("[Inventory] C++ backend ready. Max slots: ", get_max_slots())

# ── Add an item ───────────────────────────────────────────
func add_item_ext(item: Dictionary) -> bool:
	if not item.has("id"):
		item["id"] = item.get("name", "")
	var added = add_item(item)
	if added:
		inventory_changed.emit()
		print("[Inventory] Added: ", item.get("name", "?"))
	else:
		print("[Inventory] Full or invalid: ", item.get("name", "?"))
	
	return added

# ── Remove an item by id ──────────────────────────────────
func remove_item_ext(item_id: String) -> bool:
	var removed := remove_item(item_id)
	if removed:
		inventory_changed.emit()
		print("[Inventory] Removed: ", item_id)
	return removed
	
# ── Get all items (used by UI) ────────────────────────────
func get_items() -> Array:
	return get_all_items()
'''
# ── Check if an item exists ───────────────────────────────
func has_item(item_id: String) -> bool:
	return _cpp.has_item(item_id)



# ── Get a single item by id ───────────────────────────────
func get_item(item_id: String) -> Dictionary:
	return _cpp.get_item(item_id)

# ── Get item count ────────────────────────────────────────
func count() -> int:
	return _cpp.get_item_count()

# ── Clear everything ──────────────────────────────────────
func clear() -> void:
	_cpp.clear()
	emit_signal("inventory_changed")

# ── Max slots ─────────────────────────────────────────────
func get_max_slots() -> int:
	return _cpp.get_max_slots()
'''	

func clear_inventory() -> void:
	clear()
	inventory_changed.emit()
	print("[Inventory] Cleared everything.")
