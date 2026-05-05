#pragma once
#include <godot_cpp/core/class_db.hpp>

extern "C" {
GDExtensionBool GDE_EXPORT initialize_inventory_system_module(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization);
}
