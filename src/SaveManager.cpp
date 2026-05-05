//
// Created by Alex on 4/19/2026.
//

#include "SaveManager.h"
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void SaveManager:: _bind_methods() {

	ClassDB::bind_method(D_METHOD("save_game"), &SaveManager::save_game);
	ClassDB::bind_method(D_METHOD("load_game"), &SaveManager::load_game);
	ClassDB::bind_method(D_METHOD("update_inventory", "p_items"), &SaveManager::update_inventory);
	ClassDB::bind_method(D_METHOD("get_game_data"), &SaveManager::get_game_data);
	ClassDB::bind_method(D_METHOD("set_game_data"), &SaveManager::set_game_data);
	ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "game_data"), "set_game_data", "get_game_data");


}

SaveManager::SaveManager() {
	game_data["player_x"] = 0.0;
	game_data["player_y"] = 0.0;
	game_data["current_level"] = "";

	game_data["current_puzzle_id"] = "";
	game_data["puzzles"] = Dictionary();
	game_data["inventory"] = Array();
}

SaveManager::~SaveManager() {}

void SaveManager::save_game() {
	Ref<FileAccess> file = FileAccess::open(save_path, FileAccess::WRITE);

	if (file.is_valid()) {
		String json_string = JSON::stringify(game_data);
		file->store_line(json_string);
		UtilityFunctions::print("[C++] The games has been saved!");
	}
	else
		UtilityFunctions::print("[C++] The games has been not saved!");
}

void SaveManager::load_game() {
	if (!FileAccess::file_exists(save_path)) {
		UtilityFunctions::print("[C++] Nicio salvare gasita.");
		return;
	}

	Ref<FileAccess> file = FileAccess::open(save_path, FileAccess::READ);
	if (file.is_valid()) {
		String json_string = file->get_as_text();
		Ref<JSON> json;
		json.instantiate();
		Error error = json->parse(json_string);

		if (error == OK) {
			game_data = json->get_data();
			UtilityFunctions::print("[C++] The game has been loaded");
		}
		else
			UtilityFunctions::print("[C++] The JSON could not have been read");
	}
}

void SaveManager::update_inventory(Array p_items) {
	game_data["inventory"] = p_items;
	UtilityFunctions::print("[C++] Inventory has been updated");
}

void SaveManager::set_game_data(const Dictionary p_data) {
	game_data = p_data;
}

Dictionary SaveManager::get_game_data() const {
	return game_data;
}