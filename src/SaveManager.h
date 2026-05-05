//
// Created by Alex on 4/19/2026.
//

#ifndef GODOT_CPP_TEMPLATE_SAVEMANAGER_H
#define GODOT_CPP_TEMPLATE_SAVEMANAGER_H

#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

  class SaveManager : public Node {

    GDCLASS(SaveManager, Node)


    private:
      Dictionary game_data;
      String save_path = "user://savegame.json";

    protected:
      static void _bind_methods();

    public:
      SaveManager();
      ~SaveManager();

      void save_game();
      void load_game();
      void update_inventory(Array p_items);
  	  void set_game_data(const Dictionary p_data);
  	  Dictionary get_game_data() const;

  };

}

#endif //GODOT_CPP_TEMPLATE_SAVEMANAGER_H
