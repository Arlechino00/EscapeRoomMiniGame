#include "register_types.h"
#include "inventory_system.h"
#include "SaveManager.h"
#include "analytics_manager.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>


using namespace godot;

void initialize_inventory_system(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE)
		return;

	ClassDB::register_class<InventorySystem>();
	ClassDB::register_class<SaveManager>();
	ClassDB::register_class<AnalyticsManager>();
}

void uninitialize_inventory_system(ModuleInitializationLevel p_level) {}

extern "C" {
GDExtensionBool GDE_EXPORT initialize_inventory_system_module(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
    godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
    init_obj.register_initializer(initialize_inventory_system);
    init_obj.register_terminator(uninitialize_inventory_system);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init_obj.init();
}
}
