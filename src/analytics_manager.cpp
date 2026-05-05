#include "analytics_manager.h"
#include <godot_cpp/classes/http_request.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

AnalyticsManager::AnalyticsManager() {
	is_flushing = false;
	flush_threshold = 10;
	http_node = nullptr;
}

AnalyticsManager::~AnalyticsManager() {}

void AnalyticsManager::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize", "api_key", "project_id", "session_id"),
			&AnalyticsManager::initialize);
	ClassDB::bind_method(D_METHOD("log_event", "event_name", "data"),
			&AnalyticsManager::log_event);
	ClassDB::bind_method(D_METHOD("puzzle_started", "puzzle_id", "level_id"),
			&AnalyticsManager::puzzle_started);
	ClassDB::bind_method(D_METHOD("puzzle_solved", "puzzle_id", "level_id"),
			&AnalyticsManager::puzzle_solved);
	ClassDB::bind_method(D_METHOD("mistake_made", "puzzle_id", "level_id", "reason"),
			&AnalyticsManager::mistake_made);
	ClassDB::bind_method(D_METHOD("flush"), &AnalyticsManager::flush);
	ClassDB::bind_method(D_METHOD("get_queue_size"), &AnalyticsManager::get_queue_size);
	ClassDB::bind_method(D_METHOD("set_flush_threshold", "threshold"),
			&AnalyticsManager::set_flush_threshold);
	ClassDB::bind_method(D_METHOD("get_flush_threshold"),
			&AnalyticsManager::get_flush_threshold);
	ClassDB::bind_method(D_METHOD("_on_request_completed", "result", "code", "headers", "body"),
			&AnalyticsManager::_on_request_completed);

	ADD_PROPERTY(PropertyInfo(Variant::INT, "flush_threshold"), "set_flush_threshold", "get_flush_threshold");
}

void AnalyticsManager::_ready() {
	// create a child HTTPRequest node to handle outgoing calls
	http_node = memnew(HTTPRequest);
	add_child(http_node);
	http_node->connect("request_completed",
			Callable(this, "_on_request_completed"));
}

void AnalyticsManager::initialize(const String &p_api_key,
		const String &p_project_id,
		const String &p_session_id) {
	api_key = p_api_key;
	project_id = p_project_id;
	session_id = p_session_id;
	UtilityFunctions::print("[Analytics] Initialized. Session: ", session_id);
}

void AnalyticsManager::log_event(const String &event_name, const Dictionary &data) {
	if (api_key.is_empty() || project_id.is_empty()) {
		UtilityFunctions::printerr("[Analytics] Not initialized — call initialize() first.");
		return;
	}

	// build the event dict
	Dictionary event;
	event["event"] = event_name;
	event["session"] = session_id;
	event["timestamp"] = Time::get_singleton()->get_unix_time_from_system();

	// merge caller-supplied data into the event
	Array keys = data.keys();
	for (int i = 0; i < keys.size(); i++) {
		event[keys[i]] = data[keys[i]];
	}

	event_queue.push_back(event);
	UtilityFunctions::print("[Analytics] Queued: ", event_name, " (queue=", event_queue.size(), ")");

	if (event_queue.size() >= flush_threshold) {
		flush();
	}
}

void AnalyticsManager::puzzle_started(const String &puzzle_id, const String &level_id) {
	double now = Time::get_singleton()->get_unix_time_from_system();
	start_times[puzzle_id] = now;

	Dictionary data;
	data["puzzle_id"] = puzzle_id;
	data["level_id"] = level_id;
	log_event("puzzle_started", data);
}

void AnalyticsManager::puzzle_solved(const String &puzzle_id, const String &level_id) {
	double now = Time::get_singleton()->get_unix_time_from_system();
	double duration = 0.0;
	
	if (start_times.has(puzzle_id)) {
		duration = now - double(start_times[puzzle_id]);
		start_times.erase(puzzle_id); // clear it
	}

	Dictionary data;
	data["puzzle_id"] = puzzle_id;
	data["level_id"] = level_id;
	data["time_spent_seconds"] = duration;
	log_event("puzzle_solved", data);
}

void AnalyticsManager::mistake_made(const String &puzzle_id, const String &level_id, const String &reason) {
	Dictionary data;
	data["puzzle_id"] = puzzle_id;
	data["level_id"] = level_id;
	data["reason"] = reason;
	log_event("mistake_made", data);
}

// --- Firestore REST helpers -------------------------------------------------

String AnalyticsManager::_build_firestore_url() {
	// POST to a new auto-ID document under sessions/{session_id}/events/
	return "https://firestore.googleapis.com/v1/projects/" + project_id +
			"/databases/(default)/documents/sessions/" + session_id +
			"/events?key=" + api_key;
}

// Converts a single Variant value to a Firestore value object string
static String variant_to_firestore(const Variant &v) {
	switch (v.get_type()) {
		case Variant::BOOL:
			return "{\"booleanValue\":" + String((bool(v) ? "true" : "false")) + "}";
		case Variant::INT:
			return "{\"integerValue\":\"" + String::num_int64(int64_t(v)) + "\"}";
		case Variant::FLOAT:
			return "{\"doubleValue\":" + String::num(double(v)) + "}";
		default:
			// treat everything else as a string
			return "{\"stringValue\":\"" + String(v) + "\"}";
	}
}

String AnalyticsManager::_event_to_firestore_json(const Dictionary &event) {
	String fields = "";
	Array keys = event.keys();
	for (int i = 0; i < keys.size(); i++) {
		if (i > 0)
			fields += ",";
		String key = String(keys[i]);
		fields += "\"" + key + "\":" + variant_to_firestore(event[keys[i]]);
	}
	return "{\"fields\":{" + fields + "}}";
}

// --- Flush -----------------------------------------------------------------

void AnalyticsManager::flush() {
	if (event_queue.is_empty()) return;

	// If http_node wasn't created in _ready (e.g. due to GDScript override), create it now
	if (!http_node) {
		UtilityFunctions::print("[Analytics] Creating HTTP node on-demand.");
		http_node = memnew(HTTPRequest);
		add_child(http_node);
		http_node->connect("request_completed", Callable(this, "_on_request_completed"));
	}

	if (is_flushing) {
		UtilityFunctions::print("[Analytics] Already flushing, waiting...");
		return;
	}

	if (api_key.is_empty() || project_id.is_empty()) {
		UtilityFunctions::printerr("[Analytics] Cannot flush: API Key or Project ID is empty.");
		return;
	}

	UtilityFunctions::print("[Analytics] Flushing ", event_queue.size(), " events...");
	Array to_send = event_queue.duplicate();
	event_queue.clear();

	// send each event as a separate POST (Firestore batch requires OAuth;
	// individual document POSTs work with just the API key)
	// We send the first one now; the rest go in _on_request_completed
	// to avoid parallel HTTP requests on the single HTTPRequest node.
	// Store remainder back so the callback can chain them.
	if (to_send.size() > 1) {
		for (int i = 1; i < to_send.size(); i++) {
			event_queue.push_front(to_send[i]); // re-queue tail
		}
	}

	Dictionary first_event = to_send[0];
	String url = _build_firestore_url();
	String body = _event_to_firestore_json(first_event);

	PackedStringArray headers;
	headers.push_back("Content-Type: application/json");

	is_flushing = true;
	Error err = http_node->request(url, headers, HTTPClient::METHOD_POST, body);
	if (err != OK) {
		UtilityFunctions::printerr("[Analytics] HTTP request failed to start: ", err);
		is_flushing = false;
	}
}

void AnalyticsManager::_on_request_completed(int result, int code,
		const Array &headers,
		const PackedByteArray &body) {
	is_flushing = false;

	if (code == 200 || code == 201) {
		UtilityFunctions::print("[Analytics] Event sent OK (HTTP ", code, ")");
	} else {
		UtilityFunctions::printerr("[Analytics] Send failed HTTP ", code);
	}

	// if there are more queued events, chain the next flush
	if (!event_queue.is_empty()) {
		flush();
	}
}

// --- Getters/setters -------------------------------------------------------

void AnalyticsManager::set_flush_threshold(int threshold) {
	flush_threshold = threshold;
}

int AnalyticsManager::get_flush_threshold() const {
	return flush_threshold;
}

int AnalyticsManager::get_queue_size() const {
	return event_queue.size();
}
