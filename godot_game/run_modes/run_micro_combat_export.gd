# Headless micro combat training telemetry export.
# Example:
#   godot --headless --path "<godot_game>" -s res://run_modes/run_micro_combat_export.gd -- --seed 123 --max-steps 80

extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var game_seed: int = parsed["seed"]
	var max_steps: int = parsed["max_steps"]
	var loadout_a: String = parsed["loadout_a"]
	var loadout_b: String = parsed["loadout_b"]
	var output_path: String = parsed["output"]

	var written_path := MicroCombatTelemetryExporter.write_episode(
		game_seed,
		max_steps,
		output_path,
		loadout_a,
		loadout_b
	)
	if written_path == "":
		push_error("Failed to write micro combat telemetry CSV")
		quit(1)
		return

	print("Micro combat telemetry CSV written to: %s" % written_path)
	quit(0)


func _parse_args() -> Dictionary:
	var game_seed := 123
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
		"max_steps": max_steps,
		"loadout_a": loadout_a,
		"loadout_b": loadout_b,
		"output": output_path,
	}
