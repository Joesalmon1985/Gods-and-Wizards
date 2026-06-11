# Headless underworld pressure telemetry — one CSV row per pressure-scenario game.
# Example:
#   godot --headless --path "<godot_game>" -s res://run_modes/run_underworld_pressure.gd -- --games 20 --seed 42 --max-turns 120

extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var rows := UnderworldPressureRunner.run_games(
		parsed["games"],
		parsed["seed"],
		parsed["max_turns"],
		parsed["policy"]
	)
	var written_path := UnderworldPressureRunner.write_csv(rows, parsed["output"])
	if written_path == "":
		push_error("Failed to write underworld pressure CSV")
		quit(1)
		return
	print("Underworld pressure CSV written to: %s" % written_path)
	print("Games: %d | Seeds: %d..%d | Max turns: %d" % [
		parsed["games"],
		parsed["seed"],
		parsed["seed"] + parsed["games"] - 1,
		parsed["max_turns"],
	])
	quit(0)


func _parse_args() -> Dictionary:
	var game_count := 10
	var start_seed := 42
	var max_turns := 120
	var policy := BotTurnResolver.POLICY_HEURISTIC
	var output_path := ""
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg == "--games" and index + 1 < args.size():
			game_count = int(args[index + 1])
			index += 2
			continue
		if arg == "--seed" and index + 1 < args.size():
			start_seed = int(args[index + 1])
			index += 2
			continue
		if arg == "--max-turns" and index + 1 < args.size():
			max_turns = int(args[index + 1])
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
		output_path = "user://underworld_pressure_seed_%d.csv" % start_seed
	return {
		"games": maxi(game_count, 1),
		"seed": start_seed,
		"max_turns": max_turns,
		"policy": policy,
		"output": output_path,
	}
