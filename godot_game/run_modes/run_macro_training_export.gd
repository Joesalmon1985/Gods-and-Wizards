# Headless macro training telemetry export — step-level observations and actions.
# Example:
#   godot --headless --path "<godot_game>" -s res://run_modes/run_macro_training_export.gd -- --seed 42 --episodes 10 --output logs/macro.csv

extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var episodes: int = parsed["episodes"]
	var base_seed: int = parsed["seed"]
	var max_steps: int = parsed["max_steps"]
	var policy: String = parsed["policy"]
	var output_path: String = parsed["output"]

	var all_rows: Array = []
	for episode_index in range(episodes):
		var episode_seed := base_seed + episode_index
		var rows := MacroTrainingTelemetryExporter.run_episode(
			episode_seed,
			max_steps,
			policy
		)
		for row in rows:
			all_rows.append(row)

	var csv := MacroTrainingTelemetryExporter.render_csv(all_rows)
	if not ExportPathResolver.write_text(output_path, csv):
		push_error("Failed to write macro training telemetry CSV")
		quit(1)
		return

	print("Macro training telemetry CSV written to: %s (%d rows)" % [
		ExportPathResolver.globalized(output_path),
		all_rows.size(),
	])
	quit(0)


func _parse_args() -> Dictionary:
	var game_seed := 42
	var episodes := 1
	var max_steps := 50
	var policy := BotTurnResolver.POLICY_HEURISTIC
	var output_path := ""
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg == "--seed" and index + 1 < args.size():
			game_seed = int(args[index + 1])
			index += 2
			continue
		if arg == "--episodes" and index + 1 < args.size():
			episodes = int(args[index + 1])
			index += 2
			continue
		if arg == "--max-steps" and index + 1 < args.size():
			max_steps = int(args[index + 1])
			index += 2
			continue
		if arg == "--policy" and index + 1 < args.size():
			policy = args[index + 1]
			index += 2
			continue
		if arg == "--output" and index + 1 < args.size():
			output_path = args[index + 1]
			index += 2
			continue
		index += 1
	if output_path == "":
		output_path = MacroTrainingTelemetryExporter.default_output_path(game_seed)
	return {
		"seed": game_seed,
		"episodes": episodes,
		"max_steps": max_steps,
		"policy": policy,
		"output": output_path,
	}
