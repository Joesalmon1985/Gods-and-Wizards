class_name DebugRunExporter
extends RefCounted

const CSV_COLUMNS: Array[String] = [
	"sequence_id",
	"visual_step_index",
	"round_number",
	"active_player_id",
	"player_id",
	"event_type",
	"action_id",
	"action_kind",
	"resource",
	"amount",
	"victory_points",
	"hex",
	"vertex",
	"produced",
	"production_chance",
	"roll",
	"details_json",
]


static func build_rows(result: Dictionary) -> Array:
	var rows: Array = []
	var baseline: Dictionary = result.get("replay_baseline", {})
	var log: EventLog = result.get("event_log")
	var state: GameState = result.get("state")
	if baseline.is_empty() or log == null or state == null:
		return rows

	for entry in log.entries:
		var sequence_id: int = entry.get("sequence_id", -1)
		var visual_step := sequence_id + 1
		var replayed := EventLogReplay.build_view_at_step(baseline, log, visual_step)
		var payload: Dictionary = entry.get("payload", {})
		var entry_type: String = entry.get("type", "")
		var row := _empty_row()

		row["sequence_id"] = str(sequence_id)
		row["visual_step_index"] = str(visual_step)
		row["round_number"] = str(replayed.get("round_number", ""))
		row["active_player_id"] = str(replayed.get("active_player_index", ""))
		row["event_type"] = entry_type
		row["details_json"] = JSON.stringify(payload)

		_populate_event_fields(row, entry_type, payload, state, replayed)
		rows.append(row)

	return rows


static func render_csv(rows: Array) -> String:
	var lines: PackedStringArray = []
	lines.append(_join_row(_header_row()))
	for row in rows:
		var values: Array[String] = []
		for column in CSV_COLUMNS:
			values.append(str(row.get(column, "")))
		lines.append(_join_row(values))
	return "\n".join(lines) + "\n"


static func default_user_path(seed: int, rounds: int) -> String:
	return "user://debug_run_seed_%d_rounds_%d.csv" % [seed, rounds]


static func write_to_user_path(result: Dictionary, seed: int, rounds: int) -> String:
	var user_path := default_user_path(seed, rounds)
	var csv := render_csv(build_rows(result))
	var file := FileAccess.open(user_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open export path: %s" % user_path)
		return ""
	file.store_string(csv)
	file.close()
	return ProjectSettings.globalize_path(user_path)


static func _header_row() -> Array[String]:
	return CSV_COLUMNS.duplicate()


static func _empty_row() -> Dictionary:
	var row := {}
	for column in CSV_COLUMNS:
		row[column] = ""
	return row


static func _populate_event_fields(
	row: Dictionary,
	entry_type: String,
	payload: Dictionary,
	state: GameState,
	replayed: Dictionary
) -> void:
	match entry_type:
		"action_mask_recorded":
			row["player_id"] = str(payload.get("player_id", ""))
		"city_built":
			row["player_id"] = str(payload.get("player_id", ""))
			row["vertex"] = _vertex_key(payload.get("vertex", {}))
			var action := _find_build_action(state, payload.get("vertex", {}))
			if action != null:
				row["action_id"] = str(action.action_id)
				row["action_kind"] = ActionKind.to_key(action.kind)
			_set_player_victory_points(row, replayed, payload.get("player_id", -1))
		"turn_ended":
			row["player_id"] = str(payload.get("player_id", ""))
			row["action_id"] = "0"
			row["action_kind"] = ActionKind.to_key(ActionKind.Kind.END_TURN)
			_set_player_victory_points(row, replayed, payload.get("player_id", -1))
		"resource_gained":
			row["player_id"] = str(payload.get("player_id", ""))
			row["resource"] = str(payload.get("resource", ""))
			row["amount"] = str(payload.get("amount", ""))
			row["hex"] = _hex_key(payload.get("source_hex", payload.get("hex", {})))
			_set_player_victory_points(row, replayed, payload.get("player_id", -1))
		"production_check":
			row["resource"] = str(payload.get("resource", ""))
			row["hex"] = _hex_key(payload.get("hex", {}))
			row["produced"] = str(payload.get("produced", ""))
			row["production_chance"] = str(payload.get("production_chance", ""))
			row["roll"] = str(payload.get("roll", ""))
		"victory_points_changed":
			row["player_id"] = str(payload.get("player_id", ""))
			row["victory_points"] = str(payload.get("total", ""))
		"round_started", "game_over":
			if entry_type == "game_over":
				row["player_id"] = str(payload.get("winner_id", ""))
		_:
			pass


static func _set_player_victory_points(row: Dictionary, replayed: Dictionary, player_id: int) -> void:
	if player_id < 0:
		return
	for player in replayed.get("players", []):
		if player.get("id", -1) == player_id:
			row["victory_points"] = str(player.get("victory_points", ""))
			return


static func _find_build_action(state: GameState, vertex_data: Dictionary) -> GameAction:
	if vertex_data.is_empty() or state.action_space == null:
		return null
	var vertex := BoardNode.from_dict(vertex_data)
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.BUILD_CITY:
			continue
		if action.vertex != null and action.vertex.equals(vertex):
			return action
	return null


static func _hex_key(hex_data) -> String:
	if hex_data is Dictionary:
		return "%d,%d" % [hex_data.get("q", 0), hex_data.get("r", 0)]
	return ""


static func _vertex_key(vertex_data) -> String:
	if vertex_data is Dictionary:
		var keys: Array = vertex_data.get("geometric_hexes", [])
		if keys.is_empty():
			return ""
		return str(keys[0])
	return ""


static func _join_row(values: Array[String]) -> String:
	var escaped: PackedStringArray = []
	for value in values:
		escaped.append(_escape_csv_field(value))
	return ",".join(escaped)


static func _escape_csv_field(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1 and value.find("\n") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
