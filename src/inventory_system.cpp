#include "inventory_system.h"

namespace godot {

InventorySystem::InventorySystem() {}

void InventorySystem::_bind_methods() {
    ClassDB::bind_method(D_METHOD("add_item", "item"), &InventorySystem::add_item);
    ClassDB::bind_method(D_METHOD("remove_item", "item_id"), &InventorySystem::remove_item);
    ClassDB::bind_method(D_METHOD("has_item", "item_id"), &InventorySystem::has_item);
    ClassDB::bind_method(D_METHOD("get_item", "item_id"), &InventorySystem::get_item);
    ClassDB::bind_method(D_METHOD("get_all_items"), &InventorySystem::get_all_items);
    ClassDB::bind_method(D_METHOD("clear"), &InventorySystem::clear);
    ClassDB::bind_method(D_METHOD("get_item_count"), &InventorySystem::get_item_count);
    ClassDB::bind_method(D_METHOD("set_max_slots", "slots"), &InventorySystem::set_max_slots);
    ClassDB::bind_method(D_METHOD("get_max_slots"), &InventorySystem::get_max_slots);
	ClassDB::bind_method(D_METHOD("set_all_items", "items"), &InventorySystem::set_all_items);
}

bool InventorySystem::add_item(const Dictionary &item) {
    if (!item.has("id") || !item.has("name")) return false;
    if (items.size() >= max_slots) return false;
    String id = item["id"];
    for (int i = 0; i < items.size(); i++) {
        Dictionary existing = items[i];
        if (existing["id"] == id) {
            int qty = existing.get("quantity", 1);
            existing["quantity"] = qty + 1;
            items[i] = existing;
            return true;
        }
    }
    Dictionary new_item = item.duplicate();
    if (!new_item.has("quantity")) new_item["quantity"] = 1;
    items.append(new_item);
    return true;
}

bool InventorySystem::remove_item(const String &item_id) {
    for (int i = 0; i < items.size(); i++) {
        Dictionary item = items[i];
        if (item["id"] == item_id) { items.remove_at(i); return true; }
    }
    return false;
}

bool InventorySystem::has_item(const String &item_id) const {
    for (int i = 0; i < items.size(); i++) {
        Dictionary item = items[i];
        if (item["id"] == item_id) return true;
    }
    return false;
}

Dictionary InventorySystem::get_item(const String &item_id) const {
    for (int i = 0; i < items.size(); i++) {
        Dictionary item = items[i];
        if (item["id"] == item_id) return item;
    }
    return Dictionary();
}

Array InventorySystem::get_all_items() const { return items; }
void InventorySystem::clear() { items.clear(); }
int InventorySystem::get_item_count() const { return items.size(); }
void InventorySystem::set_max_slots(int slots) { max_slots = slots; }
int InventorySystem::get_max_slots() const { return max_slots; }
void InventorySystem::set_all_items(const Array &p_items) {
	items = p_items.duplicate(true);
}

} // namespace godot
