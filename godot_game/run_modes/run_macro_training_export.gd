# Headless macro training telemetry export — step-level observations and actions.
# Example:
#   godot --headless --path "<godot_game>" -s res://run_modes/run_macro_training_export.gd -- --seed 42 --max-steps 50

extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var game_seed: int = parsed["seed"]
	var max_steps: int = parsed["max_steps"]
	var policy: String = parsed["policy"]
	var output_path: String = parsed["output"]

	var written_path := MacroTrainingTelemetryExporter.write_episode(
		game_seed,
		max_steps,
		output_path,
		policy
	)
	if written_path == "":
		push_error("Failed to write macro training telemetry CSV")
		quit(1)
		return

	print("Macro training telemetry CSV written to: %s" % written_path)
	quit(0)


func _parse_args() -> Dictionary:
	var game_seed := 42
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
	return {"seed": game_seed, "max_steps": max_steps, "policy": policy, "output": output_path}
