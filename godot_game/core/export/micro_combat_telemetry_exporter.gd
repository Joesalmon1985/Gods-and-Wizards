class_name MicroCombatTelemetryExporter
extends RefCounted

const RULES_VERSION := "run_g_v2"


static func run_episode(
	game_seed: int,
	max_steps: int,
	loadout_a_id: String = "hero_patrol",
	loadout_b_id: String = "demon_breach"
) -> Array:
	var env := MicroCombatTrainingEnv.new()
	env.reset(game_seed, loadout_a_id, loadout_b_id)
	var rows: Array = []
	var step_index := 0
	var episode_id := "micro_ep_%d" % game_seed
	var encounter_id := "enc_%s_vs_%s_%d" % [loadout_a_id, loadout_b_id, game_seed]

	while not env.is_done() and step_index < max_steps:
		var pre_obs := env.session.observe()
		pre_obs["legal_spell_count"] = env.get_legal_spell_ids().size()
		var legal := env.get_legal_spell_ids()
		var mask := env.build_legal_mask()
		var result := env.step_policy()
		var post_obs := env.session.observe()
		post_obs["legal_spell_count"] = env.get_legal_spell_ids().size()
		var actor_id: String = str(pre_obs.get("active_combatant_id", ""))
		var components := MicroCombatTrainingReward.compute_components(
			actor_id,
			result.get("events", []),
			env.session
		)
		rows.append(build_step_row(
			game_seed,
			step_index,
			episode_id,
			encounter_id,
			loadout_a_id,
			loadout_b_id,
			pre_obs,
			post_obs,
			legal,
			mask,
			str(result.get("selected_spell_id", "")),
			MicroCombatTrainingReward.total_from_components(components),
			components,
			bool(result.get("done", false)),
			str(env.session.winner_id if bool(result.get("done", false)) else pre_obs.get("winner_id", "")),
			result.get("events", [])
		))
		step_index += 1

	return rows


static func build_step_row(
	game_seed: int,
	step_index: int,
	episode_id: String,
	encounter_id: String,
	loadout_a_id: String,
	loadout_b_id: String,
	pre_observation: Dictionary,
	post_observation: Dictionary,
	legal_spell_ids: Array[String],
	legal_mask: Array[int],
	selected_action: String,
	reward: float,
	reward_components: Dictionary,
	terminal: bool,
	winner_id: String,
	events: Array
) -> Dictionary:
	return {
		"telemetry_schema_version": MicroCombatTelemetrySchema.SCHEMA_VERSION,
		"episode_id": episode_id,
		"encounter_id": encounter_id,
		"combat_step_index": str(step_index),
		"seed": str(game_seed),
		"step_index": str(step_index),
		"spell_catalog_version": MicroCombatTelemetrySchema.SPELL_CATALOG_VERSION,
		"loadout_a_id": loadout_a_id,
		"loadout_b_id": loadout_b_id,
		"sim_time": str(pre_observation.get("sim_time", 0.0)),
		"active_combatant_id": str(pre_observation.get("active_combatant_id", "")),
		"combatant_id": str(pre_observation.get("combatant_id", "")),
		"actor_id": str(pre_observation.get("active_combatant_id", "")),
		"health": str(pre_observation.get("health", 0.0)),
		"mana": str(pre_observation.get("mana", 0.0)),
		"opponent_id": str(pre_observation.get("opponent_id", "")),
		"opponent_health": str(pre_observation.get("opponent_health", 0.0)),
		"opponent_mana": str(pre_observation.get("opponent_mana", 0.0)),
		"loadout_spell_ids_json": JSON.stringify(pre_observation.get("loadout_spell_ids", [])),
		"legal_spell_ids_json": JSON.stringify(legal_spell_ids),
		"legal_mask_json": JSON.stringify(legal_mask),
		"selected_action": selected_action,
		"pre_observation_json": JSON.stringify(pre_observation),
		"post_observation_json": JSON.stringify(post_observation),
		"reward": str(reward),
		"reward_components_json": JSON.stringify(reward_components),
		"terminal": str(terminal).to_lower(),
		"winner_id": winner_id,
		"timeline_events_json": JSON.stringify(events),
	}


static func render_csv(rows: Array) -> String:
	var lines: PackedStringArray = []
	lines.append(",".join(MicroCombatTelemetrySchema.STEP_COLUMNS))
	for row in rows:
		lines.append(_row_to_csv(row, MicroCombatTelemetrySchema.STEP_COLUMNS))
	return "\n".join(lines) + "\n"


static func write_episode(
	game_seed: int,
	max_steps: int,
	output_path: String,
	loadout_a_id: String = "hero_patrol",
	loadout_b_id: String = "demon_breach"
) -> String:
	var rows := run_episode(game_seed, max_steps, loadout_a_id, loadout_b_id)
	var csv := render_csv(rows)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open micro combat telemetry path: %s" % output_path)
		return ""
	file.store_string(csv)
	file.close()
	return ProjectSettings.globalize_path(output_path)


static func default_output_path(game_seed: int) -> String:
	return "user://micro_combat_seed_%d.csv" % game_seed


static func _row_to_csv(row: Dictionary, columns: Array[String]) -> String:
	var values: PackedStringArray = []
	for column in columns:
		values.append(_escape_csv_field(str(row.get(column, ""))))
	return ",".join(values)


static func _escape_csv_field(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1 and value.find("\n") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
