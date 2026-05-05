#ifndef ANALYTICS_MANAGER_H
#define ANALYTICS_MANAGER_H

#include <godot_cpp/classes/http_request.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class AnalyticsManager : public Node {
	GDCLASS(AnalyticsManager, Node)

private:
	String api_key;
	String project_id;
	String session_id;

	Array event_queue; // queued events waiting to be flushed
	Dictionary start_times; // map of puzzle_id -> start_timestamp
	bool is_flushing; // prevents overlapping flush calls
	int flush_threshold; // auto-flush when queue hits this size
	HTTPRequest *http_node; // child node for making requests

	String _build_firestore_url();
	String _event_to_firestore_json(const Dictionary &event);
	String _batch_to_json(const Array &events);
	void _on_request_completed(int result, int code, const Array &headers, const PackedByteArray &body);

protected:
	static void _bind_methods();

public:
	AnalyticsManager();
	~AnalyticsManager();

	void _ready() override;

	// called from GDScript
	void initialize(const String &p_api_key, const String &p_project_id, const String &p_session_id);
	void log_event(const String &event_name, const Dictionary &data);
	void puzzle_started(const String &puzzle_id, const String &level_id);
	void puzzle_solved(const String &puzzle_id, const String &level_id);
	void mistake_made(const String &puzzle_id, const String &level_id, const String &reason);
	void flush();

	void set_flush_threshold(int threshold);
	int get_flush_threshold() const;
	int get_queue_size() const;
};

} // namespace godot

#endif // ANALYTICS_MANAGER_H
