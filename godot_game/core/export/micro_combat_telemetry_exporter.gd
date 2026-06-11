class_name MicroCombatTelemetryExporter
extends RefCounted


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

	while not env.is_done() and step_index < max_steps:
		var obs := env.session.observe()
		var legal := env.get_legal_spell_ids()
		var mask := env.build_legal_mask()
		var result := env.step_policy()
		rows.append(build_step_row(
			game_seed,
			step_index,
			obs,
			legal,
			mask,
			str(result.get("selected_spell_id", "")),
			float(result.get("reward", 0.0)),
			bool(result.get("done", false)),
			_summarize_events(result.get("events", []))
		))
		step_index += 1

	return rows


static func build_step_row(
	game_seed: int,
	step_index: int,
	observation: Dictionary,
	legal_spell_ids: Array[String],
	legal_mask: Array[int],
	selected_spell_id: String,
	reward: float,
	terminal: bool,
	timeline_summary: String
) -> Dictionary:
	return {
		"telemetry_schema_version": MicroCombatTelemetrySchema.SCHEMA_VERSION,
		"seed": str(game_seed),
		"step_index": str(step_index),
		"sim_time": str(observation.get("sim_time", 0.0)),
		"active_combatant_id": str(observation.get("active_combatant_id", "")),
		"combatant_id": str(observation.get("combatant_id", "")),
		"health": str(observation.get("health", 0.0)),
		"mana": str(observation.get("mana", 0.0)),
		"opponent_id": str(observation.get("opponent_id", "")),
		"opponent_health": str(observation.get("opponent_health", 0.0)),
		"opponent_mana": str(observation.get("opponent_mana", 0.0)),
		"loadout_spell_ids_json": JSON.stringify(observation.get("loadout_spell_ids", [])),
		"legal_spell_ids_json": JSON.stringify(legal_spell_ids),
		"legal_mask_json": JSON.stringify(legal_mask),
		"selected_spell_id": selected_spell_id,
		"reward": str(reward),
		"terminal": str(terminal).to_lower(),
		"winner_id": str(observation.get("winner_id", "")),
		"timeline_event_summary": timeline_summary,
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


static func _summarize_events(events: Array) -> String:
	var parts: PackedStringArray = []
	for event in events:
		parts.append("%s:%s" % [str(event.get("type", "")), JSON.stringify(event)])
	return "; ".join(parts)


static func _row_to_csv(row: Dictionary, columns: Array[String]) -> String:
	var values: PackedStringArray = []
	for column in columns:
		values.append(_escape_csv_field(str(row.get(column, ""))))
	return ",".join(values)


static func _escape_csv_field(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1 and value.find("\n") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
