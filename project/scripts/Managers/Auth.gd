extends AuthManager

func _ready() -> void:
	var env_vars = _load_env("res://.env")
	var api_key = env_vars.get("FIREBASE_API_KEY", "")
	var project_id = env_vars.get("FIREBASE_PROJECT_ID", "")

	if api_key == "" or project_id == "":
		push_warning("[Auth] Firebase credentials not set in .env. Login will not work.")
	else:
		initialize(api_key, project_id)
		print("[Auth] Initialized.")

	login_finished.connect(_on_login_finished)
	register_finished.connect(_on_register_finished)

func _on_login_finished(success: bool, _message: String) -> void:
	if success:
		var nick = get_logged_in_nickname()
		Analytics.set_user_nickname(nick)
		if not is_local_mode():
			Analytics.start_session(nick)
		GameSave.set_save_nickname(nick)
		print("[Auth] Analytics and Save synced with user: ", nick)

func _on_register_finished(success: bool, _message: String) -> void:
	if success:
		var nick = get_logged_in_nickname()
		Analytics.set_user_nickname(nick)
		if not is_local_mode():
			Analytics.start_session(nick)
		GameSave.set_save_nickname(nick)
		print("[Auth] Analytics and Save synced with new user: ", nick)

func _load_env(path: String) -> Dictionary:
	var env = {}
	if not FileAccess.file_exists(path):
		return env

	var file = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue

		var parts = line.split("=", true, 1)
		if parts.size() == 2:
			var key = parts[0].strip_edges()
			var value = parts[1].strip_edges()
			if (value.begins_with("\"") and value.ends_with("\"")) or (value.begins_with("'") and value.ends_with("'")):
				value = value.substr(1, value.length() - 2)
			env[key] = value
	return env
