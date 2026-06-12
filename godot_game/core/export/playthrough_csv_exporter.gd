class_name PlaythroughCsvExporter
extends RefCounted

const CSV_COLUMNS: Array[String] = [
	"seed",
	"turn_number",
	"round_number",
	"active_player_id",
	"active_player_name",
	"action_type",
	"action_details",
	"event_type",
	"event_details",
	"event_summary",
	"player_resources",
	"city_count",
	"road_count",
	"demon_breach_info",
	"score",
]


static func build_rows(session: BotGameSession) -> Array:
	var rows: Array = []
	var result := session.to_result()
	var baseline: Dictionary = result.get("replay_baseline", {})
	var log: EventLog = result.get("event_log")
	var state: GameState = result.get("state")
	if baseline.is_empty() or log == null or state == null:
		return rows

	var turn_counter := 0
	for entry in log.entries:
		var sequence_id: int = entry.get("sequence_id", -1)
		var visual_step := sequence_id + 1
		var replayed := EventLogReplay.build_view_at_step(baseline, log, visual_step)
		var payload: Dictionary = entry.get("payload", {})
		var entry_type: String = entry.get("type", "")

		if entry_type == "turn_ended":
			turn_counter += 1

		var row := _empty_row()
		row["seed"] = str(session.seed)
		row["turn_number"] = str(turn_counter)
		row["round_number"] = str(replayed.get("round_number", state.round_number))
		row["active_player_id"] = str(replayed.get("active_player_index", ""))
		row["active_player_name"] = _active_player_name(replayed)
		row["event_type"] = entry_type
		row["event_details"] = JSON.stringify(payload)
		row["event_summary"] = EventSummary.summarize_event_entry(entry_type, payload, state)
		row["city_count"] = str(replayed.get("cities", []).size())
		row["road_count"] = str(replayed.get("roads", []).size())
		row["demon_breach_info"] = _demon_breach_info(replayed)
		row["score"] = _scores_summary(replayed)
		row["player_resources"] = _resources_summary(replayed)

		_populate_action_fields(row, entry_type, payload, state)
		rows.append(row)

	return rows


static func render_csv(rows: Array) -> String:
	var lines: PackedStringArray = []
	lines.append(",".join(CSV_COLUMNS))
	for row in rows:
		var values: PackedStringArray = []
		for column in CSV_COLUMNS:
			values.append(_escape_csv_field(str(row.get(column, ""))))
		lines.append(",".join(values))
	return "\n".join(lines) + "\n"


static func default_output_path(game_seed: int) -> String:
	return "user://playthrough_seed_%d.csv" % game_seed


static func write_session(session: BotGameSession, game_seed: int, output_path: String = "") -> String:
	var path := output_path if output_path != "" else default_output_path(game_seed)
	var csv := render_csv(build_rows(session))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open CSV path: %s" % path)
		return ""
	file.store_string(csv)
	file.close()
	return ProjectSettings.globalize_path(path)


static func _populate_action_fields(
	row: Dictionary,
	entry_type: String,
	payload: Dictionary,
	state: GameState
) -> void:
	match entry_type:
		"action_mask_recorded":
			row["action_type"] = "action_mask"
			row["action_details"] = JSON.stringify(payload.get("legal_mask", []))
		"turn_ended":
			row["action_type"] = ActionKind.to_key(ActionKind.Kind.END_TURN)
			row["action_details"] = "player_id=%s" % payload.get("player_id", "")
		"city_built":
			row["action_type"] = ActionKind.to_key(ActionKind.Kind.BUILD_CITY)
			row["action_details"] = _vertex_key(payload.get("vertex", {}))
		"road_built":
			row["action_type"] = ActionKind.to_key(ActionKind.Kind.BUILD_ROAD)
			row["action_details"] = JSON.stringify(payload.get("edge", {}))
		"hero_moved":
			row["action_type"] = ActionKind.to_key(ActionKind.Kind.MOVE_HERO)
			row["action_details"] = JSON.stringify(payload)
		"development_built":
			row["action_type"] = ActionKind.to_key(ActionKind.Kind.BUILD_DEVELOPMENT)
			row["action_details"] = JSON.stringify(payload)
		_:
			row["action_type"] = ""
			row["action_details"] = ""


static func _active_player_name(replayed: Dictionary) -> String:
	for player in replayed.get("players", []):
		if player.get("id", -1) == replayed.get("active_player_index", -1):
			return str(player.get("name", player.get("display_name", "")))
	return ""


static func _resources_summary(replayed: Dictionary) -> String:
	var parts: Array[String] = []
	for player in replayed.get("players", []):
		parts.append("p%d:%s" % [player.get("id", -1), JSON.stringify(player.get("resources", {}))])
	return "|".join(parts)


static func _scores_summary(replayed: Dictionary) -> String:
	var parts: Array[String] = []
	for player in replayed.get("players", []):
		parts.append("p%d:%d" % [player.get("id", -1), player.get("victory_points", 0)])
	return "|".join(parts)


static func _demon_breach_info(replayed: Dictionary) -> String:
	return "breach=%d,demons=%d" % [
		int(replayed.get("breach_count", 0)),
		int(replayed.get("total_demons", 0)),
	]


static func _vertex_key(vertex_data) -> String:
	if vertex_data is Dictionary:
		var keys: Array = vertex_data.get("geometric_hexes", [])
		if keys.is_empty():
			return ""
		return "|".join(keys)
	return ""


static func _empty_row() -> Dictionary:
	var row := {}
	for column in CSV_COLUMNS:
		row[column] = ""
	return row


static func _escape_csv_field(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1 and value.find("\n") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
