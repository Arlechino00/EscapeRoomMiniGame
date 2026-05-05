#ifndef INVENTORY_SYSTEM_H
#define INVENTORY_SYSTEM_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class InventorySystem : public Node {
    GDCLASS(InventorySystem, Node);

protected:
    static void _bind_methods();

private:
    Array items;
    int max_slots = 20;

public:
    InventorySystem();
    bool add_item(const Dictionary &item);
    bool remove_item(const String &item_id);
    bool has_item(const String &item_id) const;
    Dictionary get_item(const String &item_id) const;
    Array get_all_items() const;
    void clear();
    int get_item_count() const;
    void set_max_slots(int slots);
    int get_max_slots() const;
    void set_all_items(const Array &p_items);
};

} // namespace godot

#endif // INVENTORY_SYSTEM_H
