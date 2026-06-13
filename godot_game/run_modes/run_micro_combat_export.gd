# Headless micro combat training telemetry export.
extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var episodes: int = parsed["episodes"]
	var base_seed: int = parsed["seed"]
	var max_steps: int = parsed["max_steps"]
	var loadout_a: String = parsed["loadout_a"]
	var loadout_b: String = parsed["loadout_b"]
	var output_path: String = parsed["output"]

	var all_rows: Array = []
	for episode_index in range(episodes):
		var episode_seed := base_seed + episode_index
		var rows := MicroCombatTelemetryExporter.run_episode(
			episode_seed,
			max_steps,
			loadout_a,
			loadout_b
		)
		for row in rows:
			all_rows.append(row)

	var csv := MicroCombatTelemetryExporter.render_csv(all_rows)
	if not ExportPathResolver.write_text(output_path, csv):
		push_error("Failed to write micro combat telemetry CSV")
		quit(1)
		return
	print("Micro combat telemetry CSV written: %s (%d rows)" % [
		ExportPathResolver.globalized(output_path),
		all_rows.size(),
	])
	quit(0)


func _parse_args() -> Dictionary:
	var game_seed := 200
	var episodes := 1
	var max_steps := 80
	var loadout_a := "hero_patrol"
	var loadout_b := "demon_breach"
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
		if arg == "--loadout-a" and index + 1 < args.size():
			loadout_a = args[index + 1]
			index += 2
			continue
		if arg == "--loadout-b" and index + 1 < args.size():
			loadout_b = args[index + 1]
			index += 2
			continue
		if arg == "--output" and index + 1 < args.size():
			output_path = args[index + 1]
			index += 2
			continue
		index += 1
	if output_path == "":
		output_path = MicroCombatTelemetryExporter.default_output_path(game_seed)
	return {
		"seed": game_seed,
		"episodes": episodes,
		"max_steps": max_steps,
		"loadout_a": loadout_a,
		"loadout_b": loadout_b,
		"output": output_path,
	}
