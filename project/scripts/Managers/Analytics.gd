extends AnalyticsManager

func _ready() -> void:
	var env_vars = _load_env("res://.env")
	var api_key = env_vars.get("FIREBASE_API_KEY", "")
	var project_id = env_vars.get("FIREBASE_PROJECT_ID", "")
	
	# Create a simple unique session ID based on time
	var session_id = "session_" + str(Time.get_unix_time_from_system()).replace(".", "_") + "_" + str(randi() % 1000)
	
	if api_key == "" or project_id == "" or api_key == "YOUR_API_KEY_HERE":
		push_warning("[Analytics] Firebase credentials not set or still default in .env. Analytics will not be sent.")
	else:
		initialize(api_key, project_id, session_id)
		set_flush_threshold(1) # Send every event immediately for testing
		print("[Analytics] Initialized session: ", session_id)

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
			# Remove quotes if present
			if (value.begins_with("\"") and value.ends_with("\"")) or (value.begins_with("'") and value.ends_with("'")):
				value = value.substr(1, value.length() - 2)
			env[key] = value
	return env
