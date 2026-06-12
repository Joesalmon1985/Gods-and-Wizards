class_name MacroTrainingTelemetryExporter
extends RefCounted

const RULES_VERSION := "run_g_v2"
const DEFAULT_SCENARIO := "four_player_bot"


static func run_episode(
	game_seed: int,
	max_steps: int,
	policy: String = BotTurnResolver.POLICY_HEURISTIC,
	scenario_name: String = DEFAULT_SCENARIO
) -> Array:
	var env := MacroTrainingEnv.new()
	env.reset(game_seed, policy)
	var rows: Array = []
	var step_index := 0
	var episode_id := "macro_ep_%d" % game_seed

	while not env.is_game_over() and step_index < max_steps:
		var player_id := env.session.get_active_player_id()
		var view := env.get_legal_action_view(player_id)
		var action := env.choose_policy_action()
		var pre_obs := env.get_observation(player_id)
		var vp_before := int(pre_obs.get("victory_points", 0))
		var breach_before := int(pre_obs.get("breach_count", 0))
		var result := env.step(action)
		var post_obs := env.get_observation(player_id)
		var reward_map: Dictionary = result.get("rewards", {})
		var reward := float(reward_map.get(player_id, 0.0))
		var components := MacroTrainingReward.compute_components(
			result.get("events", []),
			env.session.state,
			player_id,
			vp_before,
			breach_before
		)
		rows.append(build_step_row(
			game_seed,
			step_index,
			episode_id,
			scenario_name,
			player_id,
			pre_obs,
			post_obs,
			view,
			action,
			reward,
			components,
			bool(result.get("done", false)),
			_summarize_events(result.get("events", []), env.session.state),
			result.get("events", [])
		))
		step_index += 1

	return rows


static func build_step_row(
	game_seed: int,
	step_index: int,
	episode_id: String,
	scenario_name: String,
	player_id: int,
	pre_observation: Dictionary,
	post_observation: Dictionary,
	view: LegalActionView,
	action: GameAction,
	reward: float,
	reward_components: Dictionary,
	terminal: bool,
	event_summaries: String,
	structured_events: Array = []
) -> Dictionary:
	var legal_ids: Array = []
	var legal_mask_bits: Array = []
	for i in range(view.action_ids.size()):
		legal_ids.append(view.action_ids[i])
		legal_mask_bits.append(1 if view.legal_mask[i] else 0)

	return {
		"telemetry_schema_version": MacroTrainingTelemetrySchema.SCHEMA_VERSION,
		"episode_id": episode_id,
		"macro_step_index": str(step_index),
		"seed": str(game_seed),
		"step_index": str(step_index),
		"player_id": str(player_id),
		"actor_player_id": str(player_id),
		"round_number": str(pre_observation.get("round_number", 0)),
		"active_player_id": str(pre_observation.get("active_player_id", player_id)),
		"policy_name": str(pre_observation.get("policy_name", "")),
		"scenario_name": scenario_name,
		"rules_version": RULES_VERSION,
		"action_space_layout_key": str(pre_observation.get("action_space_layout_key", "unknown")),
		"phase": str(pre_observation.get("phase", "")),
		"victory_points": str(pre_observation.get("victory_points", 0)),
		"resources_json": JSON.stringify(pre_observation.get("resources", {})),
		"city_count": str(pre_observation.get("city_count", 0)),
		"road_count": str(pre_observation.get("road_count", 0)),
		"breach_count": str(pre_observation.get("breach_count", 0)),
		"total_demons": str(pre_observation.get("total_demons", 0)),
		"game_finished": str(pre_observation.get("game_finished", false)).to_lower(),
		"winner_id": str(post_observation.get("winner_id", pre_observation.get("winner_id", -1))),
		"legal_action_ids_json": JSON.stringify(legal_ids),
		"legal_mask_json": JSON.stringify(legal_mask_bits),
		"selected_action_id": str(action.action_id),
		"selected_action_kind": ActionKind.to_key(action.kind),
		"action_params_json": _action_params_json(action),
		"pre_observation_json": JSON.stringify(_observation_for_json(pre_observation)),
		"post_observation_json": JSON.stringify(_observation_for_json(post_observation)),
		"reward": str(reward),
		"reward_components_json": JSON.stringify(reward_components),
		"terminal": str(terminal).to_lower(),
		"event_summaries": event_summaries,
		"structured_events_json": JSON.stringify(_structured_events(structured_events)),
		"draft_age": str(pre_observation.get("draft_age", 1)),
		"infection_rate": str(pre_observation.get("infection_rate", 0)),
		"development_hand_json": str(pre_observation.get("development_hand_json", "[]")),
		"draft_pack_size": str(pre_observation.get("draft_pack_size", 0)),
		"waiting_for_draft": str(pre_observation.get("waiting_for_draft", false)).to_lower(),
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


static func _observation_for_json(observation: Dictionary) -> Dictionary:
	var copy := observation.duplicate(true)
	copy.erase("_state_ref")
	return copy


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
