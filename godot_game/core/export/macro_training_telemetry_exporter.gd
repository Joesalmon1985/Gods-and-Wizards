class_name MacroTrainingTelemetryExporter
extends RefCounted

const RULES_VERSION := "run_e_v2"


static func run_episode(
	game_seed: int,
	max_steps: int,
	policy: String = BotTurnResolver.POLICY_HEURISTIC
) -> Array:
	var env := MacroTrainingEnv.new()
	env.reset(game_seed, policy)
	var rows: Array = []
	var step_index := 0

	while not env.is_game_over() and step_index < max_steps:
		var player_id := env.session.get_active_player_id()
		var view := env.get_legal_action_view(player_id)
		var action := env.choose_policy_action()
		var obs := env.get_observation(player_id)
		var result := env.step(action)
		var reward_map: Dictionary = result.get("rewards", {})
		var reward := float(reward_map.get(player_id, 0.0))
		rows.append(build_step_row(
			game_seed,
			step_index,
			player_id,
			obs,
			view,
			action,
			reward,
			bool(result.get("done", false)),
			_summarize_events(result.get("events", []), env.session.state),
			result.get("events", []),
			"ep_%d" % game_seed
		))
		step_index += 1

	return rows


static func build_step_row(
	game_seed: int,
	step_index: int,
	player_id: int,
	observation: Dictionary,
	view: LegalActionView,
	action: GameAction,
	reward: float,
	terminal: bool,
	event_summaries: String,
	structured_events: Array = [],
	episode_id: String = ""
) -> Dictionary:
	var legal_ids: Array = []
	var legal_mask_bits: Array = []
	for i in range(view.action_ids.size()):
		legal_ids.append(view.action_ids[i])
		legal_mask_bits.append(1 if view.legal_mask[i] else 0)

	return {
		"telemetry_schema_version": MacroTrainingTelemetrySchema.SCHEMA_VERSION,
		"seed": str(game_seed),
		"step_index": str(step_index),
		"player_id": str(player_id),
		"round_number": str(observation.get("round_number", 0)),
		"active_player_id": str(observation.get("active_player_id", player_id)),
		"policy_name": str(observation.get("policy_name", "")),
		"victory_points": str(observation.get("victory_points", 0)),
		"resources_json": JSON.stringify(observation.get("resources", {})),
		"city_count": str(observation.get("city_count", 0)),
		"road_count": str(observation.get("road_count", 0)),
		"breach_count": str(observation.get("breach_count", 0)),
		"total_demons": str(observation.get("total_demons", 0)),
		"game_finished": str(observation.get("game_finished", false)).to_lower(),
		"winner_id": str(observation.get("winner_id", -1)),
		"legal_action_ids_json": JSON.stringify(legal_ids),
		"legal_mask_json": JSON.stringify(legal_mask_bits),
		"selected_action_id": str(action.action_id),
		"selected_action_kind": ActionKind.to_key(action.kind),
		"reward": str(reward),
		"terminal": str(terminal).to_lower(),
		"event_summaries": event_summaries,
		"phase": str(observation.get("phase", "")),
		"episode_id": episode_id,
		"rules_version": RULES_VERSION,
		"draft_age": str(observation.get("draft_age", 1)),
		"infection_rate": str(observation.get("infection_rate", 0)),
		"development_hand_json": str(observation.get("development_hand_json", "[]")),
		"draft_pack_size": str(observation.get("draft_pack_size", 0)),
		"waiting_for_draft": str(observation.get("waiting_for_draft", false)).to_lower(),
		"action_params_json": _action_params_json(action),
		"structured_events_json": JSON.stringify(_structured_events(structured_events)),
	}


static func render_csv(rows: Array) -> String:
	var lines: PackedStringArray = []
	lines.append(",".join(MacroTrainingTelemetrySchema.STEP_COLUMNS))
	for row in rows:
		lines.append(_row_to_csv(row, MacroTrainingTelemetrySchema.STEP_COLUMNS))
	return "\n".join(lines) + "\n"


static func write_episode(
	game_seed: int,
	max_steps: int,
	output_path: String,
	policy: String = BotTurnResolver.POLICY_HEURISTIC
) -> String:
	var rows := run_episode(game_seed, max_steps, policy)
	var csv := render_csv(rows)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open macro training telemetry path: %s" % output_path)
		return ""
	file.store_string(csv)
	file.close()
	return ProjectSettings.globalize_path(output_path)


static func default_output_path(game_seed: int) -> String:
	return "user://macro_training_seed_%d.csv" % game_seed


static func _summarize_events(events: Array, state: GameState) -> String:
	var lines := EventSummary.summarize_events(events, state)
	return "; ".join(lines)


static func _row_to_csv(row: Dictionary, columns: Array[String]) -> String:
	var values: PackedStringArray = []
	for column in columns:
		values.append(_escape_csv_field(str(row.get(column, ""))))
	return ",".join(values)


static func _action_params_json(action: GameAction) -> String:
	if action == null:
		return "{}"
	return JSON.stringify({
		"kind": ActionKind.to_key(action.kind),
		"draft_player_id": action.draft_player_id,
		"development_id": action.development_id,
		"hero_id": action.hero_id,
	})


static func _structured_events(events: Array) -> Array:
	var rows: Array = []
	for event in events:
		if event == null:
			continue
		if event.has_method("to_dict"):
			rows.append(event.to_dict())
	return rows


static func _escape_csv_field(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1 and value.find("\n") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
